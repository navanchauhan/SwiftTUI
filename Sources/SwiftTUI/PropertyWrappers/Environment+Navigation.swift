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

// Public-facing convenience to trigger a pop from within a destination view.
public extension EnvironmentValues {
  /// Pop the top destination in the nearest enclosing NavigationStack, if any.
  /// When there is only the root view on the stack, this is a no-op.
  var navigationPop: (() -> Void)? {
      get { self[NavigationPopEnvironmentKey.self] }
      set { self[NavigationPopEnvironmentKey.self] = newValue }
  }
}
