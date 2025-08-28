import Foundation

public struct Toggle<Label: View>: View, PrimitiveView {
   let label: VStack<Label>
   let isOn: Binding<Bool>

   public init(isOn: Binding<Bool>, @ViewBuilder label: () -> Label) {
       self.isOn = isOn
       self.label = VStack(content: label())
   }

   public init(_ title: String, isOn: Binding<Bool>) where Label == Text {
       self.isOn = isOn
       self.label = VStack(content: Text(title))
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       node.addNode(at: 0, Node(view: label.view))
       let control = ToggleControl(isOn: isOn)
       control.label = node.children[0].control(at: 0)
       control.addSubview(control.label, at: 0)
       node.control = control
   }

   func updateNode(_ node: Node) {
       node.view = self
       node.children[0].update(using: label.view)
       (node.control as? ToggleControl)?.isOn = isOn
   }

   private class ToggleControl: Control {
       var label: Control!
       var isOn: Binding<Bool>
       weak var toggleLayer: ToggleLayer?

       init(isOn: Binding<Bool>) {
           self.isOn = isOn
       }

       override func size(proposedSize: Size) -> Size {
           // 4 chars for "[ ] " + label size
           let labelSize = label.size(proposedSize: proposedSize)
           return Size(width: labelSize.width + 4, height: max(1, labelSize.height))
       }

       override func layout(size: Size) {
           super.layout(size: size)
           // Lay out the label after the checkbox
           var labelSize = size
           if labelSize.width > 4 { labelSize.width -= 4 } else { labelSize.width = 0 }
           label.layout(size: labelSize)
           label.layer.frame.position = Position(column: 4, line: 0)
       }

       override func handleEvent(_ char: Character) {
           if char == "\n" || char == " " {
               isOn.wrappedValue.toggle()
               layer.invalidate()
           }
       }

       override var selectable: Bool { true }

       override func becomeFirstResponder() {
           super.becomeFirstResponder()
           toggleLayer?.highlighted = true
           layer.invalidate()
       }

       override func resignFirstResponder() {
           super.resignFirstResponder()
           toggleLayer?.highlighted = false
           layer.invalidate()
       }

       override func cell(at position: Position) -> Cell? {
           guard position.line == 0 else { return nil }
           switch position.column.intValue {
           case 0: return Cell(char: "[")
           case 1: return Cell(char: isOn.wrappedValue ? "x" : " ")
           case 2: return Cell(char: "]")
           case 3: return Cell(char: " ")
           default: return nil
           }
       }

       override func makeLayer() -> Layer {
           let layer = ToggleLayer()
           self.toggleLayer = layer
           return layer
       }
   }

   private class ToggleLayer: Layer {
       var highlighted = false
       override func cell(at position: Position) -> Cell? {
           var cell = super.cell(at: position)
           if highlighted { cell?.attributes.inverted.toggle() }
           return cell
       }
   }
}
