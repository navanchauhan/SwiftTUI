import XCTest
@testable import SwiftTUI

final class SecureFieldCaretTests: XCTestCase {
   func test_SecureField_Caret_EditBindingAtCursor() throws {
       var secret = ""
       let sf = SecureField(text: Binding(get: { secret }, set: { secret = $0 }))
       let node = Node(view: VStack(content: sf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Type 123
       control.handleEvent("1")
       control.handleEvent("2")
       control.handleEvent("3")
       XCTAssertEqual(secret, "123")

       // Move left twice and insert X -> 1X23
       control.handleEvent(ASCII.CTRL_B)
       control.handleEvent(ASCII.CTRL_B)
       control.handleEvent("X")
       XCTAssertEqual(secret, "1X23")

       // Backspace deletes X -> 123
       control.handleEvent(ASCII.DEL)
       XCTAssertEqual(secret, "123")
   }
}
