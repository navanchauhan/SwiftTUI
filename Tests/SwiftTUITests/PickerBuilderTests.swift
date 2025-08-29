import XCTest
@testable import SwiftTUI

final class PickerBuilderTests: XCTestCase {
  func test_PickerBuilder_RendersSelectedOption() throws {
      var idx = 0
      let root = VStack {
          Picker(selection: Binding(get: { idx }, set: { idx = $0 })) {
              Text("One")
              Text("Two")
              Text("Three")
          }
      }
      let node = Node(view: root.view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)
      let needed = control.size(proposedSize: Size(width: 0, height: 1))
      control.layout(size: needed)

      // Expect "< One >" initially
      XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "O")
  }

  func test_PickerBuilder_CyclesWithHL() throws {
      var idx = 0
      let root = VStack {
          Picker(selection: Binding(get: { idx }, set: { idx = $0 })) {
              Text("One")
              Text("Two")
          }
      }
      let node = Node(view: root.view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)
      let needed = control.size(proposedSize: Size(width: 0, height: 1))
      control.layout(size: needed)

      // Initially "One"
      XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "O")

      // Press 'l' to move to "Two"
      control.handleEvent("l")
      XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "T")
  }
}
