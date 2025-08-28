import XCTest
@testable import SwiftTUI

final class ShapesExtraTests: XCTestCase {
  func test_Circle_ClipShape_CutsCorners() throws {
      let view = Rectangle().fill(.green).clipShape(Circle())
      let node = Node(view: VStack(content: view).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)

      control.layout(size: Size(width: 6, height: 4))
      // Expect rounded clipping to remove extreme corners
      XCTAssertNil(control.cell(at: Position(column: 0, line: 0)))
      XCTAssertNil(control.cell(at: Position(column: 5, line: 0)))
      XCTAssertNil(control.cell(at: Position(column: 0, line: 3)))
      XCTAssertNil(control.cell(at: Position(column: 5, line: 3)))
      // Center should remain filled
      XCTAssertNotNil(control.cell(at: Position(column: 3, line: 2)))
  }

  func test_Capsule_ClipShape_CutsCorners() throws {
      let view = Rectangle().fill(.blue).clipShape(Capsule())
      let node = Node(view: VStack(content: view).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)

      control.layout(size: Size(width: 8, height: 3))
      // Corners should be clipped for capsule ends
      XCTAssertNil(control.cell(at: Position(column: 0, line: 0)))
      XCTAssertNil(control.cell(at: Position(column: 7, line: 0)))
      XCTAssertNil(control.cell(at: Position(column: 0, line: 2)))
      XCTAssertNil(control.cell(at: Position(column: 7, line: 2)))
      // Middle row center should exist
      XCTAssertNotNil(control.cell(at: Position(column: 4, line: 1)))
  }

  func test_Circle_Fill_SetsBackgroundAtCenter() throws {
      let view = Circle().fill(.red)
      let node = Node(view: VStack(content: view).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)
      control.layout(size: Size(width: 5, height: 5))
      let cell = try XCTUnwrap(control.cell(at: Position(column: 2, line: 2)))
      XCTAssertEqual(cell.backgroundColor, .red)
  }
}
