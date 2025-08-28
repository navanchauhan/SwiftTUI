import Foundation

// Internal navigation environment keys for push/pop actions.
// Exposed to views via @Environment in NavigationLink and related controls.

struct NavigationPushEnvironmentKey: EnvironmentKey {
   static var defaultValue: ((GenericView) -> Void)? { nil }
}

struct NavigationPopEnvironmentKey: EnvironmentKey {
   static var defaultValue: (() -> Void)? { nil }
}

extension EnvironmentValues {
   var _navigationPush: ((GenericView) -> Void)? {
       get { self[NavigationPushEnvironmentKey.self] }
       set { self[NavigationPushEnvironmentKey.self] = newValue }
   }

   var _navigationPop: (() -> Void)? {
       get { self[NavigationPopEnvironmentKey.self] }
       set { self[NavigationPopEnvironmentKey.self] = newValue }
   }
}
