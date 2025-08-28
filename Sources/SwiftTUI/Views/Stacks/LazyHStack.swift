import Foundation

/// A minimal LazyHStack that mirrors HStack behavior.
///
/// Note: This implementation is not actually lazy; it forwards to HStack.
/// It exists to provide API parity with SwiftUI in terminal contexts.
public struct LazyHStack<Content: View>: View, PrimitiveView {
   public let content: Content
   let alignment: VerticalAlignment
   let spacing: Extended?

   public init(alignment: VerticalAlignment = .top, spacing: Extended? = nil, @ViewBuilder _ content: () -> Content) {
       self.content = content()
       self.alignment = alignment
       self.spacing = spacing
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       // Delegate to HStack for layout/behavior
       node.addNode(at: 0, Node(view: HStack(alignment: alignment, spacing: spacing) { content }.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       let h = HStack(alignment: alignment, spacing: spacing) { content }
       node.children[0].update(using: h.view)
   }
}
