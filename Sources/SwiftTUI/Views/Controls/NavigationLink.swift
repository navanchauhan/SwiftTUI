import Foundation

/// A simple navigation link that pushes a destination when activated.
public struct NavigationLink<Label: View, Destination: View>: View, PrimitiveView {
   let label: VStack<Label>
   let destination: Destination

   @Environment(\._navigationPush) private var _push

   public init(destination: Destination, @ViewBuilder label: () -> Label) {
       self.destination = destination
       self.label = VStack(content: label())
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       // Access environment to capture push handler
       setupEnvironmentProperties(node: node)
       // Implement via a Button to reuse focus/activation behavior
       let button = Button(action: {
           if let p = _push { p(destination.view) }
       }, hover: {}) { label }
       node.addNode(at: 0, Node(view: button.view))
   }

   func updateNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       node.view = self
       let button = Button(action: {
           if let p = _push { p(destination.view) }
       }, hover: {}) { label }
       node.children[0].update(using: button.view)
   }
}
