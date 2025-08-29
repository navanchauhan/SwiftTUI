import Foundation

public struct SecureField: View, PrimitiveView {
   public let placeholder: String?
   enum Mode {
       case action((_ text: String) -> Void)
       case binding(text: Binding<String>, onCommit: () -> Void)
   }
   let mode: Mode
   @Environment(\.isEnabled) private var isEnabled: Bool

   @Environment(\.placeholderColor) private var placeholderColor: Color
   @Environment(\.onSubmit) private var onSubmitAction: (() -> Void)?

   // Legacy initializer: submit text on Enter and clear
   public init(placeholder: String? = nil, action: @escaping (String) -> Void) {
       self.placeholder = placeholder
       self.mode = .action(action)
   }

   // New initializer: live Binding editing; onCommit fires on Enter (does not clear)
   public init(placeholder: String? = nil, text: Binding<String>, onCommit: @escaping () -> Void = {}) {
       self.placeholder = placeholder
       self.mode = .binding(text: text, onCommit: onCommit)
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       let c = SecureFieldControl(placeholder: placeholder ?? "", placeholderColor: placeholderColor, mode: mode, onSubmit: onSubmitAction)
       c.isEnabled = isEnabled
       node.control = c
   }

   func updateNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       node.view = self
       if let c = node.control as? SecureFieldControl {
           c.placeholder = placeholder ?? ""
           c.placeholderColor = placeholderColor
           c.mode = mode
           c.onSubmit = onSubmitAction
           c.isEnabled = isEnabled
           c.layer.invalidate()
       }
   }

   private class SecureFieldControl: Control {
       var placeholder: String
       var placeholderColor: Color
       var mode: Mode
       var onSubmit: (() -> Void)?
       var isEnabled: Bool = true

       // Internal buffer used only in action-mode
       private var internalText: String = ""
       // Caret position within edited text [0...count]
       private var cursorIndex: Int = 0
        private var caretInitialized: Bool = false

       init(placeholder: String, placeholderColor: Color, mode: Mode, onSubmit: (() -> Void)?) {
           self.placeholder = placeholder
           self.placeholderColor = placeholderColor
           self.mode = mode
           self.onSubmit = onSubmit
       }

       private var editedText: String {
           get {
               switch mode {
               case .action:
                   return internalText
               case .binding(let binding, _):
                   return binding.wrappedValue
               }
           }
           set {
               switch mode {
               case .action:
                   internalText = newValue
               case .binding(let binding, _):
                   binding.wrappedValue = newValue
               }
               if cursorIndex > newValue.count { cursorIndex = newValue.count }
           }
       }

       override func size(proposedSize: Size) -> Size {
           return Size(width: Extended(max(editedText.count, placeholder.count)) + 1, height: 1)
       }

       override func handleEvent(_ char: Character) {
           guard isEnabled else { return }
           if !caretInitialized { cursorIndex = editedText.count; caretInitialized = true }
           if char == "\n" || char == "\r" {
               switch mode {
               case .action(let submit):
                   submit(editedText)
                   internalText = ""
                   cursorIndex = 0
               case .binding(_, let onCommit):
                   onCommit()
                   onSubmit?()
               }
               layer.invalidate()
               return
           }

           // Caret navigation control characters
           if char == ASCII.CTRL_B {
               if cursorIndex > 0 { cursorIndex -= 1; layer.invalidate() }
               return
           }
           if char == ASCII.CTRL_F {
               let count = editedText.count
               if cursorIndex < count { cursorIndex += 1; layer.invalidate() }
               return
           }

           if char == ASCII.DEL || char == ASCII.BS {
               if cursorIndex > 0 && !editedText.isEmpty {
                   var t = editedText
                   let i = t.index(t.startIndex, offsetBy: cursorIndex - 1)
                   t.remove(at: i)
                   editedText = t
                   cursorIndex -= 1
                   layer.invalidate()
               }
               return
           }

           // Insert at caret
           var t = editedText
           let i = t.index(t.startIndex, offsetBy: cursorIndex)
           t.insert(char, at: i)
           editedText = t
           cursorIndex += 1
           layer.invalidate()
       }

       // Note: caret navigation handled via control characters in handleEvent

       override func cell(at position: Position) -> Cell? {
           guard position.line == 0 else { return nil }
           let text = editedText
           if text.isEmpty {
               if position.column.intValue < placeholder.count {
                   let caretCol = min(cursorIndex, placeholder.count)
                   let showUnderline = (position.column.intValue == caretCol) && isFirstResponder
                   let char = placeholder[placeholder.index(placeholder.startIndex, offsetBy: position.column.intValue)]
                   var cell = Cell(
                       char: char,
                       foregroundColor: placeholderColor,
                       attributes: CellAttributes(underline: showUnderline)
                   )
                   if !isEnabled { cell.attributes.faint = true }
                   return cell
               }
               return .init(char: " ")
           }
           // Mask actual characters with bullets
           let col = position.column.intValue
           if isFirstResponder && col == cursorIndex {
               if cursorIndex == text.count {
                   var c = Cell(char: " ", attributes: CellAttributes(underline: true)); if !isEnabled { c.attributes.faint = true }; return c
               } else {
                   var c = Cell(char: "•", attributes: CellAttributes(underline: true)); if !isEnabled { c.attributes.faint = true }; return c
               }
           }
           guard col < text.count else { return .init(char: " ") }
           var c = Cell(char: "•"); if !isEnabled { c.attributes.faint = true }; return c
       }

       override var selectable: Bool { isEnabled }
       override var isTextInput: Bool { true }

       override func becomeFirstResponder() {
           super.becomeFirstResponder()
           layer.invalidate()
       }

       override func resignFirstResponder() {
           super.resignFirstResponder()
           layer.invalidate()
       }
   }
}