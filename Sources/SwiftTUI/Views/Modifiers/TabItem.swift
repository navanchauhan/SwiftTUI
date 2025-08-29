import Foundation

// Environment key used by TabView to derive a tab's title from its child view.
struct TabItemTitleEnvironmentKey: EnvironmentKey {
   static var defaultValue: String? { nil }
}

extension EnvironmentValues {
   /// Internal storage for TabView child titles.
   var _tabItemTitle: String? {
       get { self[TabItemTitleEnvironmentKey.self] }
       set { self[TabItemTitleEnvironmentKey.self] = newValue }
   }
}

public extension View {
   /// Assign a title for the enclosing TabView's tab when using
   /// `TabView(selection:content:)` without an explicit titles array.
   func tabItem(title: String) -> some View {
       environment(\._tabItemTitle, title)
   }
}
