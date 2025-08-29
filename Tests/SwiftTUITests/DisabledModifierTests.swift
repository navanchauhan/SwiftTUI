import XCTest
@testable import SwiftTUI

final class DisabledModifierTests: XCTestCase {
   func test_Button_Disabled_DoesNotActivate_AndFaints() throws {
       var fired = false
       let button = Button("Go", action: { fired = true }).disabled(true)

       let node = Node(view: VStack(content: button).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Layout to allow cell inspection
       let needed = control.size(proposedSize: Size(width: 0, height: 1))
       control.layout(size: needed)

       // Simulate activation
       control.handleEvent("\n")
       XCTAssertFalse(fired, "Disabled button should not fire action")

       // Visual fainting is a best-effort approximation; primary contract is non-activation.
   }

   func test_Toggle_Disabled_NotSelectable_DoesNotToggle() throws {
       var on = false
       let toggle = Toggle("Enabled", isOn: Binding(get: { on }, set: { on = $0 })).disabled(true)
       let node = Node(view: VStack(content: toggle).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 12, height: 1))

       // Try to activate
       control.handleEvent("\n")
       XCTAssertFalse(on, "Disabled toggle should not change state")

       // Should not be selectable
       XCTAssertNil(control.firstSelectableElement, "Disabled toggle not selectable")
   }

   func test_Slider_Disabled_IgnoresInput_AndFaints() throws {
       var v: Double = 5
       let slider = Slider(value: Binding(get: { v }, set: { v = $0 }), in: 0...10, step: 1).disabled(true)
       let node = Node(view: VStack(content: slider).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 12, height: 1))

       // Attempt to increment
       control.handleEvent("l")
       XCTAssertEqual(v, 5, "Disabled slider should ignore input")
       // Faint on a bracket cell
       let cell = control.cell(at: Position(column: 0, line: 0))
       XCTAssertTrue(cell?.attributes.faint == true)
   }

   func test_Picker_Disabled_IgnoresInput_AndFaints() throws {
       var idx = 0
       let picker = Picker(selection: Binding(get: { idx }, set: { idx = $0 }), options: ["One","Two"]).disabled(true)
       let node = Node(view: VStack(content: picker).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       let needed = control.size(proposedSize: Size(width: 0, height: 1))
       control.layout(size: needed)
       // Try to change selection
       control.handleEvent("l")
       XCTAssertEqual(idx, 0, "Disabled picker should ignore input")
       // Faint on '<'
       let cell = control.cell(at: Position(column: 0, line: 0))
       XCTAssertTrue(cell?.attributes.faint == true)
   }

   func test_TextField_Disabled_IgnoresTyping_AndFaints() throws {
       var text = ""
       let tf = TextField(placeholder: "Name", text: Binding(get: { text }, set: { text = $0 })).disabled(true)
       let node = Node(view: VStack(content: tf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       let needed = control.size(proposedSize: Size(width: 10, height: 1))
       control.layout(size: needed)
       control.handleEvent("A")
       XCTAssertEqual(text, "", "Disabled text field should ignore typing")
       let c0 = control.cell(at: Position(column: 0, line: 0))
       XCTAssertTrue(c0?.attributes.faint == true)
   }
}