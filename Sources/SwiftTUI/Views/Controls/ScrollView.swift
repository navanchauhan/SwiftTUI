import Foundation

/// Automatically scrolls to the currently active control. The content needs to contain controls
/// such as buttons to scroll to.
public struct ScrollView<Content: View>: View, PrimitiveView {
    let axis: Axis
    let content: Content

    public init(_ axis: Axis = .vertical, @ViewBuilder _ content: () -> Content) {
        self.axis = axis
        self.content = content()
    }

    static var size: Int? { 1 }

    func buildNode(_ node: Node) {
        let inner: GenericView = (axis == .vertical)
            ? VStack { content }.view
            : HStack { content }.view
        node.addNode(at: 0, Node(view: inner))
        let control = ScrollControl(axis: axis)
        control.contentControl = node.children[0].control(at: 0)
        control.addSubview(control.contentControl, at: 0)
        node.control = control
    }

    func updateNode(_ node: Node) {
        node.view = self
        let inner: GenericView = (axis == .vertical)
            ? VStack { content }.view
            : HStack { content }.view
        node.children[0].update(using: inner)
        if let sc = node.control as? ScrollControl { sc.axis = axis }
    }

    private class ScrollControl: Control {
        var contentControl: Control!
        var contentOffset: Extended = 0
        var axis: Axis

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
}
