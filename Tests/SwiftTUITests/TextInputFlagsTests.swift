import XCTest
@testable import SwiftTUI

final class TextInputFlagsTests: XCTestCase {
   func test_TextField_Control_IsTextInputTrue() throws {
       let tf = TextField(placeholder: "") { _ in }
       let node = Node(view: VStack(content: tf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       XCTAssertTrue(control.isTextInput, "TextField control should report isTextInput true")
   }

   func test_SecureField_Control_IsTextInputTrue() throws {
       let sf = SecureField(placeholder: "") { _ in }
       let node = Node(view: VStack(content: sf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       XCTAssertTrue(control.isTextInput, "SecureField control should report isTextInput true")
   }

   func test_Button_Control_IsTextInputFalse() throws {
       let b = Button("Tap") { }
       let node = Node(view: VStack(content: b).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       XCTAssertFalse(control.isTextInput, "Button control should not be a text input")
   }
}
