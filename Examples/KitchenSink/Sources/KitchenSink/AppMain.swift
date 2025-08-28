import SwiftTUI

@main
struct AppMain {
 @MainActor static func main() {
   Application(rootView: KitchenSinkView()).start()
 }
}
