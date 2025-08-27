import Foundation

// Hit testing helpers for mouse support
extension Control {
   /// Returns the deepest selectable control that contains the given screen position.
   func hitTest(screenPosition: Position) -> Control? {
       // Convert to our local coordinate by subtracting ancestors' positions
       let localPos = screenPosition - absolutePosition()
       return hitTestLocal(position: localPos)
   }

   /// Recursively resolve a selectable control containing the given local position.
   fileprivate func hitTestLocal(position: Position) -> Control? {
       // Traverse children in reverse order (topmost first)
       for child in children.reversed() {
           if child.layer.frame.contains(position) {
               let childLocal = position - child.layer.frame.position
               if let found = child.hitTestLocal(position: childLocal) { return found }
           }
       }
       // If this control is selectable and the point lies within our bounds, return self
       if selectable, layer.frame.contains(position) { return self }
       return nil
   }

   /// Compute the absolute (screen) position of this control's origin (top-left)
   fileprivate func absolutePosition() -> Position {
       var pos: Position = .zero
       var current: Control? = self
       while let c = current {
           pos = pos + c.layer.frame.position
           current = c.parent
       }
       return pos
   }
}
