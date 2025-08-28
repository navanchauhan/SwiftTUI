import Foundation

// Focus-based hover semantics for terminal UIs.
//
// SwiftUI's onHover is pointer-based. In a terminal we approximate hover by
// using focus changes: when a view (or any of its descendants) gains focus,
// we report `true`; when focus leaves the subtree, we report `false`.
//
// This is implemented as a thin alias to `.onFocusChange` so it composes with
// the existing focus system and works uniformly across macOS and Linux.
public extension View {
 /// Registers a closure to be called when focus enters or leaves this view's subtree.
 ///
 /// Note: In SwiftTUI this is a focus-based approximation of hover, not a
 /// pointer/mouse hover. The closure receives `true` when focus enters and
 /// `false` when focus exits.
 func onHover(perform action: @escaping (Bool) -> Void) -> some View {
     onFocusChange(action)
 }
}
