import Foundation

public struct Rectangle: View, PrimitiveView {
   enum Mode {
       case fill(Color)
       case stroke(Color)
   }

   private var mode: Mode? = nil

   public init() {}

   public func fill(_ color: Color) -> Rectangle {
       var copy = self
       copy.mode = .fill(color)
       return copy
   }

   public func stroke(_ color: Color) -> Rectangle {
       var copy = self
       copy.mode = .stroke(color)
       return copy
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       node.control = RectangleControl(mode: mode)
   }

   func updateNode(_ node: Node) {
       node.view = self
       if let c = node.control as? RectangleControl {
           c.mode = mode
           c.layer.invalidate()
       }
   }

   class RectangleControl: Control {
       var mode: Mode?

       init(mode: Mode?) { self.mode = mode }

       override func size(proposedSize: Size) -> Size {
           // Shapes take the proposed size
           proposedSize
       }

       override func layout(size: Size) {
           super.layout(size: size)
           layer.frame.size = size
       }

       override func cell(at position: Position) -> Cell? {
           guard position.column >= 0, position.line >= 0,
                 position.column < layer.frame.size.width,
                 position.line < layer.frame.size.height else { return nil }

           switch mode {
           case .fill(let color):
               return Cell(char: " ", backgroundColor: color)
           case .stroke(let color):
               let w = layer.frame.size.width
               let h = layer.frame.size.height
               var ch: Character? = nil
               if position.line == 0 {
                   if position.column == 0 { ch = BorderStyle.default.topLeft }
                   else if position.column == w - 1 { ch = BorderStyle.default.topRight }
                   else { ch = BorderStyle.default.top }
               } else if position.line == h - 1 {
                   if position.column == 0 { ch = BorderStyle.default.bottomLeft }
                   else if position.column == w - 1 { ch = BorderStyle.default.bottomRight }
                   else { ch = BorderStyle.default.bottom }
               } else if position.column == 0 {
                   ch = BorderStyle.default.left
               } else if position.column == w - 1 {
                   ch = BorderStyle.default.right
               }
               return ch.map { Cell(char: $0, foregroundColor: color) }
           case .none:
               // Default to fill with transparent (no-op)
               return nil
           }
       }
   }
}

public struct RoundedRectangle: View, PrimitiveView {
   enum Mode {
       case fill(Color)
       case stroke(Color)
   }

   public let cornerRadius: Int
   private var mode: Mode? = nil

   public init(cornerRadius: Int) { self.cornerRadius = max(0, cornerRadius) }

   public func fill(_ color: Color) -> RoundedRectangle {
       var copy = self
       copy.mode = .fill(color)
       return copy
   }

   public func stroke(_ color: Color) -> RoundedRectangle {
       var copy = self
       copy.mode = .stroke(color)
       return copy
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       node.control = RoundedRectangleControl(cornerRadius: cornerRadius, mode: mode)
   }

   func updateNode(_ node: Node) {
       node.view = self
       if let c = node.control as? RoundedRectangleControl {
           c.cornerRadius = cornerRadius
           c.mode = mode
           c.layer.invalidate()
       }
   }

   class RoundedRectangleControl: Control {
       var cornerRadius: Int
       var mode: Mode?

       init(cornerRadius: Int, mode: Mode?) {
           self.cornerRadius = max(0, cornerRadius)
           self.mode = mode
       }

       override func size(proposedSize: Size) -> Size { proposedSize }
       override func layout(size: Size) { super.layout(size: size); layer.frame.size = size }

       override func cell(at position: Position) -> Cell? {
           guard position.column >= 0, position.line >= 0,
                 position.column < layer.frame.size.width,
                 position.line < layer.frame.size.height else { return nil }

           switch mode {
           case .fill(let color):
               // Clip out rounded corners by returning nil there
               if !_contains(position, size: layer.frame.size) { return nil }
               return Cell(char: " ", backgroundColor: color)
           case .stroke(let color):
               let w = layer.frame.size.width
               let h = layer.frame.size.height
               var ch: Character? = nil
               // Use rounded style characters
               let style = BorderStyle.rounded
               if position.line == 0 {
                   if position.column == 0 { ch = style.topLeft }
                   else if position.column == w - 1 { ch = style.topRight }
                   else { ch = style.top }
               } else if position.line == h - 1 {
                   if position.column == 0 { ch = style.bottomLeft }
                   else if position.column == w - 1 { ch = style.bottomRight }
                   else { ch = style.bottom }
               } else if position.column == 0 {
                   ch = style.left
               } else if position.column == w - 1 {
                   ch = style.right
               }
               return ch.map { Cell(char: $0, foregroundColor: color) }
           case .none:
               return nil
           }
       }

       func _contains(_ pos: Position, size: Size) -> Bool {
           let r = max(0, cornerRadius)
           if r == 0 { return true }
           let w = size.width.intValue
           let h = size.height.intValue
           let x = pos.column.intValue
           let y = pos.line.intValue
           let rr = max(0, r - 1)
           // Too small for rounding => always inside
           if w <= r * 2 || h <= r * 2 { return true }

           // Top-left corner region
           if x < r && y < r {
               let dx = rr - x
               let dy = rr - y
               return dx * dx + dy * dy <= rr * rr
           }
           // Top-right
           if x >= w - r && y < r {
               let cx = (w - 1 - rr)
               let dx = x - cx
               let dy = rr - y
               return dx * dx + dy * dy <= rr * rr
           }
           // Bottom-left
           if x < r && y >= h - r {
               let cy = (h - 1 - rr)
               let dx = rr - x
               let dy = y - cy
               return dx * dx + dy * dy <= rr * rr
           }
           // Bottom-right
           if x >= w - r && y >= h - r {
               let cx = (w - 1 - rr)
               let cy = (h - 1 - rr)
               let dx = x - cx
               let dy = y - cy
               return dx * dx + dy * dy <= rr * rr
           }
           return true
       }
   }
}