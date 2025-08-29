import Foundation

public extension View {
   /// Hides this view while preserving its layout size.
   /// Hidden views are non-selectable and do not draw content.
   func hidden() -> some View { Hidden(content: self) }
}

private struct Hidden<Content: View>: View, PrimitiveView, ModifierView {
   let content: Content

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       // We still build the content node so it can compute size/layout,
       // but the wrapper control will not attach it as a sublayer.
       node.controls = WeakSet<Control>()
       node.addNode(at: 0, Node(view: content.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: content.view)
   }

   func passControl(_ control: Control, node: Node) -> Control {
       if let wrapper = control.parent as? HiddenControl { return wrapper }
       let wrapper = HiddenControl(proxied: control)
       node.controls?.add(wrapper)
       return wrapper
   }

   private class HiddenControl: Control {
       let proxied: Control

       init(proxied: Control) {
           self.proxied = proxied
       }

       override func size(proposedSize: Size) -> Size {
           proxied.size(proposedSize: proposedSize)
       }

       override func layout(size: Size) {
           super.layout(size: size)
           // Layout proxied off-tree so size remains consistent
           proxied.layout(size: size)
       }

       override var selectable: Bool { false }

       override func cell(at position: Position) -> Cell? { nil }

       override func makeLayer() -> Layer { HiddenLayer() }
   }

   private class HiddenLayer: Layer {
       override func cell(at position: Position) -> Cell? { nil }
   }
}
