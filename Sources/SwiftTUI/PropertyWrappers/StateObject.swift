import Foundation

#if canImport(Combine)
import Combine
#elseif canImport(OpenCombine)
import OpenCombine
#endif

#if canImport(Combine) || canImport(OpenCombine)
/// A simplified implementation of SwiftUI's @StateObject.
/// Owns the lifecycle of an observable object and stores it in the Node's state.
@propertyWrapper
public struct StateObject<T: SwiftTUIObservableObject>: AnyState, AnyObservedObject {
   private let makeInitialValue: () -> T

   public init(wrappedValue: @autoclosure @escaping () -> T) {
       self.makeInitialValue = wrappedValue
   }

   public var wrappedValue: T {
       // Lazily create and store in node.state the first time we access it
       get {
           guard let node = valueReference.node,
                 let label = valueReference.label else {
               // Best effort: construct a fresh instance before the node is wired
               return makeInitialValue()
           }
           if let existing = node.state[label] as? T {
               return existing
           }
           let value = makeInitialValue()
           node.state[label] = value
           return value
       }
   }

   // MARK: - AnyState (for wiring node+label via reflection)
   var valueReference = StateReference()

   // MARK: - AnyObservedObject (subscribe to changes)
   func subscribe(_ action: @escaping () -> Void) -> SwiftTUIAnyCancellable {
       // Ensure we access the stored value so it's initialized before subscribing
       let obj = wrappedValue
       return obj.objectWillChange.sink(receiveValue: { _ in action() })
   }
}
#endif