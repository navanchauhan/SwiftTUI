import Foundation

public extension View {
 /// Calls the given action when the specified value changes.
 ///
 /// Mirrors SwiftUI’s `.onChange(of:perform:)` behavior: the action is not
 /// called on initial appearance, only when the value subsequently changes.
 func onChange<V: Equatable>(of value: V, perform action: @escaping (V) -> Void) -> some View {
     OnChange(content: self, value: value, action: action)
 }
}

private struct OnChange<Content: View, V: Equatable>: View, PrimitiveView, ModifierView {
  let content: Content
  let value: V
  let action: (V) -> Void

  static var size: Int? { Content.size }

  func buildNode(_ node: Node) {
      node.addNode(at: 0, Node(view: content.view))
      // Seed previous value on first build; do not fire action on initial appearance.
      node.state[prevKey] = value
  }

  func updateNode(_ node: Node) {
      node.view = self
      node.children[0].update(using: content.view)
      let key = prevKey
      if let old = node.state[key] as? V {
          if old != value {
              action(value)
              node.state[key] = value
          }
      } else {
          node.state[key] = value
      }
  }

  func passControl(_ control: Control, node: Node) -> Control {
      // No wrapper control needed; just pass underlying control through.
      return control
  }

  private var prevKey: String { "OnChange.prev" }
}
