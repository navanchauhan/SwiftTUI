import XCTest
@testable import SwiftTUI

final class AccentColorTests: XCTestCase {
   func test_TabView_SelectedTab_UsesAccentColor() throws {
       var sel = 0
       let tv = TabView(titles: ["One", "Two"], selection: Binding(get: { sel }, set: { sel = $0 })) {
           Text("A")
           Text("B")
       }.accentColor(.red)

       let node = Node(view: VStack(content: tv).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(root.children.first)

       // Layout: bar + one line of content
       container.layout(size: Size(width: 12, height: 3))

       // Selected tab is index 0 ("One"). Cell at (1,0) should be 'O' with inverted and red fg
       let c = container.layer.cell(at: Position(column: 1, line: 0))
       XCTAssertEqual(c?.char, "O")
       XCTAssertEqual(c?.foregroundColor, .red)
       XCTAssertTrue(c?.attributes.inverted == true)
   }

   func test_ProgressView_Filled_UsesAccentColor() throws {
       var v = 0.5
       let pv = ProgressView(value: Binding(get: { v }, set: { v = $0 }), total: 1).accentColor(.red)
       let node = Node(view: VStack(content: pv).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(root.children.first)
       control.layout(size: Size(width: 10, height: 1))

       // First half filled -> red '█'
       for col in 0..<5 {
           let cell = control.cell(at: Position(column: Extended(col), line: 0))
           XCTAssertEqual(cell?.char, "█")
           XCTAssertEqual(cell?.foregroundColor, .red)
       }
       // Second half unfilled -> '░' (no enforced color)
       let cell5 = control.cell(at: Position(column: 7, line: 0))
       XCTAssertEqual(cell5?.char, "░")
   }

   func test_ScrollView_Indicator_UsesAccentColor() throws {
       let base = ScrollView {
           VStack(alignment: .leading, spacing: 0) {
               Text("A")
               Text("B")
               Text("C")
           }
       }.scrollIndicators(.visible).accentColor(.red)

       let node = Node(view: VStack(content: base).view)
       node.build()
       let control = try XCTUnwrap(node.control?.children.first)
       control.layout(size: Size(width: 4, height: 2))
       let rightCol = 3
       var foundRed = false
       for line in 0..<2 {
           let cell = control.layer.cell(at: Position(column: Extended(rightCol), line: Extended(line)))
           if let ch = cell?.char, ch != " " {
               foundRed = (cell?.foregroundColor == .red)
               break
           }
       }
       XCTAssertTrue(foundRed)
   }
}
