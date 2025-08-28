import Foundation
#if os(macOS)
import AppKit
#endif
#if os(Linux)
import Glibc
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
       // Enable xterm mouse reporting (SGR 1006 + basic 1000)
      writeOut(EscapeSequence.enableMouseSGR)
      writeOut(EscapeSequence.enableMouseBasic)
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
      tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr);
  }

  private func handleInput() {
      let data = FileHandle.standardInput.availableData

       // Some terminals emit bytes not valid UTF-8; ignore them
      guard let string = String(data: data, encoding: .utf8) else {
          return
      }

      for char in string {
          let arrowConsumed = arrowKeyParser.parse(character: char)
          if let key = arrowKeyParser.arrowKey {
              arrowKeyParser.arrowKey = nil
              switch key {
              case .down:
                  if let next = window.firstResponder?.selectableElement(below: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
                  }
              case .up:
                  if let next = window.firstResponder?.selectableElement(above: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
                  }
              case .right:
                  if let next = window.firstResponder?.selectableElement(rightOf: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
                  }
              case .left:
                  if let next = window.firstResponder?.selectableElement(leftOf: 0) {
                      window.firstResponder?.resignFirstResponder()
                      window.firstResponder = next
                      window.firstResponder?.becomeFirstResponder()
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

          if char == ASCII.EOT {
              stop()
          } else if char == "j" {
              if let next = window.firstResponder?.selectableElement(below: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else if char == "k" {
              if let next = window.firstResponder?.selectableElement(above: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else if char == "h" {
              if let next = window.firstResponder?.selectableElement(leftOf: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else if char == "l" {
              if let next = window.firstResponder?.selectableElement(rightOf: 0) {
                  window.firstResponder?.resignFirstResponder()
                  window.firstResponder = next
                  window.firstResponder?.becomeFirstResponder()
              }
          } else {
              if char == "\r" {
                  // Normalize CR to LF for Enter keys from some terminals
                  globalKeyHandler?("\n")
                  window.firstResponder?.handleEvent("\n")
                  continue
              }
              // Let the app intercept arbitrary keys first (e.g., 'r', 'g', 'G')
              globalKeyHandler?(char)
              window.firstResponder?.handleEvent(char)
          }
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
            size.ws_col > 0, size.ws_row > 0 else {
          // Fallback to a default size to avoid crashing in edge cases
          window.layer.frame.size = Size(width: Extended(80), height: Extended(24))
          renderer.setCache()
          return
      }
      window.layer.frame.size = Size(width: Extended(Int(size.ws_col)), height: Extended(Int(size.ws_row)))
      renderer.setCache()
  }

  private func stop() {
      renderer.stop()
      // Disable mouse reporting
      writeOut(EscapeSequence.disableMouseBasic)
      writeOut(EscapeSequence.disableMouseSGR)
      resetInputMode() // Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
      exit(0)
  }

  /// Fix for: https://github.com/rensbreur/SwiftTUI/issues/25
  private func resetInputMode() {
      // Reset ECHO and ICANON values:
      var tattr = termios()
      tcgetattr(STDIN_FILENO, &tattr)
      tattr.c_lflag |= tcflag_t(ECHO | ICANON)
      tcsetattr(STDIN_FILENO, TCSAFLUSH, &tattr);
  }

}

// MARK: - Mouse handling helpers
private extension Application {
   func handleMouse(_ event: SGRMouseParser.Event) {
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

   func writeOut(_ str: String) {
       str.withCString { _ = write(STDOUT_FILENO, $0, strlen($0)) }
   }
}