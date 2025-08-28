import Foundation

// Storage and accessors for environment objects by type
struct _EnvironmentObjectsKey: EnvironmentKey {
   static var defaultValue: [ObjectIdentifier: Any] { [:] }
}

public extension EnvironmentValues {
   var _environmentObjects: [ObjectIdentifier: Any] {
       get { self[_EnvironmentObjectsKey.self] }
       set { self[_EnvironmentObjectsKey.self] = newValue }
   }
}