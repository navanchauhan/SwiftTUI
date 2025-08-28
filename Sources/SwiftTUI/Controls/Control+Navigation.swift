import Foundation

// Navigation-related conveniences for controls.
extension Control {
   /// Whether this control is an active text-input field.
   /// Used by the Application to avoid treating Backspace as a navigation action.
   /// Defaults to false; text inputs (e.g., TextField/SecureField) override to true.
   @objc var isTextInput: Bool { false }

   /// Ask this control to perform a navigation pop if applicable.
   /// Defaults to false; Navigation containers override to perform a pop and return true.
   @discardableResult
   @objc func navigationPop() -> Bool { false }
}
