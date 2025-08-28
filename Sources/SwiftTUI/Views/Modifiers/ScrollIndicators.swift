import Foundation

/// Parity type for SwiftUI's scroll indicator visibility. No visual effect in TUI.
public enum ScrollIndicatorVisibility: Sendable {
 case automatic
 case hidden
 case visible
}

public extension View {
 /// No-op parity modifier for scroll indicators. Kept for source compatibility; TUI has no indicators.
 func scrollIndicators(_ visibility: ScrollIndicatorVisibility) -> some View { self }
}
