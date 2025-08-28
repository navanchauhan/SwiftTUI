import Foundation

public extension View {
  /// Places a view on top of this view.
  ///
  /// The overlay view is laid out relative to the content's size and drawn above it.
  func overlay<OL: View>(alignment: Alignment = .center, @ViewBuilder _ overlay: () -> OL) -> some View {
      OverlayView(content: self, overlay: overlay(), alignment: alignment)
  }
}

private struct OverlayView<Content: View, OL: View>: View, PrimitiveView {
  let content: Content
  let overlay: OL
  var alignment: Alignment

  static var size: Int? { 1 }

  func buildNode(_ node: Node) {
      // Content first, overlay second to ensure overlay draws on top
      node.addNode(at: 0, Node(view: content.view))
      node.addNode(at: 1, Node(view: overlay.view))
      let control = OverlayContainerControl(alignment: alignment)
      control.content = node.children[0].control(at: 0)
      control.overlay = node.children[1].control(at: 0)
      control.addSubview(control.content, at: 0)
      control.addSubview(control.overlay, at: 1)
      node.control = control
  }

  func updateNode(_ node: Node) {
      node.view = self
      node.children[0].update(using: content.view)
      node.children[1].update(using: overlay.view)
      (node.control as? OverlayContainerControl)?.alignment = alignment
  }

  private class OverlayContainerControl: Control {
      var content: Control!
      var overlay: Control!
      var alignment: Alignment

      init(alignment: Alignment) { self.alignment = alignment }

      override func size(proposedSize: Size) -> Size {
          // Container adopts the size of the content
          return content.size(proposedSize: proposedSize)
      }

      override func layout(size: Size) {
          super.layout(size: size)
          // Layout content
          let contentSize = content.size(proposedSize: size)
          content.layout(size: contentSize)
          content.layer.frame.position = .zero

          // Layout overlay using content's size as proposal
          let overlaySize = overlay.size(proposedSize: content.layer.frame.size)
          overlay.layout(size: overlaySize)

          // Position overlay according to alignment within content frame
          let cw = content.layer.frame.size.width
          let ch = content.layer.frame.size.height
          let ow = overlay.layer.frame.size.width
          let oh = overlay.layer.frame.size.height

          var pos = Position.zero
          switch alignment.horizontalAlignment {
          case .leading: pos.column = 0
          case .center: pos.column = (cw - ow) / 2
          case .trailing: pos.column = cw - ow
          }
          switch alignment.verticalAlignment {
          case .top: pos.line = 0
          case .center: pos.line = (ch - oh) / 2
          case .bottom: pos.line = ch - oh
          }
          overlay.layer.frame.position = pos
      }
  }
}
