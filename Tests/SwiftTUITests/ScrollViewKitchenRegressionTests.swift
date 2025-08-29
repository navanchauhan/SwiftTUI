import XCTest
@testable import SwiftTUI

final class ScrollViewKitchenRegressionTests: XCTestCase {
   func test_HorizontalScrollView_ComposedItems_RenderVisible() throws {
       // Mimic KitchenSink: horizontal scroll with bordered, padded items
       let view = ScrollView(.horizontal) {
           HStack(spacing: 1) {
               ForEach(0..<3, id: \.self) { i in
                   Text("[\(i)]").padding(1).border(.rounded)
               }
           }
       }
       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let scroll = try XCTUnwrap(root.children.first)

       // Provide a modest viewport that can show at least part of one item
       scroll.layout(size: Size(width: 10, height: 3))

       // Expect some non-space visible in the first row (e.g., border glyph)
       let firstRowHasGlyph = (0..<10).contains { col in
           if let ch = scroll.layer.cell(at: Position(column: Extended(col), line: 0))?.char {
               return ch != " "
           }
           return false
       }
       XCTAssertTrue(firstRowHasGlyph)
   }

   func test_List_WithSeparators_InsideBorder_RendersRows() throws {
       let list = List(rowSpacing: 1) {
           Text("One")
           Text("Two")
       }
       .listSeparators(style: .plain)
       .border()

       let node = Node(view: VStack(content: list).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Border adds 1px frame; allow interior to render both rows
       control.layout(size: Size(width: 10, height: 5))

       // Inside the border (offset 1,1), the first row should start with 'O'
       XCTAssertEqual(control.layer.cell(at: Position(column: 1, line: 1))?.char, "O")
       // And the second row at interior line 3 should start with 'T'
       XCTAssertEqual(control.layer.cell(at: Position(column: 1, line: 3))?.char, "T")
   }
}
