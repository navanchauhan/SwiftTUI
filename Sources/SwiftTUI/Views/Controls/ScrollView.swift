import Foundation

/// Automatically scrolls to the currently active control. The content needs to contain controls
/// such as buttons to scroll to.
public struct ScrollView<Content: View>: View, PrimitiveView {
   let axis: Axis
   let content: Content
   @Environment(\.scrollIndicatorVisibility) private var indicatorVisibility: ScrollIndicatorVisibility

   public init(_ axis: Axis = .vertical, @ViewBuilder _ content: () -> Content) {
       self.axis = axis
       self.content = content()
   }

   static var size: Int? { 1 }

   func buildNode(_ node: Node) {
       setupEnvironmentProperties(node: node)
       let inner: GenericView = (axis == .vertical)
           ? VStack { content }.view
           : HStack { content }.view
       node.addNode(at: 0, Node(view: inner))
       let control = ScrollControl(axis: axis)
       control.contentControl = node.children[0].control(at: 0)
       control.addSubview(control.contentControl, at: 0)
       control.indicatorVisibility = indicatorVisibility
       // Overlay for drawing indicators above content
       let overlay = ScrollIndicatorOverlay(owner: control)
       control.addSubview(overlay, at: 1)
       node.control = control
   }

   func updateNode(_ node: Node) {
       node.view = self
       setupEnvironmentProperties(node: node)
       let inner: GenericView = (axis == .vertical)
           ? VStack { content }.view
           : HStack { content }.view
       node.children[0].update(using: inner)
       if let sc = node.control as? ScrollControl {
           sc.axis = axis
           sc.indicatorVisibility = indicatorVisibility
           sc.layer.invalidate()
       }
   }

   private class ScrollControl: Control {
       var contentControl: Control!
       var contentOffset: Extended = 0
       var axis: Axis
       var indicatorVisibility: ScrollIndicatorVisibility = .automatic

       init(axis: Axis) { self.axis = axis }

       override func layout(size: Size) {
           super.layout(size: size)
           let contentSize = contentControl.size(proposedSize: .zero)
           contentControl.layout(size: contentSize)
           if axis == .vertical {
               contentControl.layer.frame.position.line = -contentOffset
               contentControl.layer.frame.position.column = 0
           } else {
               contentControl.layer.frame.position.column = -contentOffset
               contentControl.layer.frame.position.line = 0
           }
           // Layout overlay (and any other children) to match our viewport
           for child in children where child !== contentControl {
               child.layout(size: size)
               child.layer.frame.position = .zero
           }
       }

       override func scroll(to position: Position) {
           if axis == .vertical {
               let destination = position.line - contentControl.layer.frame.position.line
               guard layer.frame.size.height > 0 else { return }
               if contentOffset > destination {
                   contentOffset = destination
               } else if contentOffset < destination - layer.frame.size.height + 1 {
                   contentOffset = destination - layer.frame.size.height + 1
               }
           } else {
               let destination = position.column - contentControl.layer.frame.position.column
               guard layer.frame.size.width > 0 else { return }
               if contentOffset > destination {
                   contentOffset = destination
               } else if contentOffset < destination - layer.frame.size.width + 1 {
                   contentOffset = destination - layer.frame.size.width + 1
               }
           }
       }
   }

   // MARK: - Scroll indicator overlay
   private class ScrollIndicatorOverlay: Control {
       weak var owner: ScrollControl?
       init(owner: ScrollControl) { self.owner = owner }

       override func size(proposedSize: Size) -> Size { proposedSize }
       override func layout(size: Size) { super.layout(size: size); layer.frame.size = size }

       override func cell(at position: Position) -> Cell? {
           guard let sc = owner else { return nil }
           let visibility = sc.indicatorVisibility
           // Determine overflow based on axis
           let viewport = sc.layer.frame.size
           // Use laid-out content size for accurate overflow calculation
           let contentSize = sc.contentControl.layer.frame.size

           switch sc.axis {
           case .vertical:
               let overflow = contentSize.height > viewport.height
               let shouldShow: Bool = {
                   switch visibility {
                   case .hidden: return false
                   case .visible: return true
                   case .automatic: return overflow
                   }
               }()
               guard shouldShow else { return nil }
               guard viewport.height > 0 else { return nil }
               let v = max(1, viewport.height.intValue)
               let c = max(1, contentSize.height.intValue)
               let length = max(1, v * v / c)
               let maxStart = max(0, v - length)
               // Compute normalized offset in [0,1]
               let maxScroll = max(1, c - v)
               let norm = max(0.0, min(1.0, Double(sc.contentOffset.intValue) / Double(maxScroll)))
               let start = Int(round(norm * Double(maxStart)))
               // Draw thumb in the last column
               if position.column == viewport.width - 1 {
                   let line = position.line.intValue
                   if line >= start && line < start + length {
                       return Cell(char: "│")
                   }
               }
               return nil
           case .horizontal:
               let overflow = contentSize.width > viewport.width
               let shouldShow: Bool = {
                   switch visibility {
                   case .hidden: return false
                   case .visible: return true
                   case .automatic: return overflow
                   }
               }()
               guard shouldShow else { return nil }
               guard viewport.width > 0 else { return nil }
               let v = max(1, viewport.width.intValue)
               let c = max(1, contentSize.width.intValue)
               let length = max(1, v * v / c)
               let maxStart = max(0, v - length)
               let maxScroll = max(1, c - v)
               let norm = max(0.0, min(1.0, Double(sc.contentOffset.intValue) / Double(maxScroll)))
               let start = Int(round(norm * Double(maxStart)))
               if position.line == viewport.height - 1 {
                   let col = position.column.intValue
                   if col >= start && col < start + length {
                       return Cell(char: "─")
                   }
               }
               return nil
           }
       }
   }
}