import Foundation

class Renderer {
   var layer: Layer

   /// Even though we only redraw invalidated parts of the screen, terminal
   /// drawing is currently still slow, as it involves moving the cursor
   /// position and printing a character there.
   /// This cache stores the screen content to see if printing is necessary.
   private var cache: [[Cell?]] = []

   /// The current cursor position, which might need to be updated before
   /// printing.
   private var currentPosition: Position = .zero

   private var currentForegroundColor: Color? = nil
   private var currentBackgroundColor: Color? = nil

   private var currentAttributes = CellAttributes()

   weak var application: Application?

   // Snapshot/debug toggles (read from environment)
   // - SWIFTTUI_NO_ALT=1      -> do not use alternate screen buffer
   // - SWIFTTUI_ASCII_SNAPSHOT=1 -> render background-only cells as block characters
   private let noAlternateBuffer: Bool
   private let asciiSnapshot: Bool
   private let focusHighlightEnabled: Bool

   private var didSetup = false /* will set true after setup */

   init(layer: Layer) {
       self.layer = layer
       let env = ProcessInfo.processInfo.environment
       self.noAlternateBuffer = (env["SWIFTTUI_NO_ALT"] == "1")
       self.asciiSnapshot = (env["SWIFTTUI_ASCII_SNAPSHOT"] == "1")
       self.focusHighlightEnabled = (env["SWIFTTUI_FOCUS_HIGHLIGHT"] == "1")
       setCache()
   }

   /// Explicit start hook to prepare the terminal after confirming a TTY.
   func start() {
       setup()
   }

   /// Draw only the invalidated part of the layer.
   func update() {
       if let invalidated = layer.invalidated {
           draw(rect: invalidated)
           layer.invalidated = nil
       }
   }

   func setCache() {
       cache = .init(repeating: .init(repeating: nil, count: layer.frame.size.width.intValue), count: layer.frame.size.height.intValue)
   }

   /// Draw a specific area, or the entire layer if the area is nil.
   func draw(rect: Rect? = nil) {
       if rect == nil { layer.invalidated = nil }
       let rect = rect ?? Rect(position: .zero, size: layer.frame.size)
       guard rect.size.width > 0, rect.size.height > 0 else {
           assertionFailure("Trying to draw in empty rect")
           return
       }
       for line in rect.minLine.intValue ... rect.maxLine.intValue {
           for column in rect.minColumn.intValue ... rect.maxColumn.intValue {
               let position = Position(column: Extended(column), line: Extended(line))
               let cell = layer.cell(at: position) ?? Cell(char: " ")
                   ; drawPixel(cell, at: Position(column: Extended(column), line: Extended(line)))
           }
       }
   }

   func stop() {
       if didSetup, !noAlternateBuffer {
           write(EscapeSequence.disableAlternateBuffer)
           write(EscapeSequence.showCursor)
       }
   }

   private func drawPixel(_ cell: Cell, at position: Position) {
       guard position.column >= 0, position.line >= 0, position.column < layer.frame.size.width, position.line < layer.frame.size.height else {
           return
       }
       var outCell = cell
       // Optional focus highlight overlay around first responder (opt-in via SWIFTTUI_FOCUS_HIGHLIGHT=1)
       if focusHighlightEnabled, let app = application, let fr = app.window.firstResponder?.layer.frame {
           let minC = fr.minColumn
           let maxC = fr.maxColumn
           let minL = fr.minLine
           let maxL = fr.maxLine
           if position.line == minL || position.line == maxL || position.column == minC || position.column == maxC {
               if position.line == minL && position.column == minC {
                   outCell = Cell(char: "┌", attributes: CellAttributes(inverted: true))
               } else if position.line == minL && position.column == maxC {
                   outCell = Cell(char: "┐", attributes: CellAttributes(inverted: true))
               } else if position.line == maxL && position.column == minC {
                   outCell = Cell(char: "└", attributes: CellAttributes(inverted: true))
               } else if position.line == maxL && position.column == maxC {
                   outCell = Cell(char: "┘", attributes: CellAttributes(inverted: true))
               } else if position.line == minL || position.line == maxL {
                   outCell = Cell(char: "─", attributes: CellAttributes(inverted: true))
               } else {
                   outCell = Cell(char: "│", attributes: CellAttributes(inverted: true))
               }
           }
       }
       if asciiSnapshot, outCell.char == " ", let bg = outCell.backgroundColor, bg != .default { outCell.char = "█" }
       if cache[position.line.intValue][position.column.intValue] != outCell {
           cache[position.line.intValue][position.column.intValue] = outCell
           if self.currentPosition != position {
               write(EscapeSequence.moveTo(position))
               self.currentPosition = position
           }
           if self.currentForegroundColor != outCell.foregroundColor {
               write(outCell.foregroundColor.foregroundEscapeSequence)
               self.currentForegroundColor = outCell.foregroundColor
           }
           let backgroundColor = outCell.backgroundColor ?? .default
           if self.currentBackgroundColor != backgroundColor {
               write(backgroundColor.backgroundEscapeSequence)
               self.currentBackgroundColor = backgroundColor
           }
           self.updateAttributes(outCell.attributes)
           write(String(outCell.char))
           self.currentPosition.column += 1
       }
   }

   private func setup() {
       if didSetup { return }
       if !noAlternateBuffer { write(EscapeSequence.enableAlternateBuffer) }
       write(EscapeSequence.clearScreen)
       write(EscapeSequence.moveTo(currentPosition))
       write(EscapeSequence.hideCursor)
       didSetup = true
   }

   private func updateAttributes(_ attributes: CellAttributes) {
       // Intensity (bold/faint) management: prefer bold over faint when both are requested.
       let currentBold = currentAttributes.bold
       let currentFaint = currentAttributes.faint
       let newBold = attributes.bold
       let newFaint = attributes.faint
       if currentBold != newBold || currentFaint != newFaint {
           if newBold {
               write(EscapeSequence.enableBold)
           } else if newFaint {
               write(EscapeSequence.enableFaint)
           } else {
               write(EscapeSequence.disableIntensity)
           }
       }
       if currentAttributes.italic != attributes.italic {
           if attributes.italic { write(EscapeSequence.enableItalic) }
           else { write(EscapeSequence.disableItalic) }
       }
       if currentAttributes.underline != attributes.underline {
           if attributes.underline { write(EscapeSequence.enableUnderline) }
           else { write(EscapeSequence.disableUnderline) }
       }
       if currentAttributes.strikethrough != attributes.strikethrough {
           if attributes.strikethrough { write(EscapeSequence.enableStrikethrough) }
           else { write(EscapeSequence.disableStrikethrough) }
       }
       if currentAttributes.inverted != attributes.inverted {
           if attributes.inverted { write(EscapeSequence.enableInverted) }
           else { write(EscapeSequence.disableInverted) }
       }
       currentAttributes = attributes
   }

}

private func write(_ str: String) {
   str.withCString { _ = write(STDOUT_FILENO, $0, strlen($0)) }
}