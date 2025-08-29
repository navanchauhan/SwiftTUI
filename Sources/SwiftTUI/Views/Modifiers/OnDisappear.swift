import Foundation

public extension View {
   /// Registers an action to perform when this view disappears from the
   /// hierarchy (is removed due to structural updates or navigation pops).
   func onDisappear(_ action: @escaping () -> Void) -> some View {
       OnDisappear(content: self, action: action)
   }
}

private struct OnDisappear<Content: View>: View, PrimitiveView, ModifierView {
   let content: Content
   let action: () -> Void

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       node.controls = WeakSet<Control>()
       node.addNode(at: 0, Node(view: content.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: content.view)
       for control in node.controls?.values ?? [] {
           if let c = control as? OnDisappearControl {
               c.action = action
           }
       }
       // Detect wrappers removed during update and fire their actions now.
       for control in node.controls?.values ?? [] {
           if let c = control as? OnDisappearControl, c.parent == nil, !c.didFire {
               c.didFire = true
               c.action()
           }
       }
   }

   func passControl(_ control: Control, node: Node) -> Control {
       if let existing = control.parent as? OnDisappearControl { return existing }
       let wrapper = OnDisappearControl(action: action)
       wrapper.addSubview(control, at: 0)
       node.controls?.add(wrapper)
       return wrapper
   }

   private class OnDisappearControl: Control {
       var action: () -> Void
       var didFire: Bool = false
       init(action: @escaping () -> Void) { self.action = action }

       override func size(proposedSize: Size) -> Size {
           children[0].size(proposedSize: proposedSize)
       }

       override func layout(size: Size) {
           super.layout(size: size)
           children[0].layout(size: size)
       }

       deinit {
           // Fire the action when the wrapper control is deallocated,
           // which corresponds to the wrapped view leaving the hierarchy.
           if !didFire { action() }
       }
   }
}
