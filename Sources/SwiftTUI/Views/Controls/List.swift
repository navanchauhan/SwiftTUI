import Foundation

/// A simple vertical list container.
///
/// Implemented as a `ScrollView` containing a `VStack` of the provided row
/// content. Focus/scroll behavior mirrors `ScrollView`.
///
/// Notes:
/// - Row separators and advanced styling are not (yet) implemented.
/// - Behavior is a TUI-appropriate subset of SwiftUI's `List`.
public struct List<Content: View>: View, PrimitiveView {
   public let content: Content
   public let rowSpacing: Extended?

   /// Create a list of rows.
   /// - Parameters:
   ///   - rowSpacing: Optional spacing between rows (default: 0).
   ///   - content: Row views (often a `ForEach` or tuple of views).
   public init(rowSpacing: Extended? = 0, @ViewBuilder _ content: () -> Content) {
       self.content = content()
       self.rowSpacing = rowSpacing
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       node.addNode(at: 0, Node(view: ScrollView {
           VStack(content: content, alignment: .leading, spacing: rowSpacing)
       }.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       let composed = ScrollView {
           VStack(content: content, alignment: .leading, spacing: rowSpacing)
       }
       node.children[0].update(using: composed.view)
   }
}
