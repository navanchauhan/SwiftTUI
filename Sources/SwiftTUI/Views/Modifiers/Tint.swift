import Foundation

// SwiftUI’s `.tint(_:)` maps closely to accentColor for many controls.
// Provide it as a convenience alias to improve source compatibility.
public extension View {
   func tint(_ color: Color) -> some View { accentColor(color) }
}
