import Foundation

public extension View {
  /// Minimal tap gesture for terminal UIs.
  ///
  /// Triggers on Enter/Return/Space when the wrapper is focused. Mouse support
  /// is provided by Application: a click selects the control and on release
  /// it sends a "\n" to the focused control, which will fire this handler.
  func onTapGesture(count: Int = 1, perform action: @escaping () -> Void) -> some View {
      TapGestureView(content: self, count: count, action: action)
  }
}

private struct TapGestureView<Content: View>: View, PrimitiveView, ModifierView {
  let content: Content
  let count: Int
  let action: () -> Void

  static var size: Int? { Content.size }

  func buildNode(_ node: Node) {
      node.controls = WeakSet<Control>()
      node.addNode(at: 0, Node(view: content.view))
  }

  func updateNode(_ node: Node) {
      node.view = self
      node.children[0].update(using: content.view)
      for c in node.controls?.values ?? [] {
          if let tg = c as? TapGestureControl {
              tg.count = count
              tg.action = action
          }
      }
  }

  func passControl(_ control: Control, node: Node) -> Control {
      if let existing = control.parent as? TapGestureControl { return existing }
      let tg = TapGestureControl(count: count, action: action)
      tg.addSubview(control, at: 0)
      node.controls?.add(tg)
      return tg
  }

  private class TapGestureControl: Control {
      var count: Int
      var action: () -> Void
      // Track successive activations to support multi-tap semantics
      private var lastActivation: Date? = nil
      private var tapAccumulator: Int = 0
      // A reasonable detection window for TUIs (mouse release maps to "\n")
      private let activationWindow: TimeInterval = 0.35

      init(count: Int, action: @escaping () -> Void) {
          self.count = count
          self.action = action
      }

      override func size(proposedSize: Size) -> Size {
          children[0].size(proposedSize: proposedSize)
      }

      override func layout(size: Size) {
          super.layout(size: size)
          children[0].layout(size: size)
          children[0].layer.frame.position = .zero
          layer.frame.size = size
      }

      override var selectable: Bool { true }

      override func handleEvent(_ char: Character) {
          // Enter/Return/Space are treated as tap activations
          if char == "\n" || char == "\r" || char == " " {
              registerTapAndMaybeFire()
              return
          }
          children[0].handleEvent(char)
      }

      private func registerTapAndMaybeFire() {
          let now = Date()
          if let last = lastActivation, now.timeIntervalSince(last) <= activationWindow {
              tapAccumulator += 1
          } else {
              tapAccumulator = 1
          }
          lastActivation = now

          if tapAccumulator >= max(1, count) {
              tapAccumulator = 0
              lastActivation = nil
              action()
          }
      }
  }
}
