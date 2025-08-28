import SwiftTUI

@main
struct AppMain {
   @MainActor static func main() {
       let app = Application(rootView: ContentView())
       app.globalKeyHandler = { _ in }
       app.start()
   }
}
