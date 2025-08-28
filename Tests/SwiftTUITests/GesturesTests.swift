import XCTest
@testable import SwiftTUI

final class GesturesTests: XCTestCase {
   func test_OnTapGesture_FiresOnEnter() throws {
       var fired = false
       let view = Text("Tap me").onTapGesture { fired = true }

       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let tapWrapper = try XCTUnwrap(stack.children.first)

       // Simulate Enter key
       tapWrapper.handleEvent("\n")
       XCTAssertTrue(fired)
   }
}
