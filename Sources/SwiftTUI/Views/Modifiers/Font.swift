import Foundation

// Minimal font APIs to improve SwiftUI parity in terminal context.
// We map common font weights to the existing bold environment attribute.

public enum FontWeight: Sendable {
   case ultraLight
   case thin
   case light
   case regular
   case medium
   case semibold
   case bold
   case heavy
   case black
}

private extension FontWeight {
   // Treat semibold and heavier as bold in TUI cells.
   var isBold: Bool {
       switch self {
       case .ultraLight, .thin, .light, .regular, .medium:
           return false
       case .semibold, .bold, .heavy, .black:
           return true
       }
   }
}

public struct Font: Sendable {
   public enum Design: Sendable {
       case `default`
       case monospaced
       case rounded
       case serif
   }

   let weight: FontWeight?
   let size: Double?
   let design: Design?

   private init(weight: FontWeight? = nil, size: Double? = nil, design: Design? = nil) {
       self.weight = weight
       self.size = size
       self.design = design
   }

   // Minimal .system initializer; size/design are currently ignored in rendering.
   public static func system(size: Double, weight: FontWeight = .regular, design: Design = .default) -> Font {
       Font(weight: weight, size: size, design: design)
   }
}

public extension View {
   /// Map SwiftUI-like fontWeight to terminal bold attribute.
   func fontWeight(_ weight: FontWeight) -> some View {
       environment(\.bold, weight.isBold)
   }

   /// Minimal .font support: maps the provided font's weight to bold; size/design are currently ignored.
   func font(_ font: Font) -> some View {
       environment(\.bold, (font.weight ?? .regular).isBold)
   }
}
