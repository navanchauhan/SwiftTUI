import Foundation

/// A simple picker control that cycles through a set of string options.
///
/// Keyboard: use left/right arrows or h/l to change the selection.
/// Rendering: shows "< option >" and an optional leading label.
public struct Picker<Label: View>: View, PrimitiveView {
   let options: [String]
   let selection: Binding<Int>
   let label: VStack<Label>?

   /// Picker with a custom label view
   public init(selection: Binding<Int>, options: [String], @ViewBuilder label: () -> Label) {
       self.selection = selection
       self.options = options
       self.label = VStack(content: label())
   }

   /// Picker with a text label
   public init(_ title: String, selection: Binding<Int>, options: [String]) where Label == Text {
       self.selection = selection
       self.options = options
       self.label = VStack(content: Text(title))
   }

   /// Picker without a label
   public init(selection: Binding<Int>, options: [String]) where Label == EmptyView {
       self.selection = selection
       self.options = options
       self.label = nil
   }


   // MARK: - Tag-based selection (Binding<T>) convenience

   /// Picker with a custom label view and tag-based selection mapping.
   /// Provide options as an array of (title, tag) pairs; selection binds to the tag type.
   public init<T: Equatable>(selection: Binding<T>, options: [(String, T)], @ViewBuilder label: () -> Label) {
       let titles = options.map { $0.0 }
       let tags = options.map { $0.1 }
       let indexBinding = Binding<Int>(
           get: {
               if let idx = tags.firstIndex(where: { $0 == selection.wrappedValue }) { return idx }
               return 0
           },
           set: { newIndex in
               let idx = max(0, min(newIndex, tags.count - 1))
               selection.wrappedValue = tags[idx]
           }
       )
       self.selection = indexBinding
       self.options = titles
       self.label = VStack(content: label())
   }

   /// Picker with a text label and tag-based selection mapping.
   public init<T: Equatable>(_ title: String, selection: Binding<T>, options: [(String, T)]) where Label == Text {
       let titles = options.map { $0.0 }
       let tags = options.map { $0.1 }
       let indexBinding = Binding<Int>(
           get: {
               if let idx = tags.firstIndex(where: { $0 == selection.wrappedValue }) { return idx }
               return 0
           },
           set: { newIndex in
               let idx = max(0, min(newIndex, tags.count - 1))
               selection.wrappedValue = tags[idx]
           }
       )
       self.selection = indexBinding
       self.options = titles
       self.label = VStack(content: Text(title))
   }

   /// Picker without a label and tag-based selection mapping.
   public init<T: Equatable>(selection: Binding<T>, options: [(String, T)]) where Label == EmptyView {
       let titles = options.map { $0.0 }
       let tags = options.map { $0.1 }
       let indexBinding = Binding<Int>(
           get: {
               if let idx = tags.firstIndex(where: { $0 == selection.wrappedValue }) { return idx }
               return 0
           },
           set: { newIndex in
               let idx = max(0, min(newIndex, tags.count - 1))
               selection.wrappedValue = tags[idx]
           }
       )
       self.selection = indexBinding
       self.options = titles
       self.label = nil
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       if let label {
           node.addNode(at: 0, Node(view: label.view))
       }
       let control = PickerControl(selection: selection, options: options)
       if let labelNode = node.children.first {
           control.label = labelNode.control(at: 0)
           control.addSubview(control.label!, at: 0)
       }
       node.control = control
   }

   func updateNode(_ node: Node) {
       node.view = self
       if let label {
           if node.children.isEmpty {
               node.addNode(at: 0, Node(view: label.view))
               (node.control as? PickerControl)?.label = node.children[0].control(at: 0)
               if let labelCtrl = (node.control as? PickerControl)?.label {
                   node.control?.addSubview(labelCtrl, at: 0)
               }
           } else {
               node.children[0].update(using: label.view)
           }
       } else if !node.children.isEmpty {
           node.removeNode(at: 0)
           (node.control as? PickerControl)?.label = nil
       }
       if let control = node.control as? PickerControl {
           control.selection = selection
           control.options = options
           control.layer.invalidate()
       }
   }

   private class PickerControl: Control {
       var options: [String]
       var selection: Binding<Int>
       var label: Control? = nil
       private var highlighted = false

       init(selection: Binding<Int>, options: [String]) {
           self.selection = selection
           self.options = options
       }

       // MARK: - Layout
       override func size(proposedSize: Size) -> Size {
           let lblSize = label?.size(proposedSize: proposedSize) ?? .zero
           let maxLen = options.map { $0.count }.max() ?? 0
           let fieldWidth: Extended = Extended(maxLen + 4) // "< " + text + " >"
           var width = fieldWidth
           if lblSize.width > 0 { width += lblSize.width + 1 } // + space
           return Size(width: width, height: max(1, lblSize.height))
       }

       override func layout(size: Size) {
           super.layout(size: size)
           if let label {
               let lblSize = label.size(proposedSize: size)
               label.layout(size: lblSize)
               label.layer.frame.position = Position(column: 0, line: 0)
           }
       }

       // MARK: - Selection
       override var selectable: Bool { true }

       override func becomeFirstResponder() {
           super.becomeFirstResponder()
           highlighted = true
           layer.invalidate()
       }

       override func resignFirstResponder() {
           super.resignFirstResponder()
           highlighted = false
           layer.invalidate()
       }

       // MARK: - Events
       override func handleEvent(_ char: Character) {
           guard !options.isEmpty else { return }
           if char == "h" || char == "\u{1b}" { /* esc prefix for arrows ignored here */ }
           switch char {
           case "h": decrement()
           case "l": increment()
           default:
               break
           }
       }

       // Arrow keys are parsed at Application level into focus moves; we also support them via characters 'h'/'l'.
       // If future ArrowKey events are routed to controls, we can extend here.

       private func increment() {
           guard !options.isEmpty else { return }
           let count = options.count
           let idx = (selection.wrappedValue + 1) % count
           selection.wrappedValue = idx
           layer.invalidate()
       }

       private func decrement() {
           guard !options.isEmpty else { return }
           let count = options.count
           let idx = (selection.wrappedValue - 1 + count) % count
           selection.wrappedValue = idx
           layer.invalidate()
       }

       // MARK: - Drawing
       override func cell(at position: Position) -> Cell? {
           guard position.line == 0 else { return nil }

           let lblWidth = label?.layer.frame.size.width ?? 0
           let hasLabel = (label != nil && lblWidth > 0)
           let startCol: Extended = hasLabel ? (lblWidth + 1) : 0 // space after label

           // Only draw in the field area
           guard position.column >= startCol else { return nil }

           let text = currentText
           let width = Extended(text.count + 4) // < + space + text + space + >
           let i = position.column - startCol
           guard i >= 0 && i < width else { return nil }

           var ch: Character = " "
           if i == 0 { ch = "<" }
           else if i == width - 1 { ch = ">" }
           else if i == 1 { ch = " " }
           else if i == width - 2 { ch = " " }
           else {
               let ti = i - 2
               let idx = text.index(text.startIndex, offsetBy: ti.intValue)
               ch = text[idx]
           }

           var cell = Cell(char: ch)
           if highlighted { cell.attributes.inverted = true }
           return cell
       }

       private var currentText: String {
           guard !options.isEmpty else { return "" }
           let idx = min(max(selection.wrappedValue, 0), options.count - 1)
           return options[idx]
       }
   }
}
