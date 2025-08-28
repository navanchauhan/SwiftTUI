import Foundation

public struct ProgressView: View, PrimitiveView {
   let value: Binding<Double>
   let total: Double

   /// A progress bar with a binding value from 0...total.
   public init(value: Binding<Double>, total: Double) {
       self.value = value
       self.total = total
   }

   /// Convenience init for a constant value
   public init(value: Double, total: Double) {
       self.value = Binding(get: { value }, set: { _ in })
       self.total = total
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       node.control = ProgressControl(value: value, total: total)
   }

   func updateNode(_ node: Node) {
       node.view = self
       if let control = node.control as? ProgressControl {
           control.value = value
           control.total = total
           control.layer.invalidate()
       }
   }

   private class ProgressControl: Control {
       var value: Binding<Double>
       var total: Double

       init(value: Binding<Double>, total: Double) {
           self.value = value
           self.total = total
       }

       override func size(proposedSize: Size) -> Size {
           // Take proposed width, default to 10 if unknown
           let width = (proposedSize.width == .infinity || proposedSize.width == Extended(0)) ? Extended(10) : proposedSize.width
           return Size(width: max(1, width), height: 1)
       }

       override func cell(at position: Position) -> Cell? {
           guard position.line == 0 else { return nil }
           let width = max(0, layer.frame.size.width.intValue)
           guard width > 0 else { return nil }

           let v = max(0.0, min(value.wrappedValue, total))
           let ratio = total > 0 ? v / total : 0
           let filled = Int(Double(width) * ratio)
           let ch: Character = position.column.intValue < filled ? "█" : "░"
           return Cell(char: ch)
       }
   }
}
