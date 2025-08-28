import XCTest
@testable import SwiftTUI

final class ListRowSeparatorsTests: XCTestCase {
 func test_List_Separators_PerRowStyle_HeavyBelowFirstRow() throws {
     let list = List(rowSpacing: 1) {
         Text("One").listRowSeparator(style: .heavy)
         Text("Two")
     }.listSeparators(style: .plain)

     let node = Node(view: VStack(content: list).view)
     node.build()
     let stack = try XCTUnwrap(node.control)
     let control = try XCTUnwrap(stack.children.first)
     control.layout(size: Size(width: 6, height: 3))

     // Separator after first row should use row-level heavy style
     XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 1))?.char, "━")
 }

 func test_List_Separators_PerRowStyle_NoneOverridesGlobal() throws {
     let list = List(rowSpacing: 1) {
         Text("One").listRowSeparator(style: .none)
         Text("Two")
     }.listSeparators(style: .heavy)

     let node = Node(view: VStack(content: list).view)
     node.build()
     let stack = try XCTUnwrap(node.control)
     let control = try XCTUnwrap(stack.children.first)
     control.layout(size: Size(width: 6, height: 3))

     // Row-level none hides the separator despite global heavy
     XCTAssertEqual(control.layer.cell(at: Position(column: 0, line: 1))?.char, " ")
 }

 func test_List_Separators_PerRowColor_OverridesGlobal() throws {
     let list = List(rowSpacing: 1) {
         Text("One").listRowSeparator(style: .plain, color: .green)
         Text("Two")
     }.listSeparators(style: .plain, color: .brightBlue)

     let node = Node(view: VStack(content: list).view)
     node.build()
     let stack = try XCTUnwrap(node.control)
     let control = try XCTUnwrap(stack.children.first)
     control.layout(size: Size(width: 6, height: 3))

     let cell = control.layer.cell(at: Position(column: 0, line: 1))
     XCTAssertEqual(cell?.char, "─")
     XCTAssertEqual(cell?.foregroundColor, .green)
 }
}
