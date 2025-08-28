import XCTest
@testable import SwiftTUI

final class SecureFieldBackspaceTests: XCTestCase {
  func test_SecureField_BindingEditing_BackspaceBS_DeletesLast() throws {
      var value = "XY"
      let binding = Binding(get: { value }, set: { value = $0 })
      let view = SecureField(placeholder: "", text: binding)

      let node = Node(view: VStack(content: view).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let control = try XCTUnwrap(stack.children.first)

      control.handleEvent(ASCII.BS)
      XCTAssertEqual(value, "X")
  }
}
