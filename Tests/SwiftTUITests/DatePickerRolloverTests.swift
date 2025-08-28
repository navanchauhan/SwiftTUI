import XCTest
@testable import SwiftTUI

final class DatePickerRolloverTests: XCTestCase {
 func test_DatePicker_MonthIncrement_ClampsDay_NonLeap() throws {
     var cal = Calendar(identifier: .gregorian)
     cal.timeZone = TimeZone(secondsFromGMT: 0)!
     var date = cal.date(from: DateComponents(year: 2023, month: 1, day: 31))!

     let picker = DatePicker(selection: Binding(get: { date }, set: { date = $0 }), displayedComponents: [.date]) as DatePicker<EmptyView>

     let node = Node(view: VStack(content: picker).view)
     node.build()
     let root = try XCTUnwrap(node.control)
     let dp = try XCTUnwrap(root.children.first)

     // Go from default active day -> month
     dp.handleEvent("k")
     // Increment month: Jan 31 + 1 month => Feb 28 in 2023
     dp.handleEvent("l")

     // Expect yyyy-mm-dd = 2023-02-28
     let expect = Array("2023-02-28")
     for (i, ch) in expect.enumerated() {
         XCTAssertEqual(dp.cell(at: Position(column: Extended(i), line: 0))?.char, ch)
     }
 }

 func test_DatePicker_MonthIncrement_ClampsDay_LeapYear() throws {
     var cal = Calendar(identifier: .gregorian)
     cal.timeZone = TimeZone(secondsFromGMT: 0)!
     var date = cal.date(from: DateComponents(year: 2024, month: 1, day: 31))!

     let picker = DatePicker(selection: Binding(get: { date }, set: { date = $0 }), displayedComponents: [.date]) as DatePicker<EmptyView>

     let node = Node(view: VStack(content: picker).view)
     node.build()
     let root = try XCTUnwrap(node.control)
     let dp = try XCTUnwrap(root.children.first)

     // Go from day -> month
     dp.handleEvent("k")
     // Increment month: Jan 31 + 1 month => Feb 29 in 2024
     dp.handleEvent("l")

     // Expect yyyy-mm-dd = 2024-02-29
     let expect = Array("2024-02-29")
     for (i, ch) in expect.enumerated() {
         XCTAssertEqual(dp.cell(at: Position(column: Extended(i), line: 0))?.char, ch)
     }
 }

 func test_DatePicker_YearIncrement_ClampsFeb29_ToFeb28() throws {
     var cal = Calendar(identifier: .gregorian)
     cal.timeZone = TimeZone(secondsFromGMT: 0)!
     var date = cal.date(from: DateComponents(year: 2024, month: 2, day: 29))!

     let picker = DatePicker(selection: Binding(get: { date }, set: { date = $0 }), displayedComponents: [.date]) as DatePicker<EmptyView>

     let node = Node(view: VStack(content: picker).view)
     node.build()
     let root = try XCTUnwrap(node.control)
     let dp = try XCTUnwrap(root.children.first)

     // Move from day -> month -> year
     dp.handleEvent("k")
     dp.handleEvent("k")
     // Increment year: 2024-02-29 + 1 year => 2025-02-28
     dp.handleEvent("l")

     let expect = Array("2025-02-28")
     for (i, ch) in expect.enumerated() {
         XCTAssertEqual(dp.cell(at: Position(column: Extended(i), line: 0))?.char, ch)
     }
 }
}
