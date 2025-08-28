import XCTest
@testable import SwiftTUI

final class NavigationCRTests: XCTestCase {
   func test_NavigationStack_PushOnLink_WithCR_TriggersPush() throws {
       let view = NavigationStack {
           NavigationLink(destination: Text("Second")) { Text("Go") }
       }
       let node = Node(view: VStack(content: view).view)
       node.build()

       let rootControl = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(rootControl.children.first)
       let beforeFirst = container.children.first

       let linkButton = try XCTUnwrap(container.children.first)
       // Simulate carriage return (CR) Enter
       linkButton.handleEvent("\r")

       let afterFirst = container.children.first
       XCTAssertTrue(beforeFirst !== afterFirst, "Container top control should change after CR push")
   }
}
