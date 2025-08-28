import Foundation

public extension NavigationLink {
   /// Programmatic navigation initializer using destination and label view builders,
   /// matching SwiftUI's trailing-closure style.
   init(isActive: Binding<Bool>, @ViewBuilder destination: () -> Destination, @ViewBuilder label: () -> Label) {
       self.init(isActive: isActive, destination: destination(), label: label)
   }
}
