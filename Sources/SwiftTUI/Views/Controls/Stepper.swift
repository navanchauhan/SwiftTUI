import Foundation

/// A simple stepper control for integer values.
///
/// Keyboard: use '+'/'l' to increment and '-'/'h' to decrement. Value is clamped to the given range.
/// Rendering: "[-] <value> [+]" and an optional leading label.
public struct Stepper<Label: View>: View, PrimitiveView {
   let value: Binding<Int>
   let range: ClosedRange<Int>
   let step: Int
   let label: VStack<Label>?
   @Environment(\.isEnabled) private var isEnabled: Bool

   public init(value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1, @ViewBuilder label: () -> Label) {
       self.value = value
       self.range = range
       self.step = max(1, step)
       self.label = VStack(content: label())
   }

   public init(_ title: String, value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1) where Label == Text {
       self.value = value
       self.range = range
       self.step = max(1, step)
       self.label = VStack(content: Text(title))
   }

   public init(value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1) where Label == EmptyView {
       self.value = value
       self.range = range
       self.step = max(1, step)
       self.label = nil
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
      setupEnvironmentProperties(node: node)
       if let label { node.addNode(at: 0, Node(view: label.view)) }
       let control = StepperControl(value: value, range: range, step: step)
       control.isEnabled = isEnabled
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
               (node.control as? StepperControl)?.label = node.children[0].control(at: 0)
               if let labelCtrl = (node.control as? StepperControl)?.label {
                   node.control?.addSubview(labelCtrl, at: 0)
               }
           } else {
               node.children[0].update(using: label.view)
           }
       } else if !node.children.isEmpty {
           node.removeNode(at: 0)
           (node.control as? StepperControl)?.label = nil
       }
       if let control = node.control as? StepperControl {
           control.value = value
           control.range = range
           control.step = step
           control.isEnabled = isEnabled
           control.layer.invalidate()
       }
   }

   private class StepperControl: Control {
       var value: Binding<Int>
       var range: ClosedRange<Int>
       var step: Int
       var label: Control? = nil
       private var highlighted = false
       var isEnabled: Bool = true

       init(value: Binding<Int>, range: ClosedRange<Int>, step: Int) {
           self.value = value
           self.range = range
           self.step = step
       }

       override func size(proposedSize: Size) -> Size {
           let lbl = label?.size(proposedSize: proposedSize) ?? .zero
           let valStr = valueString
           let fieldWidth = Extended(valStr.count + 8) // "[-] " + value + " [+]"
           var width = fieldWidth
           if lbl.width > 0 { width += lbl.width + 1 }
           return Size(width: width, height: max(1, lbl.height))
       }

       override func layout(size: Size) {
           super.layout(size: size)
           if let label {
               let lblSize = label.size(proposedSize: size)
               label.layout(size: lblSize)
               label.layer.frame.position = Position(column: 0, line: 0)
           }
       }

       override var selectable: Bool { isEnabled }

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

       override func handleEvent(_ char: Character) {
           guard isEnabled else { return }
           switch char {
           case "+", "l": increment()
           case "-", "h": decrement()
           default: break
           }
       }

       private func increment() {
           let newVal = min(range.upperBound, value.wrappedValue + step)
           value.wrappedValue = newVal
           layer.invalidate()
       }

       private func decrement() {
           let newVal = max(range.lowerBound, value.wrappedValue - step)
           value.wrappedValue = newVal
           layer.invalidate()
       }

       override func cell(at position: Position) -> Cell? {
           guard position.line == 0 else { return nil }
           let lblW = label?.layer.frame.size.width ?? 0
           let hasLabel = (label != nil && lblW > 0)
           let startCol: Extended = hasLabel ? (lblW + 1) : 0
           guard position.column >= startCol else { return nil }

           let valStr = valueString
           let width = Extended(valStr.count + 8)
           let i = position.column - startCol
           guard i >= 0 && i < width else { return nil }

           var ch: Character = " "
           switch i.intValue {
           case 0: ch = "["
           case 1: ch = "-"
           case 2: ch = "]"
           case 3: ch = " "
           case (4 + valStr.count): ch = " "
           case (5 + valStr.count): ch = "["
           case (6 + valStr.count): ch = "+"
           case (7 + valStr.count): ch = "]"
           default:
               let idx = i - 4
               if idx >= 0 && idx < Extended(valStr.count) {
                   let sidx = valStr.index(valStr.startIndex, offsetBy: idx.intValue)
                   ch = valStr[sidx]
               }
           }

           var cell = Cell(char: ch)
           if highlighted { cell.attributes.inverted = true }
           if !isEnabled { cell.attributes.faint = true }
           return cell
       }

       private var valueString: String { String(value.wrappedValue) }
   }
}
