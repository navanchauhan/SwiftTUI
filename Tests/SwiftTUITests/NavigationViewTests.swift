import XCTest
@testable import SwiftTUI

final class NavigationViewTests: XCTestCase {
   func test_NavigationView_PushOnLinkChangesTopControl() throws {
       let view = NavigationView {
           NavigationLink(destination: Text("Second")) { Text("Go") }
       }
       let node = Node(view: VStack(content: view).view)
       node.build()

       let rootControl = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(rootControl.children.first)
       let beforeFirst = container.children.first

       let linkButton = try XCTUnwrap(container.children.first)
       linkButton.handleEvent("\n")

       let afterFirst = container.children.first
       XCTAssertTrue(beforeFirst !== afterFirst, "Container top control should change after push via NavigationView")
   }
}
