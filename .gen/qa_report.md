PASS/FAIL SUMMARY

- Unit tests: PASS (10/10)
- Interactive TUI (tmux) smoke test: FAIL (runtime crash on macOS in DispatchSource handler)
- Example apps (Numbers/Flags/ToDoList/Colors): FAIL to build on Swift 6 (main actor isolation error)

Environment

- OS: macOS 15.6.1 (24G90)
- Swift: Apple Swift version 6.1.2 (swiftlang-6.1.2.1.2 clang-1700.0.13.5)
- tmux: 3.5a
- Repo: branch main, dirty: True

What I Ran

1) Unit tests
  - Command: swift test -v
  - Result: All tests passed (10 tests, 0 failures).

2) Interactive TUI, driven via tmux
  - Examples (Numbers/Flags/ToDoList/Colors): Attempted to build and run, but builds fail on Swift 6 due to main-actor isolation (see details and fix below).
  - Created a temporary QA harness under .scratch/TUIHarness (executable linking the library) to exercise common controls (Button, Toggle, Slider, TextField, SecureField) and allow driving via tmux.
  - Drove the harness with tmux send-keys (Add item, move focus, type text, quit).

Detailed Findings

1) Unit tests

- Output excerpt:

 Test Suite 'All tests' passed at 2025-08-27 19:51:49.553.
   Executed 10 tests, with 0 failures (0 unexpected) in 0.002 (0.003) seconds

- Coverage of behaviors includes rendering expectations for Slider, ProgressView, SecureField placeholder, Toggle bracket rendering, Position arithmetic, Rect union, and basic view build structure. These give good confidence in core rendering/layout primitives.

2) Example apps fail to build on Swift 6 (SwiftPM 6 toolchain)

- Repro (Numbers example shown; others have the same pattern):
 - cd Examples/Numbers
 - swift build -c debug

- Error (excerpt):

 /Examples/Numbers/Sources/Numbers/main.swift:3:38: error: call to main actor-isolated instance method 'start()' in a synchronous nonisolated context
   Application(rootView: ContentView()).start()

 /Sources/SwiftTUI/RunLoop/Application.swift:64:15: note: calls to instance method 'start()' from outside of its actor context are implicitly asynchronous

 /Examples/Numbers/Sources/Numbers/main.swift:3:1: error: call to main actor-isolated initializer 'init(rootView:runLoopType:)' in a synchronous nonisolated context

- Root cause: Application.init(...) and start() are @MainActor isolated in Swift 6; the examples call them from top-level, nonisolated code.

- Proposed fix (for all Examples/*/Sources/*/main.swift):
 - Convert to an @main entry that is @MainActor, e.g.:

   import SwiftTUI

   @main
   struct AppMain {
       @MainActor static func main() {
           Application(rootView: ContentView()).start()
       }
   }

 - Alternatively, keep main.swift script-style and wrap the call in a main-actor Task, then keep the process alive (but the @main approach above is idiomatic and avoids dispatchMain double-entry issues).

3) Interactive TUI smoke test (tmux) crashes on macOS inside DispatchSource handler setup

- Because examples didn’t build under Swift 6, I created a minimal harness in .scratch/TUIHarness to exercise controls. It renders fine and can be driven by keystrokes, but it crashes reproducibly shortly after launch or upon sending keys, both under tmux and under a PTY created via script(1).

- Repro steps (tmux):
 - Build harness: (from repo root)
   cd .scratch/TUIHarness && swift build -c debug
 - Start tmux and run harness:
   tmux new-session -d -s qa_harness
   tmux send-keys -t qa_harness:0.0 "cd .scratch/TUIHarness" C-m
   tmux send-keys -t qa_harness:0.0 "./.build/debug/TUIHarness" C-m
 - Observe: UI briefly renders (alternate screen, title, Add/Toggle buttons, Slider, Item 1 list, TextField and SecureField placeholders), then the process terminates or crashes.

- Repro steps (script PTY):
 - script -q /tmp/run_harness.log .scratch/TUIHarness/.build/debug/TUIHarness
 - Observe UI then crash. Excerpt from the captured output:

   💣 Program crashed: Signal 10: Bus error
   Thread 0 crashed:
   0 _Block_copy + 312 in libsystem_blocks.dylib
   1 OS_dispatch_source.setEventHandler(qos:flags:handler:) + 56 in libswiftDispatch.dylib
   2 Application.start() + 1268 in TUIHarness at Sources/SwiftTUI/RunLoop/Application.swift:81:19
      79│ 
      80│   let stdInSource = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .main)
      81│   stdInSource.setEventHandler(qos: .default, flags: [], handler: self.handleInput)
      82│   stdInSource.resume()
      83│   self.stdInSource = stdInSource

- Notes:
 - The crash occurs when setting the event handler for the read source on STDIN (and similarly can happen for the signal sources). It is not a clean exit: the process switches to the alternate screen (1049h), draws the UI, then crashes.
 - The same behavior is observed under tmux. The process may terminate so quickly that the session disappears; using tmux pipe-pane shows the UI content followed by termination.
 - Before the crash, basic keystrokes do register (I was able to type into the TextField and see the string echoed in the list), but the crash prevents a reliable end-to-end script.

- Hypothesis / possible causes:
 - Swift 6’s Dispatch bridging and actor isolation may expose a bug when passing instance method references (like self.handleInput) to setEventHandler(qos:flags:handler:) in this context.
 - Using the new setEventHandler(qos:flags:handler:) overload with a method reference seems to trigger a block bridging issue on macOS 15.6 in this environment.
 - There is also a chance the closure captures are interacting poorly with actor isolation or lifetime (e.g., block copying a context referring to self before it is fully retained by stdInSource).

- Proposed fix:
 - Avoid passing the instance method reference directly. Wrap it in a closure and avoid the qos/flags overload:

   // Before
   stdInSource.setEventHandler(qos: .default, flags: [], handler: self.handleInput)

   // After (safer bridging and explicit capture)
   stdInSource.setEventHandler { [weak self] in
       self?.handleInput()
   }

   // Similarly for SIGWINCH and SIGINT sources:
   sigWinChSource.setEventHandler { [weak self] in self?.handleWindowSizeChange() }
   sigIntSource.setEventHandler { [weak self] in self?.stop() }

 - If the crash persists, consider creating these DispatchSource objects earlier and maintaining strong references to them (already done for stdInSource), and ensure all event handlers capture [weak self] and hop to the main actor if needed:

   sigIntSource.setEventHandler { [weak self] in
       Task { @MainActor in self?.stop() }
   }

 - This pattern is robust under Swift 5.x and Swift 6.x, and avoids relying on the setEventHandler(qos:flags:handler:) overload.

4) Usability observations from the harness (before crash)

- Initial render looks correct: inverted selection on Button("Add"), Slider with brackets and knob, a bordered list box with Item 1, TextField placeholder underlined when focused, and SecureField placeholder shows as plain text.
- Keyboard:
 - Buttons: Enter/Space activate as expected.
 - Focus movement: Arrow keys and vim keys j/k/h/l move focus across controls.
 - Slider: h and l adjust the knob by step.
 - TextField: typing characters shows live and Enter fires the action and clears the field; placeholder underline on focus is visible.
 - SecureField: placeholder renders; live typed characters render as bullets.
- Quitting: Ctrl-C and Ctrl-D should stop the app; attempts to send Ctrl-C under tmux hit the crash before verifying the graceful shutdown path.

Reproduction Scripts (copy/paste)

- Run unit tests:
 swift test -v

- Build an example to see Swift 6 main-actor failure:
 cd Examples/Numbers && swift build -c debug

- Build and run the QA harness with tmux:
 cd .scratch/TUIHarness && swift build -c debug
 tmux new-session -d -s qa_harness
 tmux send-keys -t qa_harness:0.0 "cd $(pwd)" C-m
 tmux send-keys -t qa_harness:0.0 "./.build/debug/TUIHarness" C-m
 # capture the pane to inspect output:
 tmux capture-pane -t qa_harness:0.0 -p -J -S -200 | sed -n '1,200p'

- Run under a PTY with script(1) and observe the crash log:
 script -q /tmp/run_harness.log .scratch/TUIHarness/.build/debug/TUIHarness
 sed -n '1,200p' /tmp/run_harness.log

Proposed Fixes (prioritized)

1) Fix example app entrypoints for Swift 6
  - Update all Examples/*/Sources/*/main.swift to use an @main type with @MainActor static func main(), calling Application(rootView:).start(). This unblocks building and running the examples under Swift 6.

2) Stabilize DispatchSource event handler setup on macOS
  - Replace uses of setEventHandler(qos:flags:handler:) with setEventHandler { [weak self] ... } and, as necessary, hop to @MainActor inside handlers. This avoids the crash observed at _Block_copy when bridging the method reference.
  - Verify on macOS in a tmux session and in a regular Terminal.app session.

3) Add a simple CLI QA harness as an example (optional)
  - Consider promoting .scratch/TUIHarness (or a similar small app) under Examples/QA to cover common controls in one place. This aids manual and automated smoke testing across macOS and Linux.

4) CI enhancements
  - Add a job to build and run each example on macOS and Linux.
  - Add a headless smoke test harness (e.g., via script(1) on macOS and script or ttyd on Linux) to catch regressions in Application.start, input handling, and shutdown.

Notes against the user goal (feature parity macOS/Linux)

- The current blocker to interactive testing on macOS is the crash in Application.start when setting DispatchSource handlers. Fixing this should also benefit Linux, where the same pattern is used.
- The feature-parity document is comprehensive; however, without running examples interactively, it’s hard to validate certain items (ScrollView auto-focus, GeometryReader edge-cases, mouse handling). Once the crash is addressed and examples compile under Swift 6, interactive parity checks can proceed.
