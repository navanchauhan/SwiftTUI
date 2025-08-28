import XCTest
@testable import SwiftTUI

final class RenderingTests: XCTestCase {
    func test_Background_FillsUnderText() throws {
        // Text("X").background(.red) should render 'X' with red background
        let view = Text("X").background(.red)
        let node = Node(view: VStack(content: view).view)
        node.build()
        let stack = try XCTUnwrap(node.control)
        let control = try XCTUnwrap(stack.children.first) // BackgroundControl
        control.layout(size: Size(width: 1, height: 1))

        let cell = control.cell(at: Position(column: 0, line: 0))
        XCTAssertEqual(cell?.char, " ")
        XCTAssertEqual(cell?.backgroundColor, .red)
        // Child content should be "X" with no explicit backgroundColor (inherits)
        let child = try! XCTUnwrap(control.children.first)
        let childCell = child.cell(at: Position(column: 0, line: 0))
        XCTAssertEqual(childCell?.char, "X")
        XCTAssertNil(childCell?.backgroundColor)
    }

    func test_Border_DrawsCornersAndEdges() throws {
        // Border around a single character content should be 3x3 and draw the expected glyphs
        let view = Text("A").border(.default)
        let node = Node(view: VStack(content: view).view)
        node.build()
        let stack = try XCTUnwrap(node.control)
        let control = try XCTUnwrap(stack.children.first) // BorderControl
        control.layout(size: Size(width: 3, height: 3))

        // Corners
        XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "┌")
        XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "┐")
        XCTAssertEqual(control.cell(at: Position(column: 0, line: 2))?.char, "└")
        XCTAssertEqual(control.cell(at: Position(column: 2, line: 2))?.char, "┘")

        // Top/bottom edges
        XCTAssertEqual(control.cell(at: Position(column: 1, line: 0))?.char, "─")
        XCTAssertEqual(control.cell(at: Position(column: 1, line: 2))?.char, "─")

        // Left/right edges
        XCTAssertEqual(control.cell(at: Position(column: 0, line: 1))?.char, "│")
        XCTAssertEqual(control.cell(at: Position(column: 2, line: 1))?.char, "│")
    }
}
