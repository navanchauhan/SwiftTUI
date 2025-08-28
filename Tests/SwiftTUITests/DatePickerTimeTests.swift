import XCTest
@testable import SwiftTUI

final class DatePickerTimeTests: XCTestCase {

  func test_DatePicker_TimeOnly_RendersAndWrapsMinute() throws {
      var cal = Calendar(identifier: .gregorian)
      cal.timeZone = TimeZone(secondsFromGMT: 0)!
      var date = cal.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 23, minute: 59))!

      let picker = DatePicker(selection: Binding(get: { date }, set: { date = $0 }), displayedComponents: [.hourAndMinute]) as DatePicker<EmptyView>

      let node = Node(view: VStack(content: picker).view)
      node.build()
      let root = try XCTUnwrap(node.control)
      let dp = try XCTUnwrap(root.children.first)

      // Layout to minimal required size
      let needed = dp.size(proposedSize: Size(width: 0, height: 1))
      dp.layout(size: Size(width: needed.width, height: 1))

      // Expect "23:59"
      XCTAssertEqual(dp.cell(at: Position(column: 0, line: 0))?.char, "2")
      XCTAssertEqual(dp.cell(at: Position(column: 1, line: 0))?.char, "3")
      XCTAssertEqual(dp.cell(at: Position(column: 2, line: 0))?.char, ":")
      XCTAssertEqual(dp.cell(at: Position(column: 3, line: 0))?.char, "5")
      XCTAssertEqual(dp.cell(at: Position(column: 4, line: 0))?.char, "9")

      // Increment minute -> wrap to 00:00
      dp.handleEvent("l")
      XCTAssertEqual(dp.cell(at: Position(column: 0, line: 0))?.char, "0")
      XCTAssertEqual(dp.cell(at: Position(column: 1, line: 0))?.char, "0")
      XCTAssertEqual(dp.cell(at: Position(column: 3, line: 0))?.char, "0")
      XCTAssertEqual(dp.cell(at: Position(column: 4, line: 0))?.char, "0")
  }

  func test_DatePicker_DateAndTime_IncrementMinute() throws {
      var cal = Calendar(identifier: .gregorian)
      cal.timeZone = TimeZone(secondsFromGMT: 0)!
      var date = cal.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 12, minute: 34))!

      let picker = DatePicker(selection: Binding(get: { date }, set: { date = $0 }), displayedComponents: [.date, .hourAndMinute]) as DatePicker<EmptyView>

      let node = Node(view: VStack(content: picker).view)
      node.build()
      let root = try XCTUnwrap(node.control)
      let dp = try XCTUnwrap(root.children.first)

      let needed = dp.size(proposedSize: Size(width: 0, height: 1))
      dp.layout(size: Size(width: needed.width, height: 1))

      // Move from default active (.day) to hour and then minute
      dp.handleEvent("j") // day -> hour
      dp.handleEvent("j") // hour -> minute
      dp.handleEvent("l") // increment minute to 35

      // Expect suffix HH:mm to be "12:35"
      // For combined string: yyyy-mm-dd␠HH:mm, hour starts at index 11
      XCTAssertEqual(dp.cell(at: Position(column: 11, line: 0))?.char, "1")
      XCTAssertEqual(dp.cell(at: Position(column: 12, line: 0))?.char, "2")
      XCTAssertEqual(dp.cell(at: Position(column: 13, line: 0))?.char, ":")
      XCTAssertEqual(dp.cell(at: Position(column: 14, line: 0))?.char, "3")
      XCTAssertEqual(dp.cell(at: Position(column: 15, line: 0))?.char, "5")
  }
}
