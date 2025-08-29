import XCTest
@testable import SwiftTUI

final class TintTests: XCTestCase {
   func test_TabView_Tint_AppliesToSelectedTab() throws {
       var sel = 0
       let tv = TabView(titles: ["One", "Two"], selection: Binding(get: { sel }, set: { sel = $0 })) {
           Text("A")
           Text("B")
       }.tint(.magenta)

       let node = Node(view: VStack(content: tv).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(root.children.first)
       container.layout(size: Size(width: 10, height: 3))

       // Selected tab text should have the tinted (accent) color
       // The tab bar is drawn on line 0; first letter of "One" at column 1
       let c = container.layer.cell(at: Position(column: 1, line: 0))
       XCTAssertEqual(c?.foregroundColor, .magenta)
   }

   func test_ProgressView_Tint_AppliesToFill() throws {
       var v = 0.5
       let pv = ProgressView(value: Binding(get: { v }, set: { v = $0 }), total: 1).tint(.brightGreen)
       let node = Node(view: VStack(content: pv).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(root.children.first)
       control.layout(size: Size(width: 10, height: 1))

       for col in 0..<5 {
           let cell = control.cell(at: Position(column: Extended(col), line: 0))
           XCTAssertEqual(cell?.char, "█")
           XCTAssertEqual(cell?.foregroundColor, .brightGreen)
       }
   }
}
