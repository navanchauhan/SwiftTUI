import Foundation

struct CellAttributes: Equatable, Sendable {
   var bold: Bool
   // Terminal "faint" (low intensity). Mutually exclusive with bold in most terminals.
   // When both are requested, Renderer prefers bold.
   var faint: Bool
   var italic: Bool
   var underline: Bool
   var strikethrough: Bool
   var inverted: Bool

   init(
       bold: Bool = false,
       faint: Bool = false,
       italic: Bool = false,
       underline: Bool = false,
       strikethrough: Bool = false,
       inverted: Bool = false
   ) {
       self.bold = bold
       self.faint = faint
       self.italic = italic
       self.underline = underline
       self.strikethrough = strikethrough
       self.inverted = inverted
   }
}
