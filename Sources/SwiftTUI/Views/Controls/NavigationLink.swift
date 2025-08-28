import Foundation

/// A simple navigation link that pushes a destination when activated.
public struct NavigationLink<Label: View, Destination: View>: View, PrimitiveView {
  let label: VStack<Label>
  let destination: Destination

  // Activation mode: simple (tap to push) or programmatic via isActive binding
  enum Activation { case simple, isActive(Binding<Bool>) }
  let activation: Activation

  @Environment(\._navigationPush) private var _push
  @Environment(\._navigationPop) private var _pop

  public init(destination: Destination, @ViewBuilder label: () -> Label) {
      self.destination = destination
      self.label = VStack(content: label())
      self.activation = .simple
  }

  /// Programmatic navigation initializer. When `isActive` becomes true, the destination is pushed;
  /// when it becomes false, a pop is issued.
  public init(isActive: Binding<Bool>, destination: Destination, @ViewBuilder label: () -> Label) {
      self.destination = destination
      self.label = VStack(content: label())
      self.activation = .isActive(isActive)
  }

  static var size: Int? { 1 }

  func buildNode(_ node: Node) {
      // Access environment to capture push/pop handlers
      setupEnvironmentProperties(node: node)
      // For the view hierarchy, we still build a Button so the label is focusable/activatable.
      let button: Button<VStack<Label>>
      switch activation {
      case .simple:
          button = Button(action: { if let p = _push { p(destination.view) } }, hover: {}) { label }
      case .isActive(let binding):
          button = Button(action: { binding.wrappedValue = true }, hover: {}) { label }
          // Seed previous state so first update can detect an initial true and push.
          node.state["NavigationLink.isActive.prev"] = binding.wrappedValue
      }
      node.addNode(at: 0, Node(view: button.view))
  }

  func updateNode(_ node: Node) {
      setupEnvironmentProperties(node: node)
      node.view = self

      switch activation {
      case .simple:
          let button = Button(action: { if let p = _push { p(destination.view) } }, hover: {}) { label }
          node.children[0].update(using: button.view)
      case .isActive(let binding):
          let button = Button(action: { binding.wrappedValue = true }, hover: {}) { label }
          node.children[0].update(using: button.view)

          // Detect binding changes and perform push/pop side effects.
          let key = "NavigationLink.isActive.prev"
          let prev = (node.state[key] as? Bool) ?? false
          let cur = binding.wrappedValue
          if cur != prev {
              if cur {
                  if let p = _push { p(destination.view) }
              } else {
                  if let pop = _pop { pop() }
              }
              node.state[key] = cur
          }
      }
  }
}
