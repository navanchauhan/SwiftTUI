import XCTest
@testable import SwiftTUI

final class InputCRTests: XCTestCase {

   func test_Button_EnterCRTriggersAction() throws {
       var tapped = false
       let button = Button("Tap") { tapped = true }
       let node = Node(view: VStack(content: button).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Simulate CR (carriage return) as Enter
       control.handleEvent("\r")
       XCTAssertTrue(tapped, "Button action should fire on CR Enter")
   }

   func test_TextField_SubmitsOnCR() throws {
       var submitted: String? = nil
       let tf = TextField(placeholder: "") { submitted = $0 }
       let node = Node(view: VStack(content: tf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Type AB and submit with CR
       control.handleEvent("A")
       control.handleEvent("B")
       control.handleEvent("\r")
       XCTAssertEqual(submitted, "AB")
   }

   func test_SecureField_SubmitsOnCR() throws {
       var submitted: String? = nil
       let sf = SecureField(placeholder: "") { submitted = $0 }
       let node = Node(view: VStack(content: sf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       // Type AB and submit with CR
       control.handleEvent("A")
       control.handleEvent("B")
       control.handleEvent("\r")
       XCTAssertEqual(submitted, "AB")
   }
}
