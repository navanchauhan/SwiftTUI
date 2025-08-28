import XCTest
@testable import SwiftTUI

final class ListSeparatorsTests: XCTestCase {
  func test_List_Separators_RenderBetweenRows() throws {
      let list = List(rowSpacing: 1) {
          Text("One")
          Text("Two")
      }.listSeparators()

      let node = Node(view: VStack(content: list).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)

      // Provide enough height to show two rows with a blank line between
      control.layout(size: Size(width: 6, height: 3))

      // Separator should appear on the middle line
      XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 1))?.char, "─")
  }

  func test_List_Separators_Style_Heavy_RendersHeavyLine() throws {
      let list = List(rowSpacing: 1) {
          Text("One")
          Text("Two")
      }.listSeparators(style: .heavy)

      let node = Node(view: VStack(content: list).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)
      control.layout(size: Size(width: 6, height: 3))
      XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 1))?.char, "━")
  }

  func test_List_Separators_Style_Double_RendersDoubleLine() throws {
      let list = List(rowSpacing: 1) {
          Text("One")
          Text("Two")
      }.listSeparators(style: .double)

      let node = Node(view: VStack(content: list).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)
      control.layout(size: Size(width: 6, height: 3))
      XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 1))?.char, "═")
  }

  func test_List_Separators_Style_None_ShowsNoLine() throws {
       let list = List(rowSpacing: 1) {
           Text("One")
           Text("Two")
       }.listSeparators(style: .none)

       let node = Node(view: VStack(content: list).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 6, height: 3))
       // With no separators, the blank spacing line remains a space, not a line glyph
       XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 1))?.char, " ")
  }

  func test_List_Separators_CustomColor_Applied() throws {
      let list = List(rowSpacing: 1) {
          Text("One")
          Text("Two")
      }.listSeparators(style: .plain, color: .red)

      let node = Node(view: VStack(content: list).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)
      control.layout(size: Size(width: 6, height: 3))
      let cell = control.layer.cell(at: Position(column: 0, line: 1))
      XCTAssertEqual(cell?.char, "─")
      XCTAssertEqual(cell?.foregroundColor, .red)
  }
}
