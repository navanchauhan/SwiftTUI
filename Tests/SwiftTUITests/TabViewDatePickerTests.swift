import XCTest
@testable import SwiftTUI

final class TabViewDatePickerTests: XCTestCase {
   func test_TabView_SelectionChangesOnEnter() throws {
       var selection: Int = 1
       let view = TabView(titles: ["One", "Two"], selection: Binding(get: { selection }, set: { selection = $0 })) {
           Text("First")
           Text("Second")
       }
       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let tabViewContainer = try XCTUnwrap(root.children.first)

       // First child of TabView is first tab button; simulate activation
       let firstTabButton = try XCTUnwrap(tabViewContainer.children.first)
       firstTabButton.handleEvent("\n")

       XCTAssertEqual(selection, 0, "Tab selection should update to first tab on activation")
   }

   func test_DatePicker_IncrementDay() throws {
       let cal = Calendar(identifier: .gregorian)
       var date = cal.date(from: DateComponents(year: 2024, month: 1, day: 1))!
       let picker = DatePicker(selection: Binding(get: { date }, set: { date = $0 })) as DatePicker<EmptyView>

       let node = Node(view: VStack(content: picker).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let dpControl = try XCTUnwrap(root.children.first)

       dpControl.handleEvent("l") // increment active component (day) by 1

       let next = cal.date(from: DateComponents(year: 2024, month: 1, day: 2))!
       // Compare days ignoring time/timezone
       let d1 = cal.dateComponents([.year, .month, .day], from: date)
       let d2 = cal.dateComponents([.year, .month, .day], from: next)
       XCTAssertEqual(d1, d2)
   }
}
