import Foundation

// Minimal animation and transition API surface for SwiftUI parity in TUI.
// These are no-ops for rendering but allow source compatibility and future
// expansion. Animations currently take effect immediately.

public struct Animation: Sendable, Equatable {
   public enum Curve: Sendable { case linear, easeIn, easeOut, easeInOut }
   public let curve: Curve
   public let duration: Double?

   public init(curve: Curve = .linear, duration: Double? = nil) {
       self.curve = curve
       self.duration = duration
   }

   public static let `default` = Animation(curve: .easeInOut, duration: nil)
   public static func easeInOut(duration: Double) -> Animation { Animation(curve: .easeInOut, duration: duration) }
   public static func linear(duration: Double) -> Animation { Animation(curve: .linear, duration: duration) }
}

public struct AnyTransition: Sendable, Equatable {
   // Marker type – no actual effect in terminal rendering yet
   private let id: String
   private init(_ id: String) { self.id = id }

   public static let identity = AnyTransition("identity")
   public static let opacity = AnyTransition("opacity")
   public static let slide = AnyTransition("slide")
   public static let scale = AnyTransition("scale")
}

public func withAnimation(_ animation: Animation? = .default, _ body: () -> Void) {
   // Immediate apply; if needed we could schedule staged invalidations here.
   body()
}

public extension View {
   // SwiftUI-like API; no-op in terminal environment for now.
   func animation<V: Equatable>(_ animation: Animation?, value: V) -> some View { self }

   func animation(_ animation: Animation?) -> some View { self }

   func transition(_ t: AnyTransition) -> some View { self }
}
