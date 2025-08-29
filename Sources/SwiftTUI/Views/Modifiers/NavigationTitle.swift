import Foundation

// Navigation title environment and modifier, used by NavigationStack to render
// a simple title bar when present.

private struct NavigationTitleKey: EnvironmentKey {
   static var defaultValue: String? { nil }
}

public extension EnvironmentValues {
   var navigationTitle: String? {
       get { self[NavigationTitleKey.self] }
       set { self[NavigationTitleKey.self] = newValue }
   }
}

public extension View {
   func navigationTitle(_ title: String) -> some View {
       environment(\.navigationTitle, title)
   }
}
