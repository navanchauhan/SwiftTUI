import XCTest
@testable import SwiftTUI

final class TextFieldCaretTests: XCTestCase {
   func test_TextField_Caret_InsertAndBackspaceAtCursor() throws {
       var value = ""
       let tf = TextField(text: Binding(get: { value }, set: { value = $0 }))
       let node = Node(view: VStack(content: tf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Type ABC at end
       control.handleEvent("A")
       control.handleEvent("B")
       control.handleEvent("C")
       XCTAssertEqual(value, "ABC")

       // Move caret left twice (to between A and B), insert X -> AXBC
       control.handleEvent(ASCII.CTRL_B)
       control.handleEvent(ASCII.CTRL_B)
       control.handleEvent("X")
       XCTAssertEqual(value, "AXBC")

       // Backspace should delete X and move caret left
       control.handleEvent(ASCII.DEL)
       XCTAssertEqual(value, "ABC")

       // Move to start and insert Z at beginning
       control.handleEvent(ASCII.CTRL_B)
       control.handleEvent(ASCII.CTRL_B)
       control.handleEvent(ASCII.CTRL_B)
       control.handleEvent("Z")
       XCTAssertEqual(value, "ZABC")
   }
}
