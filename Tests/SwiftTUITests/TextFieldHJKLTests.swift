import XCTest
@testable import SwiftTUI

final class TextFieldHJKLTests: XCTestCase {
   func test_TextField_BindingEditing_TypingHJKL_UpdatesBinding() throws {
       var value = ""
       let binding = Binding(get: { value }, set: { value = $0 })
       let view = TextField(placeholder: "", text: binding)

       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       control.handleEvent("h")
       control.handleEvent("j")
       control.handleEvent("k")
       control.handleEvent("l")

       XCTAssertEqual(value, "hjkl")
   }
}
