import Foundation

// Minimal accessibility hooks. These attach metadata to the environment so
// apps can author semantic information even if the renderer does not
// currently consume it.

private struct AccessibilityLabelKey: EnvironmentKey {
   static var defaultValue: String? { nil }
}

private struct AccessibilityHintKey: EnvironmentKey {
   static var defaultValue: String? { nil }
}

public extension EnvironmentValues {
   var accessibilityLabel: String? {
       get { self[AccessibilityLabelKey.self] }
       set { self[AccessibilityLabelKey.self] = newValue }
   }

   var accessibilityHint: String? {
       get { self[AccessibilityHintKey.self] }
       set { self[AccessibilityHintKey.self] = newValue }
   }
}

public extension View {
   func accessibilityLabel(_ label: String) -> some View {
       environment(\.accessibilityLabel, label)
   }

   func accessibilityHint(_ hint: String) -> some View {
       environment(\.accessibilityHint, hint)
   }
}
