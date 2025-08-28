import Foundation

public struct Circle: View, PrimitiveView {
  enum Mode { case fill(Color), stroke(Color) }
  private var mode: Mode? = nil

  public init() {}

  public func fill(_ color: Color) -> Circle {
      var copy = self; copy.mode = .fill(color); return copy
  }
  public func stroke(_ color: Color) -> Circle {
      var copy = self; copy.mode = .stroke(color); return copy
  }

  static var size: Int? { 1 }

  func buildNode(_ node: Node) { node.control = CircleControl(mode: mode) }
  func updateNode(_ node: Node) { node.view = self; (node.control as? CircleControl)?.mode = mode; node.control?.layer.invalidate() }

  class CircleControl: Control {
      var mode: Mode?
      init(mode: Mode?) { self.mode = mode }

      override func size(proposedSize: Size) -> Size { proposedSize }
      override func layout(size: Size) { super.layout(size: size); layer.frame.size = size }

      override func cell(at position: Position) -> Cell? {
          guard position.column >= 0, position.line >= 0,
                position.column < layer.frame.size.width,
                position.line < layer.frame.size.height else { return nil }
          func contains(_ pos: Position) -> Bool { CircleControl.containsCircle(pos, size: layer.frame.size) }
          switch mode {
          case .fill(let c):
              return contains(position) ? Cell(char: " ", backgroundColor: c) : nil
          case .stroke(let c):
              // Simple boundary: inside but at least one 4-neighbor outside
              if contains(position) {
                  let p = position
                  let neigh = [Position(column: p.column-1, line: p.line), Position(column: p.column+1, line: p.line), Position(column: p.column, line: p.line-1), Position(column: p.column, line: p.line+1)]
                  if neigh.contains(where: { !contains($0) }) {
                      return Cell(char: "•", foregroundColor: c)
                  }
              }
              return nil
          case .none:
              return nil
          }
      }

      static func containsCircle(_ pos: Position, size: Size) -> Bool {
          let w = Double(size.width.intValue)
          let h = Double(size.height.intValue)
          if w <= 0 || h <= 0 { return false }
          let cx = Double(pos.column.intValue) + 0.5
          let cy = Double(pos.line.intValue) + 0.5
          let centerX = w / 2.0
          let centerY = h / 2.0
          let r = min(w, h) / 2.0
          let dx = cx - centerX
          let dy = cy - centerY
          return (dx*dx + dy*dy) <= r*r
      }
  }
}

public struct Capsule: View, PrimitiveView {
  enum Mode { case fill(Color), stroke(Color) }
  private var mode: Mode? = nil

  public init() {}

  public func fill(_ color: Color) -> Capsule { var c = self; c.mode = .fill(color); return c }
  public func stroke(_ color: Color) -> Capsule { var c = self; c.mode = .stroke(color); return c }

  static var size: Int? { 1 }

  func buildNode(_ node: Node) { node.control = CapsuleControl(mode: mode) }
  func updateNode(_ node: Node) { node.view = self; (node.control as? CapsuleControl)?.mode = mode; node.control?.layer.invalidate() }

  class CapsuleControl: Control {
      var mode: Mode?
      init(mode: Mode?) { self.mode = mode }
      override func size(proposedSize: Size) -> Size { proposedSize }
      override func layout(size: Size) { super.layout(size: size); layer.frame.size = size }

      override func cell(at position: Position) -> Cell? {
          guard position.column >= 0, position.line >= 0,
                position.column < layer.frame.size.width,
                position.line < layer.frame.size.height else { return nil }
          func contains(_ pos: Position) -> Bool { CapsuleControl.containsCapsule(pos, size: layer.frame.size) }
          switch mode {
          case .fill(let c):
              return contains(position) ? Cell(char: " ", backgroundColor: c) : nil
          case .stroke(let c):
              if contains(position) {
                  let p = position
                  let neigh = [Position(column: p.column-1, line: p.line), Position(column: p.column+1, line: p.line), Position(column: p.column, line: p.line-1), Position(column: p.column, line: p.line+1)]
                  if neigh.contains(where: { !contains($0) }) {
                      return Cell(char: "•", foregroundColor: c)
                  }
              }
              return nil
          case .none:
              return nil
          }
      }

      static func containsCapsule(_ pos: Position, size: Size) -> Bool {
          let w = Double(size.width.intValue)
          let h = Double(size.height.intValue)
          if w <= 0 || h <= 0 { return false }
          let cx = Double(pos.column.intValue) + 0.5
          let cy = Double(pos.line.intValue) + 0.5
          let centerY = h / 2.0
          if w >= h {
              // Horizontal capsule
              let r = h / 2.0
              let leftCenterX = r
              let rightCenterX = w - r
              if cx >= leftCenterX && cx <= rightCenterX {
                  return abs(cy - centerY) <= r
              }
              let dlx = cx - leftCenterX
              let drx = cx - rightCenterX
              let dy = cy - centerY
              return (dlx*dlx + dy*dy) <= r*r || (drx*drx + dy*dy) <= r*r
          } else {
              // Vertical capsule
              let r = w / 2.0
              let centerX = w / 2.0
              let topCenterY = r
              let bottomCenterY = h - r
              if cy >= topCenterY && cy <= bottomCenterY {
                  return abs(cx - centerX) <= r
              }
              let dty = cy - topCenterY
              let dby = cy - bottomCenterY
              let dx = cx - centerX
              return (dx*dx + dty*dty) <= r*r || (dx*dx + dby*dby) <= r*r
          }
      }
  }
}
