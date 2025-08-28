import XCTest
@testable import SwiftTUI

final class BackgroundViewTests: XCTestCase {
   func test_BackgroundView_RendersBehindContent() throws {
       // Text("X") with a red rectangle background should render 'X' with red background
       let view = Text("X").background { Rectangle().fill(.red) }
       let node = Node(view: VStack(content: view).view)
       node.build()

       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 1, height: 1))

       // Query composed layer output (container does composition)
       let cell = control.layer.cell(at: Position(column: 0, line: 0))
       XCTAssertEqual(cell?.char, "X")
       XCTAssertEqual(cell?.backgroundColor, .red)
   }
}
