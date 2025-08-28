import Foundation

public struct TextField: View, PrimitiveView {
   public let placeholder: String?
   // Operation modes:
   // - action: submit current contents on Enter and clear (legacy SwiftTUI behavior)
   // - binding: live-edit a Binding<String>; optional onCommit on Enter (does not clear)
   enum Mode {
       case action((_ text: String) -> Void)
       case binding(text: Binding<String>, onCommit: () -> Void)
   }
   let mode: Mode

   @Environment(\.placeholderColor) private var placeholderColor: Color

   // Legacy initializer: action fires on Enter; clears text afterwards
   public init(placeholder: String? = nil, action: @escaping (String) -> Void) {
       self.placeholder = placeholder
       self.mode = .action(action)
   }

   // New initializer: live-edit Binding<String>; optional onCommit invoked on Enter (does not clear)
   public init(placeholder: String? = nil, text: Binding<String>, onCommit: @escaping () -> Void = {}) {
       self.placeholder = placeholder
       self.mode = .binding(text: text, onCommit: onCommit)
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       node.control = TextFieldControl(placeholder: placeholder ?? "", placeholderColor: placeholderColor, mode: mode)
   }

   func updateNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       node.view = self
       if let c = node.control as? TextFieldControl {
           c.placeholder = placeholder ?? ""
           c.placeholderColor = placeholderColor
           c.mode = mode
           c.layer.invalidate()
       }
   }

   private class TextFieldControl: Control {
       var placeholder: String
       var placeholderColor: Color
       var mode: Mode

       // Internal buffer used only in action-mode
       private var internalText: String = ""

       init(placeholder: String, placeholderColor: Color, mode: Mode) {
           self.placeholder = placeholder
           self.placeholderColor = placeholderColor
           self.mode = mode
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
           }
       }

       override func size(proposedSize: Size) -> Size {
           return Size(width: Extended(max(editedText.count, placeholder.count)) + 1, height: 1)
       }

       override func handleEvent(_ char: Character) {
           if char == "\n" || char == "\r" {
               switch mode {
               case .action(let submit):
                   submit(editedText)
                   internalText = ""
               case .binding(_, let onCommit):
                   onCommit()
               }
               layer.invalidate()
               return
           }

           if char == ASCII.DEL {
               if !editedText.isEmpty {
                   editedText.removeLast()
                   layer.invalidate()
               }
               return
           }

           editedText.append(char)
           layer.invalidate()
       }

       override func cell(at position: Position) -> Cell? {
           guard position.line == 0 else { return nil }
           let text = editedText
           if text.isEmpty {
               if position.column.intValue < placeholder.count {
                   let showUnderline = (position.column.intValue == 0) && isFirstResponder
                   let char = placeholder[placeholder.index(placeholder.startIndex, offsetBy: position.column.intValue)]
                   return Cell(
                       char: char,
                       foregroundColor: placeholderColor,
                       attributes: CellAttributes(underline: showUnderline)
                   )
               }
               return .init(char: " ")
           }
           if position.column.intValue == text.count, isFirstResponder { return Cell(char: " ", attributes: CellAttributes(underline: true)) }
           guard position.column.intValue < text.count else { return .init(char: " ") }
           return Cell(char: text[text.index(text.startIndex, offsetBy: position.column.intValue)])
       }

       override var selectable: Bool { true }

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

extension EnvironmentValues {
   public var placeholderColor: Color {
       get { self[PlaceholderColorEnvironmentKey.self] }
       set { self[PlaceholderColorEnvironmentKey.self] = newValue }
   }
}

private struct PlaceholderColorEnvironmentKey: EnvironmentKey {
   static var defaultValue: Color { .default }
}
