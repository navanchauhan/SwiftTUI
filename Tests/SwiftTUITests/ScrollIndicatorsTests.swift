import XCTest
@testable import SwiftTUI

final class ScrollIndicatorsTests: XCTestCase {
   func test_ScrollView_ScrollIndicators_Hidden_HasNoOverlay() throws {
       // Overflowing content (3 rows) into a 2-line viewport
       let base = ScrollView {
           VStack(alignment: .leading, spacing: 0) {
               Text("A")
               Text("B")
               Text("C")
           }
       }
       let visible = base.scrollIndicators(.visible)
       let hidden = base.scrollIndicators(.hidden)

       let nodeVisible = Node(view: VStack(content: visible).view)
       nodeVisible.build()
       let cv = try XCTUnwrap(nodeVisible.control?.children.first)
       cv.layout(size: Size(width: 4, height: 2))

       let nodeHidden = Node(view: VStack(content: hidden).view)
       nodeHidden.build()
       let ch = try XCTUnwrap(nodeHidden.control?.children.first)
       ch.layout(size: Size(width: 4, height: 2))

       // Rightmost column should contain a thumb in the visible case, none in hidden
       let rightCol = 3 // width 4 -> last index is 3
       var visibleCount = 0
       var hiddenCount = 0
       for line in 0..<2 {
           if let c = cv.layer.cell(at: Position(column: Extended(rightCol), line: Extended(line)))?.char, c != " " {
               visibleCount += 1
           }
           if let c = ch.layer.cell(at: Position(column: Extended(rightCol), line: Extended(line)))?.char, c != " " {
               hiddenCount += 1
           }
       }
       XCTAssertGreaterThan(visibleCount, 0)
       XCTAssertEqual(hiddenCount, 0)
   }

   func test_ScrollView_ScrollIndicators_Automatic_OnlyWhenOverflow() throws {
       // Non-overflow case (2 rows, 2 lines viewport)
       let nonOverflow = ScrollView {
           VStack(alignment: .leading, spacing: 0) {
               Text("A")
               Text("B")
           }
       }
       let nodeNo = Node(view: VStack(content: nonOverflow).view)
       nodeNo.build()
       let cNo = try XCTUnwrap(nodeNo.control?.children.first)
       cNo.layout(size: Size(width: 4, height: 2))
       let rightCol = 3
       var countNo = 0
       for line in 0..<2 {
           if let c = cNo.layer.cell(at: Position(column: Extended(rightCol), line: Extended(line)))?.char, c != " " {
               countNo += 1
           }
       }
       XCTAssertEqual(countNo, 0)

       // Overflow case (3 rows, 2 lines viewport) should show indicator by default (.automatic)
       let overflow = ScrollView {
           VStack(alignment: .leading, spacing: 0) {
               Text("A")
               Text("B")
               Text("C")
           }
       }
       let nodeYes = Node(view: VStack(content: overflow).view)
       nodeYes.build()
       let cYes = try XCTUnwrap(nodeYes.control?.children.first)
       cYes.layout(size: Size(width: 4, height: 2))
       var countYes = 0
       for line in 0..<2 {
           if let c = cYes.layer.cell(at: Position(column: Extended(rightCol), line: Extended(line)))?.char, c != " " {
               countYes += 1
           }
       }
       XCTAssertGreaterThan(countYes, 0)
   }
}
