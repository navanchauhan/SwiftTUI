import Foundation

/// A minimal LazyVStack that mirrors VStack behavior.
///
/// Note: This implementation is not actually lazy; it forwards to VStack.
/// It exists to provide API parity with SwiftUI in terminal contexts.
public struct LazyVStack<Content: View>: View, PrimitiveView {
   public let content: Content
   let alignment: HorizontalAlignment
   let spacing: Extended?

   public init(alignment: HorizontalAlignment = .leading, spacing: Extended? = nil, @ViewBuilder _ content: () -> Content) {
       self.content = content()
       self.alignment = alignment
       self.spacing = spacing
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       // Delegate to VStack for layout/behavior
       node.addNode(at: 0, Node(view: VStack(content: content, alignment: alignment, spacing: spacing).view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       let v = VStack(content: content, alignment: alignment, spacing: spacing)
       node.children[0].update(using: v.view)
   }
}
