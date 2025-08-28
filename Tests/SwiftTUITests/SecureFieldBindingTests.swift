import XCTest
@testable import SwiftTUI

final class SecureFieldBindingTests: XCTestCase {
   func test_SecureField_BindingEditing_TypingAndBackspace_UpdatesBinding() throws {
       var value = ""
       let binding = Binding(get: { value }, set: { value = $0 })
       let view = SecureField(placeholder: "", text: binding)

       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.handleEvent("A")
       control.handleEvent("B")
       XCTAssertEqual(value, "AB")

       control.handleEvent(ASCII.DEL)
       XCTAssertEqual(value, "A")
   }

   func test_SecureField_BindingEditing_OnCommit_DoesNotClearBinding() throws {
       var value = "Hi"
       var committed = false
       let binding = Binding(get: { value }, set: { value = $0 })
       let view = SecureField(placeholder: "", text: binding) { committed = true }

       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.handleEvent("!")
       XCTAssertEqual(value, "Hi!")
       control.handleEvent("\r")
       XCTAssertTrue(committed)
       XCTAssertEqual(value, "Hi!")
   }
}
