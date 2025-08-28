import Foundation

/// A property wrapper that stores focus-related state and participates in the
/// view graph like @State. Changing the value schedules a view update so that
/// `.focused(...)` modifiers can react and request/resign focus.
@propertyWrapper
public struct FocusState<T>: AnyState {
   public let initialValue: T

   public init(initialValue: T) {
       self.initialValue = initialValue
   }

   public init(wrappedValue: T) {
       self.initialValue = wrappedValue
   }

   // Convenience default initializer for optional values
   public init() where T: ExpressibleByNilLiteral {
       self.initialValue = nil
   }

   var valueReference = StateReference()

   public var wrappedValue: T {
       get {
           guard let node = valueReference.node,
                 let label = valueReference.label
           else {
               assertionFailure("Attempting to access @FocusState before view is instantiated")
               return initialValue
           }
           if let value = node.state[label] { return value as! T }
           return initialValue
       }
       nonmutating set {
           guard let node = valueReference.node,
                 let label = valueReference.label
           else {
               assertionFailure("Attempting to modify @FocusState before view is instantiated")
               return
           }
           node.state[label] = newValue
           DispatchQueue.main.async {
               node.root.application?.invalidateNode(node)
           }
       }
   }

   public var projectedValue: Binding<T> {
       Binding<T>(get: { wrappedValue }, set: { wrappedValue = $0 })
   }
}
