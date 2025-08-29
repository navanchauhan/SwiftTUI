import XCTest
@testable import SwiftTUI

final class TabViewShortcutsTests: XCTestCase {
   func test_TabView_TabSelectHooks_ChangeSelection() throws {
       var sel = 0
       let tv = TabView(titles: ["One", "Two"], selection: Binding(get: { sel }, set: { sel = $0 })) {
           Button("A") {}
           Button("B") {}
       }
       let node = Node(view: VStack(content: tv).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(root.children.first)

       // selection starts at 0
       XCTAssertEqual(sel, 0)
       // Invoke tabSelectNext on the container control
       _ = container.tabSelectNext()
       XCTAssertEqual(sel, 1)
       _ = container.tabSelectPrev()
       XCTAssertEqual(sel, 0)
   }
}
