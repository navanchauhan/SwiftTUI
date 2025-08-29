import Foundation

// Environment key for enabled/disabled state. Defaults to true (enabled).
private struct IsEnabledEnvironmentKey: EnvironmentKey {
   static var defaultValue: Bool { true }
}

public extension EnvironmentValues {
   var isEnabled: Bool {
       get { self[IsEnabledEnvironmentKey.self] }
       set { self[IsEnabledEnvironmentKey.self] = newValue }
   }
}

public extension View {
   /// Disables user interaction for this view and its descendants when `disabled` is true.
   func disabled(_ disabled: Bool) -> some View {
       environment(\.isEnabled, !disabled)
   }
}
