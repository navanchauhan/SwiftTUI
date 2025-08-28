import Foundation

// Internal protocol to let shapes provide a containment test for clipping.
protocol _MaskShape {
   func _contains(_ pos: Position, size: Size) -> Bool
}

extension Rectangle: _MaskShape {
   func _contains(_ pos: Position, size: Size) -> Bool {
       return pos.column >= 0 && pos.line >= 0 && pos.column < size.width && pos.line < size.height
   }
}

extension RoundedRectangle: _MaskShape {
   func _contains(_ pos: Position, size: Size) -> Bool {
       // Reuse control logic for inclusion test
       let ctrl = RoundedRectangle.RoundedRectangleControl(cornerRadius: cornerRadius, mode: nil)
       return ctrl._contains(pos, size: size)
   }
}

public extension View {
   func clipShape(_ shape: Rectangle) -> some View {
       ClipShapeView(content: self, shape: shape)
   }

   func clipShape(_ shape: RoundedRectangle) -> some View {
       ClipShapeView(content: self, shape: shape)
   }
}

private struct ClipShapeView<Content: View, ShapeType: _MaskShape>: View, PrimitiveView, ModifierView {
   let content: Content
   let shape: ShapeType

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       node.controls = WeakSet<Control>()
       node.addNode(at: 0, Node(view: content.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: content.view)
       for c in node.controls?.values ?? [] {
           if let cc = c as? ClippingControl<ShapeType> {
               cc.shape = shape
               cc.layer.invalidate()
           }
       }
   }

   func passControl(_ control: Control, node: Node) -> Control {
       if let existing = control.parent as? ClippingControl<ShapeType> { return existing }
       let clip = ClippingControl(shape: shape)
       clip.addSubview(control, at: 0)
       node.controls?.add(clip)
       return clip
   }

   private class ClippingControl<S: _MaskShape>: Control {
       var shape: S
       weak var clipLayer: ClippingLayer?

       init(shape: S) { self.shape = shape }

       override func size(proposedSize: Size) -> Size { children[0].size(proposedSize: proposedSize) }

       override func layout(size: Size) {
           super.layout(size: size)
           children[0].layout(size: size)
           children[0].layer.frame.position = .zero
           layer.frame.size = size
       }

       override func makeLayer() -> Layer {
           let l = ClippingLayer()
           l.allow = { [weak self] pos, size in
               guard let self else { return true }
               return self.shape._contains(pos, size: size)
           }
           self.clipLayer = l
           return l
       }
   }

   private class ClippingLayer: Layer {
       var allow: ((Position, Size) -> Bool)?

       override func cell(at position: Position) -> Cell? {
           let base = super.cell(at: position)
           guard let base else { return nil }
           if let allow, !allow(position, frame.size) { return nil }
           return base
       }
   }
}