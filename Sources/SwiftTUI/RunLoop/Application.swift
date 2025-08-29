// Explicitly import Dispatch for portability across macOS and Linux toolchains.
// Some environments do not re-export Dispatch from Foundation.
import Dispatch
import Foundation

#if os(macOS)
  import AppKit
#endif
#if os(Linux)
  //import Glibc
#else
  import Darwin
#endif

@MainActor
public class Application {
  private let node: Node
  let window: Window
  let control: Control
  private let renderer: Renderer

  private let runLoopType: RunLoopType

  private var arrowKeyParser = ArrowKeyParser()
  private var mouseParser = SGRMouseParser()
  private var mouseReportingActive = false

  private var invalidatedNodes: [Node] = []
  private var updateScheduled = false

  // Global key handler to let apps intercept characters (e.g., 'r', 'g', 'G')
  public var globalKeyHandler: ((Character) -> Void)? = nil

  public init<I: View>(rootView: I, runLoopType: RunLoopType = .dispatch) {
      self.runLoopType = runLoopType

      node = Node(view: VStack(content: rootView).view)
      node.build()

      control = node.control!

      window = Window()
      window.addControl(control)

      window.firstResponder = control.firstSelectableElement
      window.firstResponder?.becomeFirstResponder()

      renderer = Renderer(layer: window.layer)
      window.layer.renderer = renderer

      node.application = self
      renderer.application = self
  }

  var stdInSource: DispatchSourceRead?
  var sigWinChSource: DispatchSourceSignal?
  var sigIntSource: DispatchSourceSignal?

  public enum RunLoopType {
      /// The default option, using Dispatch for the main run loop.
      case dispatch

      #if os(macOS)
          /// This creates and runs an NSApplication with an associated run loop. This allows you
          /// e.g. to open NSWindows running simultaneously to the terminal app. This requires macOS
          /// and AppKit.
          case cocoa
      #endif
  }

  public func start() {
      // Ensure we are attached to a TTY; otherwise exit gracefully
      let stdinTTY = isatty(STDIN_FILENO) != 0
      let stdoutTTY = isatty(STDOUT_FILENO) != 0
      if !stdinTTY || !stdoutTTY {
          fputs("SwiftTUI: Non-TTY detected. Please run in a terminal.\n", stderr)
          return
      }
      // Initialize renderer and input mode only after confirming TTY
      renderer.start()
      setInputMode()
      // Enable xterm mouse reporting (SGR 1006 + basic 1000) unless disabled by env
      let disableMouse = ProcessInfo.processInfo.environment["SWIFTTUI_DISABLE_MOUSE"] == "1"
      if !disableMouse {
          writeOut(EscapeSequence.enableMouseSGR)
          writeOut(EscapeSequence.enableMouseBasic)
          mouseReportingActive = true
      } else {
          mouseReportingActive = false
      }
      updateWindowSize()
      control.layout(size: window.layer.frame.size)
      renderer.draw()

      let stdInSource = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .main)
      stdInSource.setEventHandler { [weak self] in
          Task { @MainActor in self?.handleInput() }
      }
      stdInSource.resume()
      self.stdInSource = stdInSource

      let sigWinChSource = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: .main)
      sigWinChSource.setEventHandler { [weak self] in
          Task { @MainActor in self?.handleWindowSizeChange() }
      }
      sigWinChSource.resume()
      self.sigWinChSource = sigWinChSource

      signal(SIGINT, SIG_IGN)
      let sigIntSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
      sigIntSource.setEventHandler { [weak self] in
          Task { @MainActor in self?.stop() }
      }
      sigIntSource.resume()
      self.sigIntSource = sigIntSource

      switch runLoopType {
      case .dispatch:
          dispatchMain()
      #if os(macOS)
          case .cocoa:
              NSApplication.shared.setActivationPolicy(.accessory)
              NSApplication.shared.run()
      #endif
      }
  }

  private func setInputMode() {
      var tattr = termios()
      tcgetattr(STDIN_FILENO, &tattr)
      tattr.c_lflag &= ~tcflag_t(ECHO | ICANON)
      tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr)
  }

  private func handleInput() {
      let data = FileHandle.standardInput.availableData

      // Some terminals emit bytes not valid UTF-8. Decode lossily so we keep
      // processing known escape sequences and printable characters instead of
      // dropping the whole chunk. Invalid sequences are replaced with U+FFFD.
      let string = String(decoding: data, as: UTF8.self)

      for char in string {
          // Normalize Enter (CR/LF) early and deliver to the focused control first,
          // before any global focus mapping or handlers.
          if char == "\r" || char == "\n" {
              window.firstResponder?.handleEvent("\n")
              globalKeyHandler?("\n")
              continue
          }

          let arrowConsumed = arrowKeyParser.parse(character: char)
          if let key = arrowKeyParser.arrowKey {
              arrowKeyParser.arrowKey = nil
              var moved = false
              switch key {
              case .down:
                  if let next = window.firstResponder?.selectableElement(below: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
                      moved = true
                  }
              case .up:
                  if let next = window.firstResponder?.selectableElement(above: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
                      moved = true
                  }
              case .right:
                  if let next = window.firstResponder?.selectableElement(rightOf: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
                      moved = true
                  }
              case .left:
                  if let next = window.firstResponder?.selectableElement(leftOf: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
                      moved = true
                  }
              }
              if !moved {
                  // Try to scroll nearest ScrollView first; if none, forward vim-mapped intent
                  let scrolled: Bool = {
                      switch key {
                      case .left: return window.firstResponder?.scrollBy(lines: 0, columns: -1) ?? false
                      case .right: return window.firstResponder?.scrollBy(lines: 0, columns: 1) ?? false
                      case .up: return window.firstResponder?.scrollBy(lines: -1, columns: 0) ?? false
                      case .down: return window.firstResponder?.scrollBy(lines: 1, columns: 0) ?? false
                      }
                  }()
                  if !scrolled {
                      if window.firstResponder?.isTextInput == true {
                          switch key {
                          case .left: window.firstResponder?.handleEvent(ASCII.CTRL_B)
                          case .right: window.firstResponder?.handleEvent(ASCII.CTRL_F)
                          case .up, .down: break
                          }
                      } else {
                          switch key {
                          case .left: window.firstResponder?.handleEvent("h")
                          case .right: window.firstResponder?.handleEvent("l")
                          case .up: window.firstResponder?.handleEvent("k")
                          case .down: window.firstResponder?.handleEvent("j")
                          }
                      }
                  }
              }
              continue
          }

          let mouseConsumed = mouseParser.parse(character: char)
          if let event = mouseParser.event {
              mouseParser.event = nil
              handleMouse(event)
              continue
          }

          if arrowConsumed || mouseConsumed { continue }


          // Global TabView shortcuts: [ prev tab, ] next tab when not in a text input
          if char == "[" || char == "]" {
              if window.firstResponder?.isTextInput != true {
                  var cur = window.firstResponder
                  var handled = false
                  while let c = cur, !handled {
                      if char == "[" { handled = c.tabSelectPrev() }
                      else { handled = c.tabSelectNext() }
                      cur = c.parent
                  }
                  if handled { continue }
              }
          }
          // Backspace: handle both DEL (0x7F) and BS (^H, 0x08). When not in a text input, try to pop navigation.
          if char == ASCII.DEL || char == ASCII.BS {
              if window.firstResponder?.isTextInput == true {
                  window.firstResponder?.handleEvent(char)
              } else if tryNavigationPopFromFirstResponder() {
                  // Pop handled by navigation container; it schedules an update
              }
              continue
          }

          if char == ASCII.EOT {
              stop()
          } else if char == "q" {
              // Conventional TUI quit key when not in a text input
              if window.firstResponder?.isTextInput == true {
                  window.firstResponder?.handleEvent(char)
              } else {
                  stop()
              }
          } else if char == "j" {
              if window.firstResponder?.isTextInput == true {
                  window.firstResponder?.handleEvent(char)
              } else if let next = window.firstResponder?.selectableElement(below: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else if char == "k" {
              if window.firstResponder?.isTextInput == true {
                  window.firstResponder?.handleEvent(char)
              } else if let next = window.firstResponder?.selectableElement(above: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else if char == "h" {
              if window.firstResponder?.isTextInput == true {
                  window.firstResponder?.handleEvent(char)
              } else if let next = window.firstResponder?.selectableElement(leftOf: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else if char == "l" {
              if window.firstResponder?.isTextInput == true {
                  window.firstResponder?.handleEvent(char)
              } else if let next = window.firstResponder?.selectableElement(rightOf: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else {
              // Let the app intercept arbitrary keys first (e.g., 'r', 'g', 'G')
              globalKeyHandler?(char)
              window.firstResponder?.handleEvent(char)
          }
      }
      // Flush any pending invalidations immediately to avoid perceived lag in redraws.
      if window.layer.invalidated != nil || !invalidatedNodes.isEmpty {
          update()
      }
      // Schedule a follow-up coalesced update on the next tick to capture any
      // async @State/@EnvironmentObject invalidations triggered by control
      // actions (e.g. TextField action-mode submit).
      DispatchQueue.main.async { [weak self] in
          self?.scheduleUpdate()
      }
  }

  func invalidateNode(_ node: Node) {
      invalidatedNodes.append(node)
      scheduleUpdate()
  }

  func scheduleUpdate() {
      if !updateScheduled {
          DispatchQueue.main.async { self.update() }
          updateScheduled = true
      }
  }

  private func update() {
      updateScheduled = false

      let hadInvalidations = !invalidatedNodes.isEmpty
      for node in invalidatedNodes {
          node.update(using: node.view)
      }
      invalidatedNodes = []

      control.layout(size: window.layer.frame.size)
      // In rare cases structural updates may not mark a region invalid; ensure a flush.
      if hadInvalidations && window.layer.invalidated == nil {
          window.layer.invalidate()
      }
      renderer.update()
  }

  private func handleWindowSizeChange() {
      updateWindowSize()
      control.layer.invalidate()
      update()
  }

  private func updateWindowSize() {
      var size = winsize()
      guard ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &size) == 0,
          size.ws_col > 0, size.ws_row > 0
      else {
          // Fallback to a default size to avoid crashing in edge cases
          window.layer.frame.size = Size(width: Extended(80), height: Extended(24))
          renderer.setCache()
          return
      }
      window.layer.frame.size = Size(
          width: Extended(Int(size.ws_col)), height: Extended(Int(size.ws_row)))
      renderer.setCache()
  }

  private func stop() {
      renderer.stop()
      // Disable mouse reporting if it was enabled
      if mouseReportingActive {
          writeOut(EscapeSequence.disableMouseBasic)
          writeOut(EscapeSequence.disableMouseSGR)
      }
      resetInputMode()  // Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
      exit(0)
  }

  /// Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
  private func resetInputMode() {
      // Reset ECHO and ICANON values:
      var tattr = termios()
      tcgetattr(STDIN_FILENO, &tattr)
      tattr.c_lflag |= tcflag_t(ECHO | ICANON)
      tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr)
  }

  // MARK: - Navigation helpers
  private func isLikelyTextInput(_ c: Control?) -> Bool {
      guard let c else { return false }
      let name = String(describing: type(of: c))
      return name.contains("TextFieldControl") || name.contains("SecureFieldControl")
  }

  private func tryNavigationPopFromFirstResponder() -> Bool {
      var current = window.firstResponder
      while let cur = current {
          if cur.navigationPop() { return true }
          current = cur.parent
      }
      return false
  }
}

// MARK: - Mouse handling helpers
extension Application {
  fileprivate func handleMouse(_ event: SGRMouseParser.Event) {
      // Only act on left button clicks
      guard event.button == .left else { return }
      let pos = Position(column: Extended(event.column), line: Extended(event.line))
      switch event.kind {
      case .press:
          if let target = control.hitTest(screenPosition: pos) {
              window.firstResponder?.resignFirstResponder()
              window.firstResponder = target
              window.firstResponder?.becomeFirstResponder()
          }
      case .release:
          window.firstResponder?.handleEvent("\n")
      }
  }

  fileprivate func writeOut(_ str: String) {
      str.withCString { _ = write(STDOUT_FILENO, $0, strlen($0)) }
  }
}
