import Foundation

public extension View {
   /// Notify when focus enters or leaves this view's subtree.
   func onFocusChange(_ action: @escaping (Bool) -> Void) -> some View {
       OnFocusChange(content: self, action: action)
   }
}

private struct OnFocusChange<Content: View>: View, PrimitiveView, ModifierView {
   let content: Content
   let action: (Bool) -> Void

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       node.controls = WeakSet<Control>()
       node.addNode(at: 0, Node(view: content.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: content.view)
       for c in node.controls?.values ?? [] {
           if let oc = c as? OnFocusChangeControl { oc.action = action }
       }
   }

   func passControl(_ control: Control, node: Node) -> Control {
       if let existing = control.parent as? OnFocusChangeControl { return existing }
       let wrapper = OnFocusChangeControl(action: action)
       wrapper.addSubview(control, at: 0)
       node.controls?.add(wrapper)
       return wrapper
   }

   private class OnFocusChangeControl: Control {
       var action: (Bool) -> Void
       private var isFocusedSubtree: Bool = false

       init(action: @escaping (Bool) -> Void) { self.action = action }

       override func size(proposedSize: Size) -> Size { children[0].size(proposedSize: proposedSize) }

       override func layout(size: Size) {
           super.layout(size: size)
           children[0].layout(size: size)
           children[0].layer.frame.position = .zero
           layer.frame.size = size
       }

       override func handleEvent(_ char: Character) { children[0].handleEvent(char) }

       override func descendantBecameFirstResponder(_ control: Control) {
           if !isFocusedSubtree { isFocusedSubtree = true; action(true) }
           super.descendantBecameFirstResponder(control)
       }

       override func descendantResignedFirstResponder(_ control: Control) {
           if isFocusedSubtree {
               isFocusedSubtree = false
               action(false)
           }
           super.descendantResignedFirstResponder(control)
       }
   }
}
