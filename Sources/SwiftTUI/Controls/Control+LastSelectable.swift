import Foundation

extension Control {
   /// Return the last selectable element in a depth-first right-to-left traversal
   var lastSelectableElement: Control? {
       for control in children.reversed() {
           if let element = control.lastSelectableElement { return element }
       }
       return selectable ? self : nil
   }
}
