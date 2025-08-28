import Foundation

/// A minimal navigation stack that renders only the top-most destination.
///
/// Descendant views can push new destinations using `NavigationLink`.
public struct NavigationStack<Content: View>: View, PrimitiveView, LayoutRootView {
   public let root: Content

   public init(@ViewBuilder _ content: () -> Content) {
       self.root = content()
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       // Child nodes represent pages in the stack; start with the root page
       node.addNode(at: 0, Node(view: root.view))

       // Container control that will display only the top page controls
       node.control = NavigationContainerControl()

       // Inject push/pop actions into the environment for descendants
       node.environment = { env in
           env._navigationPush = { [weak node] view in
               guard let node else { return }
               node.addNode(at: node.children.count, Node(view: view))
           }
           env._navigationPop = { [weak node] in
               guard let node, node.children.count > 1 else { return }
               node.removeNode(at: node.children.count - 1)
           }
       }
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: root.view)
       // Environment closures are stable; nothing else to update here
   }

   // LayoutRootView: keep container in sync with top page controls
   func loadData(node: Node) {
       refreshTop(node: node)
   }

   func insertControl(at index: Int, node: Node) {
       refreshTop(node: node)
   }

   func removeControl(at index: Int, node: Node) {
       refreshTop(node: node)
   }

   private func refreshTop(node: Node) {
       guard let container = node.control as? NavigationContainerControl else { return }
       // Remove all current children from container
       for i in (0 ..< container.children.count).reversed() {
           container.removeSubview(at: i)
       }
       // Install controls from the top-most child node (page)
       guard let top = node.children.last else { return }
       for i in 0 ..< top.size {
           container.addSubview(top.control(at: i), at: i)
       }
   }

   private class NavigationContainerControl: Control {
       override func size(proposedSize: Size) -> Size {
           // Fill proposed area; content lays out inside
           proposedSize
       }

       override func layout(size: Size) {
           super.layout(size: size)
           for child in children {
               child.layout(size: size)
               child.layer.frame.position = .zero
           }
       }
   }
}
