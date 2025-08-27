import Foundation

// Parse xterm SGR mouse reporting sequences (1006):
// Format: ESC [ < b ; x ; y (M|m)
// Where M = press/drag, m = release; x,y are 1-based columns/lines.
struct SGRMouseParser {
   struct Event {
       enum Kind { case press, release }
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
               let kind: Event.Kind = (character == "M") ? .press : .release
               let button: Event.Button
               switch bVal & 0x3 { // lowest two bits are button for simple presses
               case 0: button = .left
               case 1: button = .middle
               case 2: button = .right
               default: button = .other
               }
               event = Event(kind: kind, button: button, column: max(0, xVal), line: max(0, yVal))
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