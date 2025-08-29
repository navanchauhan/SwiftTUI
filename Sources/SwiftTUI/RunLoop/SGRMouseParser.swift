import Foundation

// Parse xterm SGR mouse reporting sequences (1006):
// Format: ESC [ < b ; x ; y (M|m)
// Where M = press/drag, m = release; x,y are 1-based columns/lines.
struct SGRMouseParser {
   struct Event {
       enum Kind {
           case press
           case release
           // Mouse wheel scroll (SGR 1006): delivers a delta in columns/lines.
           // dy: positive = scroll down; negative = scroll up
           // dx: positive = scroll right; negative = scroll left
           case wheel(dx: Int, dy: Int)
       }
       enum Button { case left, middle, right, other }
       let kind: Kind
       let button: Button
       let column: Int // 0-based
       let line: Int   // 0-based
   }

   private enum State { case idle, esc, bracket, lt, x, y }
   private var state: State = .idle
   private var acc: String = ""
   private var bVal: Int = 0
   private var xVal: Int = 0
   private var yVal: Int = 0

   var event: Event?

   mutating func parse(character: Character) -> Bool {
       switch state {
       case .idle:
           if character == "\u{1b}" { state = .esc; return true }
           return false
       case .esc:
           if character == "[" { state = .bracket; return true }
           reset(); return false
       case .bracket:
           if character == "<" { state = .lt; acc = ""; return true }
           reset(); return false
       case .lt:
           if character.isNumber { acc.append(character); return true }
           if character == ";" { bVal = Int(acc) ?? 0; acc = ""; state = .x; return true }
           reset(); return false
       case .x:
           if character.isNumber { acc.append(character); return true }
           if character == ";" { xVal = (Int(acc) ?? 1) - 1; acc = ""; state = .y; return true }
           reset(); return false
       case .y:
           if character.isNumber { acc.append(character); return true }
           if character == "M" || character == "m" {
               yVal = (Int(acc) ?? 1) - 1
               let col = max(0, xVal)
               let ln = max(0, yVal)

               // SGR 1006: Mouse wheel events set bit 6 (0x40). The low two bits then
               // indicate direction: 0=up, 1=down, 2=left, 3=right.
               if (bVal & 0x40) != 0 {
                   let base = bVal & 0x3
                   var dx = 0
                   var dy = 0
                   switch base {
                   case 0: dy = -1 // up
                   case 1: dy = 1  // down
                   case 2: dx = -1 // left
                   case 3: dx = 1  // right
                   default: break
                   }
                   event = Event(kind: .wheel(dx: dx, dy: dy), button: .other, column: col, line: ln)
                   reset()
                   return true
               }

               let kind: Event.Kind = (character == "M") ? .press : .release
               let button: Event.Button
               switch bVal & 0x3 { // lowest two bits are button for simple presses
               case 0: button = .left
               case 1: button = .middle
               case 2: button = .right
               default: button = .other
               }
               event = Event(kind: kind, button: button, column: col, line: ln)
               reset()
               return true
           }
           reset(); return false
       }
   }

   private mutating func reset() {
       state = .idle
       acc = ""
       bVal = 0
       xVal = 0
       yVal = 0
   }
}
