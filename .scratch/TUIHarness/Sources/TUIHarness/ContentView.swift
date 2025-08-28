import SwiftTUI

struct ContentView: View {
   @State var count: Int = 1
   @State var toggleOn: Bool = false
   @State var sliderValue: Double = 5
   @State var items: [String] = ["Item 1"]

   var body: some View {
       VStack(alignment: .leading, spacing: 1) {
           Text("SwiftTUI QA Harness").bold()

           HStack(spacing: 1) {
               Button("Add") {
                   count += 1
                   items.append("Item \(count)")
               }
               if count > 1 {
                   Button("Remove") {
                       if count > 0 { count -= 1 }
                       if !items.isEmpty { _ = items.popLast() }
                   }
               }
               Toggle("Toggle", isOn: Binding(get: { toggleOn }, set: { toggleOn = $0 }))
           }

           HStack(spacing: 1) {
               Text("Slider:")
               Slider(value: Binding(get: { sliderValue }, set: { sliderValue = $0 }), in: 0...10, step: 1)
           }

           VStack(spacing: 0) {
               ForEach(items, id: \.self) { it in
                   Text(it)
               }
           }
           .border()

           HStack(spacing: 1) {
               Text("Add item:").italic()
               TextField(placeholder: "Type and Enter") { text in
                   items.append(text)
               }
           }

           HStack(spacing: 1) {
               Text("Password:")
               SecureField(placeholder: "Password") { _ in }
           }

           Text("Quit: Ctrl-C or Ctrl-D").italic()
       }
       .padding()
       .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
   }
}
