import Foundation

/// A minimal terminal Image implementation.
///
/// Two forms are supported:
/// - ASCII: provide a matrix of characters (multiline String or [String]).
/// - Colors: provide a 2D matrix of optional Colors; non-nil cells render as
///   background-colored blocks (using a space character), nil cells are transparent.
public struct Image: View, PrimitiveView {
   private enum Storage {
       case ascii([String])
       case colors([[Color?]])
   }

   private let storage: Storage

   @Environment(\.foregroundColor) private var foregroundColor: Color

   /// Create an Image from a multiline ASCII string. Lines are split on "\n".
   public init(_ ascii: String) {
       let lines = ascii.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
       self.storage = .ascii(lines)
   }

   /// Create an Image from an array of ASCII lines.
   public init(lines: [String]) {
       self.storage = .ascii(lines)
   }

   /// Create an Image from a color matrix. `colors[row][column]` defines the
   /// background color at that cell; nil means transparent for that cell.
   public init(colors: [[Color?]]) {
       self.storage = .colors(colors)
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       node.control = ImageControl(storage: storage, foregroundColor: foregroundColor)
   }

   func updateNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       node.view = self
       if let control = node.control as? ImageControl {
           control.storage = storage
           control.foregroundColor = foregroundColor
           control.layer.invalidate()
       }
   }

   private class ImageControl: Control {
       var storage: Storage
       var foregroundColor: Color

       init(storage: Storage, foregroundColor: Color) {
           self.storage = storage
           self.foregroundColor = foregroundColor
       }

       override func size(proposedSize: Size) -> Size {
           switch storage {
           case .ascii(let lines):
               let height = Extended(lines.count)
               let width = Extended(lines.map { $0.count }.max() ?? 0)
               return Size(width: width, height: height)
           case .colors(let cols):
               let height = Extended(cols.count)
               let width = Extended(cols.map { $0.count }.max() ?? 0)
               return Size(width: width, height: height)
           }
       }

       override func cell(at position: Position) -> Cell? {
           guard position.line >= 0, position.column >= 0 else { return nil }
           switch storage {
           case .ascii(let lines):
               let r = position.line.intValue
               guard r < lines.count else { return nil }
               let line = lines[r]
               let c = position.column.intValue
               if c < line.count {
                   let idx = line.index(line.startIndex, offsetBy: c)
                   let ch = line[idx]
                   return Cell(char: ch, foregroundColor: foregroundColor)
               } else {
                   // Pad short lines with spaces
                   return Cell(char: " ", foregroundColor: foregroundColor)
               }
           case .colors(let cols):
               let r = position.line.intValue
               guard r < cols.count else { return nil }
               let row = cols[r]
               let c = position.column.intValue
               guard c < row.count else { return nil }
               if let bg = row[c] {
                   // Draw as background-colored space
                   return Cell(char: " ", backgroundColor: bg)
               } else {
                   // Transparent cell
                   return nil
               }
           }
       }
   }
}
