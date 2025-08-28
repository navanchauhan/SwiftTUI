import XCTest
@testable import SwiftTUI

final class OverlayTests: XCTestCase {
  func test_Overlay_TextCoversContent() throws {
      // Overlay a "*" on top of "X"; expect topmost char to be "*"
      let view = Text("X").overlay { Text("*") }
      let node = Node(view: VStack(content: view).view)
      node.build()

      let root = try XCTUnwrap(node.control)
      let container = try XCTUnwrap(root.children.first) // overlay container

      container.layout(size: Size(width: 1, height: 1))
      let cell = container.layer.cell(at: Position(column: 0, line: 0))
      XCTAssertEqual(cell?.char, "*")
  }
}
