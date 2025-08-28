import XCTest
@testable import SwiftTUI

final class NavigationTests: XCTestCase {
    func test_NavigationStack_PushOnLinkChangesTopControl() throws {
        let view = NavigationStack {
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
        XCTAssertTrue(beforeFirst !== afterFirst, "Container top control should change after push")
    }

    func test_NavigationStack_OnlyTopControlsDisplayed() throws {
        let view = NavigationStack {
            VStack {
                NavigationLink(destination: Text("Second")) { Text("Go") }
            }
        }
        let node = Node(view: VStack(content: view).view)
        node.build()

        let rootControl = try XCTUnwrap(node.control)
        let container = try XCTUnwrap(rootControl.children.first)
        let beforeFirst = container.children.first

        let linkButton = try XCTUnwrap(container.children.first)
        linkButton.handleEvent("\n")

        let afterFirst = container.children.first
        XCTAssertTrue(beforeFirst !== afterFirst, "Container should display the pushed destination as top controls")
    }
}
