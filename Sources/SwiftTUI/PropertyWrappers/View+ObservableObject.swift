import Foundation
#if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
import OpenCombine
#endif

extension View {
   func setupObservedObjectProperties(node: Node) {
       for (label, value) in Mirror(reflecting: self).children {
           if let label, let observedObject = value as? AnyObservedObject {
               node.subscriptions[label] = observedObject.subscribe {
                   Task { @MainActor in
                    node.root.application?.invalidateNode(node)
                }
               }
           }
       }
   }
}
