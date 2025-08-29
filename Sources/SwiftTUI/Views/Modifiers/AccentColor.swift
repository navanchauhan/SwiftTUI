import Foundation

// Accent color environment and modifier, used by controls to render selected
// or highlighted elements in a cohesive theme color.

private struct AccentColorEnvironmentKey: EnvironmentKey {
   static var defaultValue: Color { .blue }
}

public extension EnvironmentValues {
   /// The accent color for interactive controls (selection, indicators, etc.).
   /// Defaults to blue; views can override via `.accentColor(_:)`.
   var accentColor: Color {
       get { self[AccentColorEnvironmentKey.self] }
       set { self[AccentColorEnvironmentKey.self] = newValue }
   }
}

public extension View {
   /// Sets the accent color for this view and its descendants.
   func accentColor(_ color: Color) -> some View {
       environment(\.accentColor, color)
   }
}
