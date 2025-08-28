import XCTest
@testable import SwiftTUI

final class ShapesTests: XCTestCase {
   func test_Rectangle_Fill_Background() throws {
       let view = Rectangle().fill(.red)
       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.layout(size: Size(width: 4, height: 2))
       for y in 0..<2 {
           for x in 0..<4 {
               let cell = try XCTUnwrap(control.cell(at: Position(column: Extended(x), line: Extended(y))))
               XCTAssertEqual(cell.backgroundColor, .red)
           }
       }
   }

   func test_Rectangle_Stroke_DrawsBorder() throws {
       let view = Rectangle().stroke(.blue)
       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.layout(size: Size(width: 5, height: 3))
       // Corners
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "┌")
       XCTAssertEqual(control.cell(at: Position(column: 4, line: 0))?.char, "┐")
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 2))?.char, "└")
       XCTAssertEqual(control.cell(at: Position(column: 4, line: 2))?.char, "┘")
       // Edges
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "─")
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 2))?.char, "─")
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 1))?.char, "│")
       XCTAssertEqual(control.cell(at: Position(column: 4, line: 1))?.char, "│")
   }

   func test_RoundedRectangle_ClipShape_CutsCorners() throws {
       // Fill a rectangle, then clip with rounded rect to remove corners
       let view = Rectangle().fill(.green).clipShape(RoundedRectangle(cornerRadius: 2))
       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.layout(size: Size(width: 6, height: 4))
       // Expect rounded corners to be clipped (nil cells)
       XCTAssertNil(control.cell(at: Position(column: 0, line: 0)))
       XCTAssertNil(control.cell(at: Position(column: 5, line: 0)))
       XCTAssertNil(control.cell(at: Position(column: 0, line: 3)))
       XCTAssertNil(control.cell(at: Position(column: 5, line: 3)))
   }
}