import Foundation

enum ASCII {
   static let EOT: Character = "\u{04}"
   static let DEL: Character = "\u{7f}"
   // Emacs-style control characters for caret navigation within text inputs
   static let CTRL_B: Character = "\u{02}" // move left
   static let CTRL_F: Character = "\u{06}" // move right
}
