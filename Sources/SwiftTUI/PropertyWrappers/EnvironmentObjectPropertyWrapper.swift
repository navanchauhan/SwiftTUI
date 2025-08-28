import Foundation
#if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
import OpenCombine
#endif

#if canImport(Combine) || canImport(OpenCombine)
/// A simplified implementation of SwiftUI's @EnvironmentObject.
/// Looks up an object injected with .environmentObject(_:) in the nearest ancestor.
@propertyWrapper
public struct EnvironmentObject<T: SwiftTUIObservableObject>: AnyObservedObject, AnyEnvironment {
   public init() {}

   // Reference to the current node, wired via setupEnvironmentProperties like @Environment
   var valueReference = EnvironmentReference()

   public var wrappedValue: T {
       get {
           guard let node = valueReference.node else {
               fatalError("Attempting to access @EnvironmentObject before view is instantiated")
           }
           var env = makeEnvironment(node: node)
           if let obj = env._environmentObjects[ObjectIdentifier(T.self)] as? T {
               return obj
           }
           fatalError("No environment object of type \(T.self) found. Did you forget to call .environmentObject(_:) on an ancestor view?")
       }
   }

   private func makeEnvironment(node: Node) -> EnvironmentValues {
       if let parent = node.parent {
           var env = makeEnvironment(node: parent)
           node.environment?(&env)
           return env
       }
       var env = EnvironmentValues()
       node.environment?(&env)
       return env
   }

   // Subscribe to changes
   func subscribe(_ action: @escaping () -> Void) -> SwiftTUIAnyCancellable {
       let obj: T = wrappedValue
       return obj.objectWillChange.sink(receiveValue: { _ in action() })
   }
}
#endif
