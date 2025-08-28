import Foundation

public extension View {
  /// Convenience to clip a view with a rounded rectangle mask.
  /// Matches SwiftUI's API surface, implemented via clipShape.
  func cornerRadius(_ radius: Int) -> some View {
      clipShape(RoundedRectangle(cornerRadius: radius))
  }
}
