import XCTest
@testable import SwiftTUI

final class NavigationIsActiveTests: XCTestCase {
   func test_NavigationLink_IsActive_PushOnTrue() throws {
       var isActive = false

       let view = NavigationStack {
           NavigationLink(isActive: Binding(get: { isActive }, set: { isActive = $0 }),
                          destination: Text("Second")) {
               Text("Go")
           }
       }
       let node = Node(view: VStack(content: view).view)
       node.build()

       let rootControl = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(rootControl.children.first)
       let beforeFirst = container.children.first
       let navNode = try XCTUnwrap(node.children.first)
       XCTAssertEqual(navNode.children.count, 1)

       // Programmatically toggle to true
       isActive = true
       node.update(using: node.view)

       let afterFirst = container.children.first
       XCTAssertEqual(navNode.children.count, 2)
       XCTAssertTrue(beforeFirst !== afterFirst, "Top control should change after isActive=true push")
   }

   func test_NavigationLink_IsActive_PopOnFalse() throws {
       var isActive = false

       let view = NavigationStack {
           NavigationLink(isActive: Binding(get: { isActive }, set: { isActive = $0 }),
                          destination: Text("Second")) {
               Text("Go")
           }
       }
       let node = Node(view: VStack(content: view).view)
       node.build()

       let rootControl = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(rootControl.children.first)
       let navNode = try XCTUnwrap(node.children.first)

       // Push
       isActive = true
       node.update(using: node.view)
       let pushedFirst = container.children.first
       XCTAssertEqual(navNode.children.count, 2)

       // Pop
       isActive = false
       node.update(using: node.view)
       XCTAssertEqual(navNode.children.count, 1)
   }
}