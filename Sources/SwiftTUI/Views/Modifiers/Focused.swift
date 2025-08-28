import Foundation

public extension View {
   /// Bind whether this view is focused.
   func focused(_ isFocused: Binding<Bool>) -> some View {
       FocusedBool(content: self, isFocused: isFocused)
   }

   /// Bind a focus value; when this view (or its focusable descendant) is focused,
   /// the binding is set to `value`. When the binding equals `value`, this view
   /// requests focus.
   func focused<V: Equatable>(_ binding: Binding<V?>, equals value: V) -> some View {
       FocusedEquals(content: self, binding: binding, value: value)
   }
}

// MARK: - Bool focused modifier

private struct FocusedBool<Content: View>: View, PrimitiveView, ModifierView {
   let content: Content
   var isFocused: Binding<Bool>

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       node.controls = WeakSet<Control>()
       node.addNode(at: 0, Node(view: content.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: content.view)
       for c in node.controls?.values ?? [] {
           if let ctrl = c as? FocusedBoolControl {
               ctrl.isFocused = isFocused
               ctrl.ensureFocusIfRequested()
           }
       }
   }

   func passControl(_ control: Control, node: Node) -> Control {
       if let parent = control.parent { return parent }
       let wrapper = FocusedBoolControl(isFocused: isFocused)
       wrapper.addSubview(control, at: 0)
       node.controls?.add(wrapper)
       return wrapper
   }

   private class FocusedBoolControl: Control {
       var isFocused: Binding<Bool>

       init(isFocused: Binding<Bool>) {
           self.isFocused = isFocused
       }

       override func size(proposedSize: Size) -> Size {
           children[0].size(proposedSize: proposedSize)
       }

       override func layout(size: Size) {
           super.layout(size: size)
           children[0].layout(size: size)
       }

       override func handleEvent(_ char: Character) {
           children[0].handleEvent(char)
       }

       override func descendantBecameFirstResponder(_ control: Control) {
           if control === children[0] || control.isDescendant(of: children[0]) {
               if isFocused.wrappedValue != true { isFocused.wrappedValue = true }
           }
           super.descendantBecameFirstResponder(control)
       }

       override func descendantResignedFirstResponder(_ control: Control) {
           if control === children[0] || control.isDescendant(of: children[0]) {
               if isFocused.wrappedValue != false { isFocused.wrappedValue = false }
           }
           super.descendantResignedFirstResponder(control)
       }

       func ensureFocusIfRequested() {
           guard let win = root.window else { return }
           if isFocused.wrappedValue {
               if let target = children[0].firstSelectableElement, win.firstResponder !== target {
                   win.firstResponder?.resignFirstResponder()
                   win.firstResponder = target
                   target.becomeFirstResponder()
               }
           } else {
               if let current = win.firstResponder,
                  current === children[0] || current.isDescendant(of: children[0]) {
                   current.resignFirstResponder()
                   win.firstResponder = nil
               }
           }
       }
   }
}

// MARK: - Equals focused modifier

private struct FocusedEquals<Content: View, V: Equatable>: View, PrimitiveView, ModifierView {
   let content: Content
   var binding: Binding<V?>
   let value: V

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       node.controls = WeakSet<Control>()
       node.addNode(at: 0, Node(view: content.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: content.view)
       for c in node.controls?.values ?? [] {
           if let ctrl = c as? FocusedEqualsControl<V> {
               ctrl.binding = binding
               ctrl.value = value
               ctrl.ensureFocusIfRequested()
           }
       }
   }

   func passControl(_ control: Control, node: Node) -> Control {
       if let parent = control.parent { return parent }
       let wrapper = FocusedEqualsControl<V>(binding: binding, value: value)
       wrapper.addSubview(control, at: 0)
       node.controls?.add(wrapper)
       return wrapper
   }

   private class FocusedEqualsControl<T: Equatable>: Control {
       var binding: Binding<T?>
       var value: T

       init(binding: Binding<T?>, value: T) {
           self.binding = binding
           self.value = value
       }

       override func size(proposedSize: Size) -> Size {
           children[0].size(proposedSize: proposedSize)
       }

       override func layout(size: Size) {
           super.layout(size: size)
           children[0].layout(size: size)
       }

       override func handleEvent(_ char: Character) {
           children[0].handleEvent(char)
       }

       override func descendantBecameFirstResponder(_ control: Control) {
           if control === children[0] || control.isDescendant(of: children[0]) {
               if binding.wrappedValue != value { binding.wrappedValue = value }
           }
           super.descendantBecameFirstResponder(control)
       }

       override func descendantResignedFirstResponder(_ control: Control) {
           if control === children[0] || control.isDescendant(of: children[0]) {
               if binding.wrappedValue == value { binding.wrappedValue = nil }
           }
           super.descendantResignedFirstResponder(control)
       }

       func ensureFocusIfRequested() {
           guard let win = root.window else { return }
           if binding.wrappedValue == value {
               if let target = children[0].firstSelectableElement, win.firstResponder !== target {
                   win.firstResponder?.resignFirstResponder()
                   win.firstResponder = target
                   target.becomeFirstResponder()
               }
           } else {
               if let current = win.firstResponder,
                  current === children[0] || current.isDescendant(of: children[0]) {
                   current.resignFirstResponder()
                   win.firstResponder = nil
               }
           }
       }
   }
}
