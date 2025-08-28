import XCTest
@testable import SwiftTUI

final class ScrollIndicatorsTests: XCTestCase {
 func test_ScrollView_ScrollIndicators_NoOpRendering() throws {
     // Build two identical ScrollViews; one with the no-op modifier.
     let base = ScrollView {
         VStack {
             Text("A")
             Text("B")
         }
     }
     let withNoIndicators = base.scrollIndicators(.hidden)

     let node1 = Node(view: VStack(content: base).view)
     node1.build()
     let control1 = try XCTUnwrap(node1.control?.children.first)
     control1.layout(size: Size(width: 4, height: 2))

     let node2 = Node(view: VStack(content: withNoIndicators).view)
     node2.build()
     let control2 = try XCTUnwrap(node2.control?.children.first)
     control2.layout(size: Size(width: 4, height: 2))

     // Expect same content at a few sample positions
     for line in 0..<2 {
         let c1 = control1.layer.cell(at: Position(column: 0, line: Extended(line)))?.char
         let c2 = control2.layer.cell(at: Position(column: 0, line: Extended(line)))?.char
         XCTAssertEqual(c1, c2)
     }
 }
}
