import XCTest
@testable import SwiftTUI

final class TabViewGlobalShortcutsTests: XCTestCase {
   func test_TabView_GlobalShortcuts_BubbleFromContent() throws {
       var selection: Int = 0
       let view = TabView(titles: ["One", "Two"], selection: Binding(get: { selection }, set: { selection = $0 })) {
           // Simple content views for each tab
           Text("First")
           Text("Second")
       }

       // Build the view graph
       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let tabContainer = try XCTUnwrap(root.children.first, "Expected TabView container as first child")

       // Sanity: selection starts at 0
       XCTAssertEqual(selection, 0)

       // The TabViewControl adds tab buttons first, then installs selected content as the last child.
       // Start bubbling from the content control (last child) to simulate Application's parent traversal.
       let contentControl = try XCTUnwrap(tabContainer.children.last, "Expected content control installed as last child")

       // Bubble tabSelectNext up the ancestor chain
       var handled = false
       var walker: Control? = contentControl
       while let c = walker, handled == false {
           handled = c.tabSelectNext()
           walker = c.parent
       }
       XCTAssertTrue(handled, "Expected a TabView ancestor to handle tabSelectNext")
       XCTAssertEqual(selection, 1, "Expected selection to advance to the next tab")

       // After selection changed, refresh the content control reference (the previously
       // selected content was detached). Bubble tabSelectPrev up the ancestor chain.
       let currentContent = try XCTUnwrap(tabContainer.children.last, "Expected updated content control after selection change")
       handled = false
       walker = currentContent
       while let c = walker, handled == false {
           handled = c.tabSelectPrev()
           walker = c.parent
       }
       XCTAssertTrue(handled, "Expected a TabView ancestor to handle tabSelectPrev")
       XCTAssertEqual(selection, 0, "Expected selection to move back to previous tab")
   }
}