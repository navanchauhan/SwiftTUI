import Foundation

/// A thin wrapper providing SwiftUI's NavigationView API.
///
/// In SwiftTUI, NavigationView forwards to NavigationStack for terminal-friendly
/// navigation behavior (minimal push/pop via NavigationLink).
public struct NavigationView<Content: View>: View, PrimitiveView {
   public let content: Content

   public init(@ViewBuilder _ content: () -> Content) {
       self.content = content()
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       // Delegate to NavigationStack with the same content
       node.addNode(at: 0, Node(view: NavigationStack { content }.view))
   }

   func updateNode(_ node: Node) {
       node.view = self
       let forwarded = NavigationStack { content }
       node.children[0].update(using: forwarded.view)
   }
}
