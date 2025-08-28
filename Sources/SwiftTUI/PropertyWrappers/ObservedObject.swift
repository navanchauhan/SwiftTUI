import Foundation

#if canImport(Combine)
import Combine
public typealias SwiftTUIAnyCancellable = AnyCancellable
public typealias SwiftTUIObservableObject = Combine.ObservableObject
#elseif canImport(OpenCombine)
import OpenCombine
public typealias SwiftTUIAnyCancellable = OpenCombine.AnyCancellable
public typealias SwiftTUIObservableObject = OpenCombine.ObservableObject
#endif

#if canImport(Combine) || canImport(OpenCombine)
@propertyWrapper
public struct ObservedObject<T: SwiftTUIObservableObject>: AnyObservedObject {
   public let initialValue: T

   public init(initialValue: T) {
       self.initialValue = initialValue
   }

   public init(wrappedValue: T) {
       self.initialValue = wrappedValue
   }

   public var wrappedValue: T {
       get { initialValue }
   }

   func subscribe(_ action: @escaping () -> Void) -> SwiftTUIAnyCancellable {
       initialValue.objectWillChange.sink(receiveValue: { _ in action() })
   }
}

protocol AnyObservedObject {
   func subscribe(_ action: @escaping () -> Void) -> SwiftTUIAnyCancellable
}
#endif
