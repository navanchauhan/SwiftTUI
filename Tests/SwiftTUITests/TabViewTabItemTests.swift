import XCTest
@testable import SwiftTUI

final class TabViewTabItemTests: XCTestCase {
   func test_TabView_DerivesTitles_FromChildTabItem() throws {
       var sel = 0
       let view = TabView(selection: Binding(get: { sel }, set: { sel = $0 })) {
           Text("First").tabItem(title: "A")
           Text("Second").tabItem(title: "B")
       }

       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(root.children.first)

       // Layout with enough width for two tabs " A " and " B " plus a spacer
       container.layout(size: Size(width: 12, height: 3))

       // Expect the titles to render on the first line at the expected columns
       // " A " occupies columns 0..2, so 'A' at col 1
       XCTAssertEqual(container.layer.cell(at: Position(column: 1, line: 0))?.char, "A")
       // There is one space separator, so next title starts at col 4; 'B' at col 5
       XCTAssertEqual(container.layer.cell(at: Position(column: 5, line: 0))?.char, "B")

       // Initially selection = 0 -> content shows "First" on content line (line 1)
       XCTAssertEqual(container.layer.cell(at: Position(column: 0, line: 1))?.char, "F")

       // Switch to second tab and re-render
       sel = 1
       node.update(using: node.view)
       container.layout(size: Size(width: 12, height: 3))
       XCTAssertEqual(container.layer.cell(at: Position(column: 0, line: 1))?.char, "S")
   }
}
