import Foundation

/// SwiftUI-like opacity modifier.
///
/// Terminals don’t support real alpha blending; we approximate:
/// - value >= 1: no change
/// - 0 < value < 1: render content using low intensity (faint)
/// - value <= 0: also rendered as faint (still occupies layout)
public extension View {
   func opacity(_ value: Double) -> some View {
       Opacity(content: self, value: value)
   }
}

private struct Opacity<Content: View>: View, PrimitiveView, ModifierView {
   let content: Content
   let value: Double

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       node.controls = WeakSet<Control>()
       node.addNode(at: 0, Node(view: content.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: content.view)
       for c in node.controls?.values ?? [] {
           if let oc = c as? OpacityControl { oc.value = value }
       }
   }

   func passControl(_ control: Control, node: Node) -> Control {
       if let existing = control.parent as? OpacityControl { return existing }
       let wrapper = OpacityControl(value: value)
       wrapper.addSubview(control, at: 0)
       node.controls?.add(wrapper)
       return wrapper
   }

   private class OpacityControl: Control {
       var value: Double

       init(value: Double) { self.value = value }

       override func size(proposedSize: Size) -> Size {
           children[0].size(proposedSize: proposedSize)
       }

       override func layout(size: Size) {
           super.layout(size: size)
           children[0].layout(size: size)
           children[0].layer.frame.position = .zero
           layer.frame.size = size
       }

       override func cell(at position: Position) -> Cell? {
           guard var cell = children[0].cell(at: position) else { return nil }
           // Clamp and apply faint mapping for any value below 1.
           if value < 1.0 { cell.attributes.faint = true }
           return cell
       }
   }
}
