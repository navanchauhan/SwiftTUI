import XCTest
@testable import SwiftTUI

final class FontTests: XCTestCase {
   func test_FontWeight_BoldMapsToAttribute() throws {
       let view = Text("A").fontWeight(.bold)

       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 1, height: 1))

       let cell = control.cell(at: Position(column: 0, line: 0))
       XCTAssertEqual(cell?.char, "A")
       XCTAssertEqual(cell?.attributes.bold, true)
   }

   func test_Font_SystemWeight_SetsBoldForSemiboldAndUp() throws {
       do {
           let view = Text("A").font(.system(size: 12, weight: .semibold))
           let node = Node(view: VStack(content: view).view)
           node.build()
           let stack = try XCTUnwrap(node.control)
           let control = try XCTUnwrap(stack.children.first)
           control.layout(size: Size(width: 1, height: 1))
           XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.attributes.bold, true)
       }

       do {
           let view = Text("A").font(.system(size: 12, weight: .regular))
           let node = Node(view: VStack(content: view).view)
           node.build()
           let stack = try XCTUnwrap(node.control)
           let control = try XCTUnwrap(stack.children.first)
           control.layout(size: Size(width: 1, height: 1))
           XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.attributes.bold, false)
       }
   }
}
