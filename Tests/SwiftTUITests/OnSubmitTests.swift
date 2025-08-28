import XCTest
@testable import SwiftTUI

final class OnSubmitTests: XCTestCase {
   func test_TextField_OnSubmit_FiresInBindingMode() throws {
       var value = "Hi"
       var submitted = false
       let tf = TextField(placeholder: "", text: Binding(get: { value }, set: { value = $0 }))
           .onSubmit { submitted = true }

       let node = Node(view: VStack(content: tf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.handleEvent("!")
       XCTAssertEqual(value, "Hi!")
       control.handleEvent("\r")
       XCTAssertTrue(submitted)
       // Ensure value not cleared
       XCTAssertEqual(value, "Hi!")
   }

   func test_SecureField_OnSubmit_FiresInBindingMode() throws {
       var value = "Hi"
       var submitted = false
       let sf = SecureField(placeholder: "", text: Binding(get: { value }, set: { value = $0 }))
           .onSubmit { submitted = true }

       let node = Node(view: VStack(content: sf).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.handleEvent("!")
       XCTAssertEqual(value, "Hi!")
       control.handleEvent("\r")
       XCTAssertTrue(submitted)
       XCTAssertEqual(value, "Hi!")
   }
}
