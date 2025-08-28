import XCTest
@testable import SwiftTUI

final class OnFocusChangeTests: XCTestCase {
   func test_OnFocusChange_FiresOnEnterAndExit() throws {
       var events: [Bool] = []

       let view = VStack {
           Button("One") {}
           Button("Two") {}
               .onFocusChange { events.append($0) }
       }

       let node = Node(view: VStack(content: view).view)
       node.build()

       // Attach to window to enable focus behavior
       let window = Window()
       let root = try XCTUnwrap(node.control)
       window.addControl(root)

       // Focus should start on the first button (no onFocusChange fire yet)
       XCTAssertEqual(events.count, 0)

       // Find the second button's control via traversal
       let outer = try XCTUnwrap(root.children.first) // VStackControl for our content
       let secondWrapper = try XCTUnwrap(outer.children.dropFirst().first) // our onFocusChange wrapper
       let secondTarget = try XCTUnwrap(secondWrapper.firstSelectableElement)

       // Move focus to second button
       window.firstResponder?.resignFirstResponder()
       window.firstResponder = secondTarget
       secondTarget.becomeFirstResponder()

       // Expect enter event
       XCTAssertEqual(events, [true])

       // Move focus back to first
       let firstTarget = try XCTUnwrap(outer.children.first?.firstSelectableElement)
       window.firstResponder?.resignFirstResponder()
       window.firstResponder = firstTarget
       firstTarget.becomeFirstResponder()

       // Expect exit event appended
       XCTAssertEqual(events, [true, false])
   }
}
