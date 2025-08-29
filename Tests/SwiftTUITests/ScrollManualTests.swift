import XCTest
@testable import SwiftTUI

final class ScrollManualTests: XCTestCase {
   func test_ScrollView_ManualScroll_DownOneLine_ShowsNextRow() throws {
       // Build a vertical ScrollView with three lines and a 2-line viewport
       let view = ScrollView {
           VStack(alignment: .leading, spacing: 0) {
               Text("A")
               Text("B")
               Text("C")
           }
       }
       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let scroll = try XCTUnwrap(root.children.first)

       // Layout to 1x2 (width x height)
       let size = Size(width: 2, height: 2)
       scroll.layout(size: size)

       // Initially top cell should be 'A'
       XCTAssertEqual(scroll.layer.cell(at: Position(column: 0, line: 0))?.char, "A")

       // Scroll down by one line and re-layout
       _ = scroll.scrollBy(lines: 1, columns: 0)
       scroll.layout(size: size)

       // Now the top cell should be 'B'
       XCTAssertEqual(scroll.layer.cell(at: Position(column: 0, line: 0))?.char, "B")
   }
}
