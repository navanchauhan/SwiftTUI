import XCTest
@testable import SwiftTUI

final class ListTests: XCTestCase {
   func test_List_RendersRows() throws {
       let list = List(rowSpacing: 1) {
           Text("One")
           Text("Two")
       }

       let node = Node(view: VStack(content: list).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Provide enough height to show two rows with a blank line between
       control.layout(size: Size(width: 10, height: 3))

       // Query the composed layer output (containers don't override cell())
       XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 0))?.char, "O")
       XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 2))?.char, "T")
   }
}