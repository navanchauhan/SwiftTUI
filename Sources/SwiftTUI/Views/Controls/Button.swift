import Foundation

public struct Button<Label: View>: View, PrimitiveView {
    let label: VStack<Label>
    let hover: () -> Void
    let action: () -> Void
    @Environment(\.isEnabled) private var isEnabled: Bool

    public init(action: @escaping () -> Void, hover: @escaping () -> Void = {}, @ViewBuilder label: () -> Label) {
        self.label = VStack(content: label())
        self.action = action
        self.hover = hover
    }

    public init(_ text: String, hover: @escaping () -> Void = {}, action: @escaping () -> Void) where Label == Text {
        self.label = VStack(content: Text(text))
        self.action = action
        self.hover = hover
    }

    static var size: Int? { 1 }

    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.addNode(at: 0, Node(view: label.view))
        let control = ButtonControl(action: action, hover: hover)
        control.isEnabled = isEnabled
        control.label = node.children[0].control(at: 0)
        control.addSubview(control.label, at: 0)
        node.control = control
    }

    func updateNode(_ node: Node) {
        node.view = self
        node.children[0].update(using: label.view)
        if let c = node.control as? ButtonControl {
            c.isEnabled = isEnabled
            c.layer.invalidate()
        }
    }

    private class ButtonControl: Control {
        var action: () -> Void
        var hover: () -> Void
        var label: Control!
        weak var buttonLayer: ButtonLayer?
        var isEnabled: Bool = true

        init(action: @escaping () -> Void, hover: @escaping () -> Void) {
            self.action = action
            self.hover = hover
        }

        override func size(proposedSize: Size) -> Size {
            return label.size(proposedSize: proposedSize)
        }

        override func layout(size: Size) {
            super.layout(size: size)
            self.label.layout(size: size)
        }

        override func handleEvent(_ char: Character) {
            guard isEnabled else { return }
            if char == "\n" || char == "\r" || char == " " {
                action()
            }
        }

        override var selectable: Bool { isEnabled }

        override func becomeFirstResponder() {
            super.becomeFirstResponder()
            if isEnabled {
                buttonLayer?.highlighted = true
                hover()
                layer.invalidate()
            }
        }

        override func resignFirstResponder() {
            super.resignFirstResponder()
            buttonLayer?.highlighted = false
            layer.invalidate()
        }

        override func makeLayer() -> Layer {
            let layer = ButtonLayer(owner: self)
            self.buttonLayer = layer
            return layer
        }
    }

    private class ButtonLayer: Layer {
        weak var owner: Button.ButtonControl?
        init(owner: Button.ButtonControl) { self.owner = owner }
        var highlighted = false

        override func cell(at position: Position) -> Cell? {
            var cell = super.cell(at: position)
            if highlighted { cell?.attributes.inverted.toggle() }
            if let o = owner, !o.isEnabled { cell?.attributes.faint = true }
            return cell
        }
    }
}
