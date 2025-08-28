import Foundation

public extension View {
   /// Places a view in the background of this view.
   ///
   /// Unlike the color-only background(_:) variant, this accepts an arbitrary
   /// view builder. The background view is sized and aligned to the modified
   /// view's size and drawn behind it.
   func background<BG: View>(@ViewBuilder _ background: () -> BG) -> some View {
       BackgroundView(content: self, background: background())
   }
}

private struct BackgroundView<Content: View, BG: View>: View, PrimitiveView {
   let content: Content
   let background: BG

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       // Build both background and content as children; the control composes them
       node.addNode(at: 0, Node(view: background.view))
       node.addNode(at: 1, Node(view: content.view))
       let control = BackgroundContainerControl()
       control.background = node.children[0].control(at: 0)
       control.content = node.children[1].control(at: 0)
       // Ensure background draws first (index 0), then content (index 1)
       control.addSubview(control.background, at: 0)
       control.addSubview(control.content, at: 1)
       node.control = control
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: background.view)
       node.children[1].update(using: content.view)
   }

   private class BackgroundContainerControl: Control {
       var background: Control!
       var content: Control!

       override func size(proposedSize: Size) -> Size {
           // The container adopts the size of the content
           return content.size(proposedSize: proposedSize)
       }

       override func layout(size: Size) {
           super.layout(size: size)
           // Lay out content at its natural size under the given proposal
           let contentSize = content.size(proposedSize: size)
           content.layout(size: contentSize)
           content.layer.frame.position = .zero

           // Match background to content's frame size and origin
           background.layout(size: content.layer.frame.size)
           background.layer.frame.position = .zero
       }
   }
}
