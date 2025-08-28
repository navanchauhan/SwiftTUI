import XCTest
@testable import SwiftTUI

final class TextFieldBackspaceTests: XCTestCase {
  func test_TextField_BindingEditing_BackspaceBS_DeletesLast() throws {
      var value = "AB"
      let binding = Binding(get: { value }, set: { value = $0 })
      let view = TextField(placeholder: "", text: binding)

      let node = Node(view: VStack(content: view).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)

      control.handleEvent(ASCII.BS)
      XCTAssertEqual(value, "A")
  }
}
