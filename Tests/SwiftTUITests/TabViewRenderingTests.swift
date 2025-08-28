import XCTest
@testable import SwiftTUI

final class TabViewRenderingTests: XCTestCase {
  func test_TabView_RendersOnlySelectedContent() throws {
      var sel = 0
      let view = TabView(titles: ["One", "Two"], selection: Binding(get: { sel }, set: { sel = $0 })) {
          Text("First")
          Text("Second")
      }

      let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(root.children.first)

       // Layout container: bar + one line of content
       container.layout(size: Size(width: 10, height: 3))

       // Initially selection = 0 -> "First" should render on content line (line 1)
       var c = container.layer.cell(at: Position(column: 0, line: 1))?.char
       XCTAssertEqual(c, "F")

       // Switch to second tab and re-render
       sel = 1
       node.update(using: node.view)
       container.layout(size: Size(width: 10, height: 3))
       c = container.layer.cell(at: Position(column: 0, line: 1))?.char
       XCTAssertEqual(c, "S")
  }
}
