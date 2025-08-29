import Foundation

/// Parity type for SwiftUI's scroll indicator visibility.
public enum ScrollIndicatorVisibility: Sendable {
case automatic
case hidden
case visible
}

// Environment storage for scroll indicator visibility
private struct ScrollIndicatorVisibilityEnvironmentKey: EnvironmentKey {
   static var defaultValue: ScrollIndicatorVisibility { .automatic }
}

extension EnvironmentValues {
   var scrollIndicatorVisibility: ScrollIndicatorVisibility {
       get { self[ScrollIndicatorVisibilityEnvironmentKey.self] }
       set { self[ScrollIndicatorVisibilityEnvironmentKey.self] = newValue }
   }
}

public extension View {
   /// Control the visibility of scroll indicators for descendant ScrollViews.
   /// - automatic: show indicators only when content overflows
   /// - hidden: never show indicators
   /// - visible: always show indicators (if axis is applicable)
   func scrollIndicators(_ visibility: ScrollIndicatorVisibility) -> some View {
       environment(\.scrollIndicatorVisibility, visibility)
   }
}
