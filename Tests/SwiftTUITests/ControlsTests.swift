import XCTest
@testable import SwiftTUI

final class ControlsTests: XCTestCase {
   func test_Slider_RendersKnobAndBrackets() throws {
       var v: Double = 5
       let slider = Slider(value: Binding(get: { v }, set: { v = $0 }), in: 0...10, step: 1)

       // Build control
       let node = Node(view: VStack(content: slider).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 12, height: 1)) // interior 10

       // [ ● ... ]
       // Positions: 0 '[', 11 ']'
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "[")
       XCTAssertEqual(control.cell(at: Position(column: 11, line: 0))?.char, "]")

       // knob pos: interior=10 -> indices 0..9; ratio 0.5 -> knob at 4 -> column 1+4 = 5
       XCTAssertEqual(control.cell(at: Position(column: 5, line: 0))?.char, "●")
   }

   func test_ProgressView_FilledCount() throws {
       var p: Double = 0.5
       let progress = ProgressView(value: Binding(get: { p }, set: { p = $0 }), total: 1.0)
       let node = Node(view: VStack(content: progress).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 10, height: 1))

       // Expect first 5 cells filled, then empty
       let filled = (0..<5).allSatisfy { control.cell(at: Position(column: Extended($0), line: 0))?.char == "█" }
       let empty = (5..<10).allSatisfy { control.cell(at: Position(column: Extended($0), line: 0))?.char == "░" }
       XCTAssertTrue(filled && empty)
   }

   func test_SecureField_PlaceholderRenders() throws {
       let field = SecureField(placeholder: "Password") { _ in }
       let node = Node(view: VStack(content: field).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 10, height: 1))

       // Since empty, first cell should be 'P'
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "P")
       XCTAssertEqual(control.cell(at: Position(column: 5, line: 0))?.char, "o")
   }

   func test_Toggle_Brackets() throws {
       var on = true
       let toggle = Toggle("Enabled", isOn: Binding(get: { on }, set: { on = $0 }))
       let node = Node(view: VStack(content: toggle).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 20, height: 1))

       XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "[")
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "]")
       // middle should be 'x' for true
       XCTAssertEqual(control.cell(at: Position(column: 1, line: 0))?.char, "x")
   }
}
