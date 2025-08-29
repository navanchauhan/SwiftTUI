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


   func test_Picker_RendersFieldAndSelection() throws {
       var idx = 1
       let picker = Picker(selection: Binding(get: { idx }, set: { idx = $0 }), options: ["Red", "Green", "Blue"]) as Picker<EmptyView, EmptyView>

       let node = Node(view: VStack(content: picker).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Layout with computed minimal size
       let needed = control.size(proposedSize: Size(width: 0, height: 1))
       control.layout(size: needed)

       // Expect "< Green >" (idx = 1)
       XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "<")
       XCTAssertEqual(control.cell(at: Position(column: 1, line: 0))?.char, " ")
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "G")
       let lastCol = needed.width.intValue - 1
       XCTAssertEqual(control.cell(at: Position(column: Extended(lastCol), line: 0))?.char, ">")
   }

   func test_Picker_ChangesSelectionWithHL() throws {
       var idx = 0
       let picker = Picker(selection: Binding(get: { idx }, set: { idx = $0 }), options: ["One", "Two"]) as Picker<EmptyView, EmptyView>

       let node = Node(view: VStack(content: picker).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       let needed = control.size(proposedSize: Size(width: 0, height: 1))
       control.layout(size: needed)

       // Initially "< One >"
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "O")

       // Press 'l' to move to "Two"
       control.handleEvent("l")
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "T")

       // Press 'h' to move back to "One"
       control.handleEvent("h")
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "O")
   }


   func test_Stepper_RendersAndChanges() throws {
       var v = 10
       let stepper = Stepper(value: Binding(get: { v }, set: { v = $0 }), in: 0...100, step: 5) as Stepper<EmptyView>

        let node = Node(view: VStack(content: stepper).view)
        node.build()
        let stack = try XCTUnwrap(node.control)
        let control = try XCTUnwrap(stack.children.first)
        let needed = control.size(proposedSize: Size(width: 0, height: 1))
        control.layout(size: needed)

        // Expect "[-] 10 [+]"
        XCTAssertEqual(control.cell(at: Position(column: 0, line: 0))?.char, "[")
        XCTAssertEqual(control.cell(at: Position(column: 1, line: 0))?.char, "-")
        XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "]")
        XCTAssertEqual(control.cell(at: Position(column: 4, line: 0))?.char, "1")
        XCTAssertEqual(control.cell(at: Position(column: 5, line: 0))?.char, "0")
        // increment to 15
        control.handleEvent("+")
        XCTAssertEqual(control.cell(at: Position(column: 4, line: 0))?.char, "1")
        XCTAssertEqual(control.cell(at: Position(column: 5, line: 0))?.char, "5")
        // decrement back to 10
        control.handleEvent("-")
        XCTAssertEqual(control.cell(at: Position(column: 5, line: 0))?.char, "0")
   }


   func test_Picker_TagSelection_RendersAndChanges() throws {
       enum Flavor: Equatable { case vanilla, chocolate, strawberry }
       var sel: Flavor = .chocolate
       let opts: [(String, Flavor)] = [("Vanilla", .vanilla), ("Chocolate", .chocolate), ("Strawberry", .strawberry)]
       let picker = Picker(selection: Binding(get: { sel }, set: { sel = $0 }), options: opts) as Picker<EmptyView, EmptyView>

       let node = Node(view: VStack(content: picker).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       let needed = control.size(proposedSize: Size(width: 0, height: 1))
       control.layout(size: needed)

       // Initially "< Chocolate >"
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "C")

       // Cycle forward to Strawberry
       control.handleEvent("l")
       XCTAssertEqual(sel, .strawberry)
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "S")

       // Cycle forward to wrap to Vanilla
       control.handleEvent("l")
       XCTAssertEqual(sel, .vanilla)
       XCTAssertEqual(control.cell(at: Position(column: 2, line: 0))?.char, "V")
   }

}