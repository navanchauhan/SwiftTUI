import Foundation

public extension Application {
   func focusFirst() {
       if let current = window.firstResponder, let first = control.firstSelectableElement, current !== first {
           current.resignFirstResponder()
           window.firstResponder = first
           first.becomeFirstResponder()
       }
   }

   func focusLast() {
       if let current = window.firstResponder, let last = control.lastSelectableElement, current !== last {
           current.resignFirstResponder()
           window.firstResponder = last
           last.becomeFirstResponder()
       }
   }
}
