import Foundation

public struct Spacer: View, PrimitiveView {
    @Environment(\.stackOrientation) var stackOrientation
    
    private let minLength: Int
    
    public init() { self.minLength = 0 }
    public init(minLength: Int) { self.minLength = max(0, minLength) }
    
    static var size: Int? { 1 }
    
    func buildNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.control = SpacerControl(orientation: stackOrientation, minLength: minLength)
    }
    
    func updateNode(_ node: Node) {
        setupEnvironmentProperties(node: node)
        node.view = self
        let control = node.control as! SpacerControl
        control.orientation = stackOrientation
        control.minLength = minLength
    }
    
    private class SpacerControl: Control {
        var orientation: StackOrientation
        var minLength: Int
        
        init(orientation: StackOrientation, minLength: Int) {
            self.orientation = orientation
            self.minLength = max(0, minLength)
        }
        
        override func size(proposedSize: Size) -> Size {
            switch orientation {
            case .horizontal:
                let w = max(Extended(minLength), proposedSize.width)
                return Size(width: w, height: 0)
            case .vertical:
                let h = max(Extended(minLength), proposedSize.height)
                return Size(width: 0, height: h)
            }
        }
    }
}
