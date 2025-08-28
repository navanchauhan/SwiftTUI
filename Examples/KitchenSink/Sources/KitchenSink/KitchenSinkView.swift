import SwiftTUI
import Foundation

struct KitchenSinkView: View {
 @State var selectedTab: Int = 0
 @State var toggleOn: Bool = true
 @State var sliderVal: Double = 5
 @State var stepperVal: Int = 0
 @State var pickerIndex: Int = 0
 @State var password: String = ""
 @State var text: String = ""
 @State var date: Date = Date(timeIntervalSince1970: 0)
 @FocusState var focusedField: String?
 @State var hovered: Bool = false
 @State var doubleTapped: Bool = false
 @State var pushActive: Bool = false

 var body: some View {
   NavigationStack {
     VStack(alignment: .leading, spacing: 1) {
       Text("SwiftTUI KitchenSink")
         .bold()
         .padding(1)
         .border()

       // Basic Navigation
       HStack(spacing: 2) {
         NavigationLink(destination: DetailsView(title: "ASCII Image")) {
           Text("Push ASCII Image")
         }
         NavigationLink(isActive: Binding(get: { pushActive }, set: { pushActive = $0 })) {
           DetailsView(title: "Programmatic Push")
         } label: {
           Text("Programmatic Push")
         }
         Button("Trigger Push") { pushActive = true }
       }
       .padding(1)

       TabView(titles: ["Controls", "Lists & Shapes"], selection: Binding(get: { selectedTab }, set: { selectedTab = $0 })) {
         // Controls tab
         VStack(alignment: .leading, spacing: 1) {
           Toggle("Enable feature", isOn: Binding(get: { toggleOn }, set: { toggleOn = $0 }))
           HStack(spacing: 2) {
             Text("Value:")
             Slider(value: Binding(get: { sliderVal }, set: { sliderVal = $0 }), in: 0...10, step: 1)
             Stepper(value: Binding(get: { stepperVal }, set: { stepperVal = $0 })) { Text("Step: \(stepperVal)") }
           }
           Picker("Picker:", selection: Binding(get: { pickerIndex }, set: { pickerIndex = $0 }), options: ["One", "Two", "Three"]) 
           HStack(spacing: 2) {
             Text("Progress:")
             ProgressView(value: Binding(get: { sliderVal }, set: { sliderVal = $0 }), total: 10)
           }

           // Text input: binding + onSubmit
           TextField(placeholder: "Your name", text: Binding(get: { text }, set: { text = $0 }), onCommit: { /* no-op */ })
             .focused($focusedField, equals: "name")
             .onSubmit { /* exercise onSubmit path */ }
           SecureField(placeholder: "Password", text: Binding(get: { password }, set: { password = $0 }))

           HStack(spacing: 2) {
             Button("Focus Name") { focusedField = "name" }
             Button("Clear Focus") { focusedField = nil }
           }

           // onHover: focus-based; visibly indicate when focused
           Button(action: { /* tap */ }, hover: { hovered.toggle() }) { Text("Hover me (focus)") }
           if hovered { Text("Hover: true").foregroundColor(.green) } else { Text("Hover: false").foregroundColor(.red) }

           // onTapGesture count:2
           Text(doubleTapped ? "Double tapped!" : "Double-tap me")
             .onTapGesture(count: 2) { doubleTapped.toggle() }

           // ScrollView horizontal
           Text("Horizontal ScrollView:")
           ScrollView(.horizontal) {
             HStack(spacing: 1) {
               ForEach(0..<10) { i in
                 Text("[\(i)]").padding(1).border(.rounded)
               }
             }
           }
         }
         // Lists & Shapes tab
         VStack(alignment: .leading, spacing: 1) {
           Text("List with separators:")
           List(rowSpacing: 1) {
             ForEach(1...5) { i in
               Text("Row \(i)")
             }
           }
           .listSeparators(style: .heavy, color: .brightBlue)
           .border()

           Divider().padding(1)

           Text("Shapes and clipping:")
           HStack(spacing: 2) {
             Rectangle().stroke(.magenta).frame(width: 10, height: 4)
             RoundedRectangle(cornerRadius: 2).fill(.cyan).frame(width: 10, height: 4)
             Color.red.frame(width: 6, height: 3).clipShape(Circle())
           }

           Divider().padding(1)

           Text("ASCII Image:")
           Image("""
           /\\/\\
           \\//\\
           /\\/\\
           """)
             .foregroundColor(.yellow)
         }
       }
       .padding(1)
       .border(.rounded)
     }
     .padding(1)
   }
 }
}

private struct DetailsView: View {
 let title: String
 var body: some View {
   VStack(alignment: .leading, spacing: 1) {
     Text(title).bold()
     Image(lines: [
       "  ^  ",
       " /\\ ",
       "/__\\",
     ]).foregroundColor(.green)
     Button("Pop?", action: { /* NavigationStack pop handled by default back actions */ })
   }
   .padding(1)
   .border()
 }
}
