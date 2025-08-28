import Foundation

struct ArrowKeyParser {
    enum ArrowKey {
        case up
        case down
        case right
        case left
    }

    // 0: idle, 1: ESC, 2: ESC [, 3: ESC O (SS3)
    private var partial: Int = 0

    var arrowKey: ArrowKey?

    mutating func parse(character: Character) -> Bool {
        if partial == 0 && character == "\u{1b}" {
            partial = 1
            return true
        }
        if partial == 1 {
            if character == "[" { partial = 2; return true }
            if character == "O" { partial = 3; return true }
        }
        if partial == 2 {
            switch character {
            case "A": arrowKey = .up; partial = 0; return true
            case "B": arrowKey = .down; partial = 0; return true
            case "C": arrowKey = .right; partial = 0; return true
            case "D": arrowKey = .left; partial = 0; return true
            case "0","1","2","3","4","5","6","7","8","9",";":
                return true
            default:
                arrowKey = nil; partial = 0; return false
            }
        }
        if partial == 3 {
            switch character {
            case "A": arrowKey = .up
            case "B": arrowKey = .down
            case "C": arrowKey = .right
            case "D": arrowKey = .left
            default:
                arrowKey = nil; partial = 0; return false
            }
            partial = 0
            return true
        }
        arrowKey = nil
        partial = 0
        return false
    }

}
