import Foundation

public struct Slider: View, PrimitiveView {
   let range: ClosedRange<Double>
   let step: Double
   let value: Binding<Double>
   @Environment(\.isEnabled) private var isEnabled: Bool

   public init(value: Binding<Double>, in range: ClosedRange<Double>, step: Double = 1.0) {
       self.value = value
       self.range = range
       self.step = step
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       let c = SliderControl(value: value, range: range, step: step)
       c.isEnabled = isEnabled
       node.control = c
   }

   func updateNode(_ node: Node) {
       node.view = self
       if let control = node.control as? SliderControl {
           control.value = value
           control.range = range
           control.step = step
           control.isEnabled = isEnabled
           control.layer.invalidate()
       }
   }

   private class SliderControl: Control {
       var value: Binding<Double>
       var range: ClosedRange<Double>
       var step: Double
       private var highlighted = false
       var isEnabled: Bool = true

       init(value: Binding<Double>, range: ClosedRange<Double>, step: Double) {
           self.value = value
           self.range = range
           self.step = step
       }

       override func size(proposedSize: Size) -> Size {
           // Default to width 12: [########] (10 interior + brackets)
           let width = (proposedSize.width == .infinity || proposedSize.width == Extended(0)) ? Extended(12) : max(Extended(3), proposedSize.width)
           return Size(width: width, height: 1)
       }

       override func handleEvent(_ char: Character) {
           guard isEnabled else { return }
           if char == "h" || char == "-" { decrement() }
           else if char == "l" || char == "+" { increment() }
       }

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

       override var selectable: Bool { isEnabled }

       override func cell(at position: Position) -> Cell? {
           guard position.line == 0 else { return nil }
           let w = layer.frame.size.width.intValue
           guard w >= 3 else { return nil }

           let interior = max(1, w - 2)
           // Clamp value and compute knob position
           let clamped = min(max(value.wrappedValue, range.lowerBound), range.upperBound)
           let ratio = (range.upperBound - range.lowerBound) > 0 ? (clamped - range.lowerBound) / (range.upperBound - range.lowerBound) : 0
           let knob = min(interior - 1, max(0, Int(Double(interior - 1) * ratio)))

           var cell: Cell?
           if position.column.intValue == 0 { cell = Cell(char: "[") }
           else if position.column.intValue == w - 1 { cell = Cell(char: "]") }
           let i = position.column.intValue - 1
           if i == knob {
               var c = Cell(char: highlighted ? "◉" : "●")
               if highlighted { c.attributes.inverted = true }
               cell = c
           }
           let fill = i < knob ? "─" : " "
           var c2 = Cell(char: Character(fill))
           if highlighted { c2.attributes.inverted = true }
           if cell == nil { cell = c2 }
           if !isEnabled { cell?.attributes.faint = true }
           return cell
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
   }
}