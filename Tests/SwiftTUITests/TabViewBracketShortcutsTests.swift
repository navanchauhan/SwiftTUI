import XCTest
@testable import SwiftTUI

final class TabViewBracketShortcutsTests: XCTestCase {
   func test_TabView_Container_HandleEvent_Brackets_ChangeSelection() throws {
       var selection: Int = 0
       let view = TabView(titles: ["One", "Two", "Three"], selection: Binding(get: { selection }, set: { selection = $0 })) {
           Text("First")
           Text("Second")
           Text("Third")
       }
       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let tabContainer = try XCTUnwrap(root.children.first)

       XCTAssertEqual(selection, 0)
       // Simulate pressing ']' on the container to go next
       tabContainer.handleEvent("]")
       XCTAssertEqual(selection, 1)
       // Simulate pressing '[' on the container to go prev
       tabContainer.handleEvent("[")
       XCTAssertEqual(selection, 0)
   }
}
