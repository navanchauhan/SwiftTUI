import Foundation

/// Basic styles for list separators, mirroring common border line sets.
public enum ListSeparatorStyle: Sendable, Equatable {
 /// No separators are drawn.
 case none
 /// Thin line (─)
 case plain
 /// Heavy line (━)
 case heavy
 /// Double line (═)
 case double
}

// A lightweight overlay that draws horizontal separator lines between vertically stacked rows.
// Intended for use with List views: `List { ... }.listSeparators()`.
//
// This modifier does not reserve vertical space; to avoid overlapping content, set `rowSpacing` on
// your List to at least 1.
public extension View {
 /// Draw simple horizontal separators between vertically stacked rows.
 /// For best results, use with `List(rowSpacing: 1, ...)` so the separators occupy the blank line.
 func listSeparators() -> some View { ListSeparatorsOverlay(content: self, style: .plain, color: nil) }

 /// Draw horizontal separators with a chosen style and optional color override.
 /// - Parameters:
 ///   - style: Separator style (plain is default).
 ///   - color: Optional foreground color to use for separator glyphs.
 func listSeparators(style: ListSeparatorStyle, color: Color? = nil) -> some View {
   ListSeparatorsOverlay(content: self, style: style, color: color)
 }
}

// MARK: - Implementation
private struct ListSeparatorsOverlay<Content: View>: View, PrimitiveView, ModifierView {
 let content: Content
 var style: ListSeparatorStyle
 var color: Color?

 static var size: Int? { Content.size }

 func buildNode(_ node: Node) {
     node.controls = WeakSet<Control>()
     node.addNode(at: 0, Node(view: content.view))
 }

 func updateNode(_ node: Node) {
     node.view = self
     node.children[0].update(using: content.view)
     for c in node.controls?.values ?? [] {
         if let lc = c as? _ListSeparatorsControl {
             lc.style = style
             lc.color = color
             lc.layer.invalidate()
         }
     }
 }

 func passControl(_ control: Control, node: Node) -> Control {
     if let existing = control.parent as? _ListSeparatorsControl { return existing }
     let wrapper = _ListSeparatorsControl()
     wrapper.style = style
     wrapper.color = color
     // Content as first child
     wrapper.addSubview(control, at: 0)
     // Overlay as second child drawn on top
     let overlay = _SeparatorsOverlay(root: control)
     wrapper.addSubview(overlay, at: 1)
     node.controls?.add(wrapper)
     return wrapper
 }

 // Wrapper control that sizes and lays out content + overlay
 private class _ListSeparatorsControl: Control {
     var style: ListSeparatorStyle = .plain
     var color: Color? = nil

     override func size(proposedSize: Size) -> Size { children[0].size(proposedSize: proposedSize) }

     override func layout(size: Size) {
         super.layout(size: size)
         children[0].layout(size: size)
         children[0].layer.frame.position = .zero
         if children.count > 1 {
             children[1].layout(size: size)
             children[1].layer.frame.position = .zero
         }
         layer.frame.size = size
     }
 }

 // Draws separators by inspecting the first descendant stack under the passed root.
 private class _SeparatorsOverlay: Control {
     weak var contentRoot: Control?
     init(root: Control) { self.contentRoot = root }

     override func size(proposedSize: Size) -> Size { proposedSize }
     override func layout(size: Size) { super.layout(size: size); layer.frame.size = size }

     override func cell(at position: Position) -> Cell? {
         guard let (stack, offset) = findVerticalStack(startingAt: contentRoot) else { return nil }
         // A separator on the first spacing line after each row
         let rows = stack.children
         guard rows.count >= 2 else { return nil }
         for i in 0 ..< (rows.count - 1) {
             let row = rows[i]
             let sepLine = offset + row.layer.frame.position.line + row.layer.frame.size.height
             if position.line == sepLine {
                 if let wrapper = parent as? _ListSeparatorsControl {
                     switch wrapper.style {
                     case .none:
                        return Cell(char: " ", foregroundColor: wrapper.color ?? .default)
                     case .plain:
                         return Cell(char: "─", foregroundColor: wrapper.color ?? .default)
                     case .heavy:
                         return Cell(char: "━", foregroundColor: wrapper.color ?? .default)
                     case .double:
                         return Cell(char: "═", foregroundColor: wrapper.color ?? .default)
                     }
                 }
                 return Cell(char: "─")
             }
         }
         return nil
     }

     // Find the vertical stack under the given root control.
     private func findVerticalStack(startingAt control: Control?) -> (stack: Control, offset: Extended)? {
         guard let control else { return nil }
         // Heuristic: expect the first child to be the content stack inside a ScrollView.
         // Accumulate the stack's offset within our overlay coordinate space.
         var current: Control? = control
         var accumulatedOffset: Extended = 0

         // Descend one level if present
         if let first = current?.children.first {
             accumulatedOffset += first.layer.frame.position.line
             current = first
         }
         // If there's another level, include its offset as well (ScrollView -> Stack)
         if let first = current?.children.first {
             accumulatedOffset += first.layer.frame.position.line
             current = first
         }
         if let stack = current, !stack.children.isEmpty {
             return (stack, accumulatedOffset)
         }
         return nil
     }
 }
}
