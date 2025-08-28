import Foundation

#if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
import OpenCombine
#endif

#if canImport(Combine) || canImport(OpenCombine)
public extension View {
   func environmentObject<T: SwiftTUIObservableObject>(_ object: T) -> some View {
       SetEnvironmentObject(content: self, object: object)
   }
}

private struct SetEnvironmentObject<Content: View, T: SwiftTUIObservableObject>: View, PrimitiveView {
   let content: Content
   let object: T

   init(content: Content, object: T) {
       self.content = content
       self.object = object
   }

   static var size: Int? { Content.size }

   func buildNode(_ node: Node) {
       node.addNode(at: 0, Node(view: content.view))
       node.environment = { env in
           var objects = env._environmentObjects
           objects[ObjectIdentifier(T.self)] = object
           env._environmentObjects = objects
       }
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.environment = { env in
           var objects = env._environmentObjects
           objects[ObjectIdentifier(T.self)] = object
           env._environmentObjects = objects
       }
       node.children[0].update(using: content.view)
   }
}
#endif
