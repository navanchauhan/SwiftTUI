import XCTest
@testable import SwiftTUI

final class ImageTests: XCTestCase {
   func test_Image_ASCII_RendersGrid() throws {
       let img = Image(lines: ["A", "BC"]) // width 2, height 2

       let node = Node(view: VStack(content: img).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Layout to expected size 2x2
       control.layout(size: Size(width: 2, height: 2))

       // Row 0: "A "
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "A")
       XCTAssertEqual(control.cell(at: Position(column: 1, line: 0))?.char, " ")

       // Row 1: "BC"
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 1))?.char, "B")
       XCTAssertEqual(control.cell(at: Position(column: 1, line: 1))?.char, "C")
   }

   func test_Image_Colors_RendersBackground() throws {
       let colors: [[Color?]] = [
           [.red, nil],
           [nil, .blue]
       ]
       let img = Image(colors: colors)

       let node = Node(view: VStack(content: img).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.layout(size: Size(width: 2, height: 2))

       // (0,0) has red background
       let c00 = try XCTUnwrap(control.cell(at: Position(column: 0, line: 0)))
       XCTAssertEqual(c00.backgroundColor, .red)

       // (1,0) is transparent (no cell)
       XCTAssertNil(control.cell(at: Position(column: 1, line: 0)))

       // (1,1) has blue background
       let c11 = try XCTUnwrap(control.cell(at: Position(column: 1, line: 1)))
       XCTAssertEqual(c11.backgroundColor, .blue)
   }
}
