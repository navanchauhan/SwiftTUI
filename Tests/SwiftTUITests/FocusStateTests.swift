import XCTest
@testable import SwiftTUI

final class FocusStateTests: XCTestCase {
   func test_FocusedBool_ProgrammaticFocus() throws {
       var isSecondFocused = true

       let view = VStack {
           Button("One") {}
           Button("Two") {}
               .focused(Binding(get: { isSecondFocused }, set: { isSecondFocused = $0 }))
       }

       let node = Node(view: VStack(content: view).view)
       node.build()

       // Attach to window to enable focus operations
       let window = Window()
       let rootControl = try XCTUnwrap(node.control)
       window.addControl(rootControl)

       // Trigger update to apply programmatic focus
       node.update(using: node.view)

       // Expect the focused control to be the second button (descendant of wrapper)
       let outer = try XCTUnwrap(rootControl)
       let inner = try XCTUnwrap(outer.children.first)
       let secondWrapper = try XCTUnwrap(inner.children.dropFirst().first)
       let target = try XCTUnwrap(secondWrapper.firstSelectableElement)
       XCTAssertTrue(window.firstResponder === target || window.firstResponder?.isDescendant(of: target) == true)
   }

   func test_FocusedBool_ClearFocus() throws {
       var isSecondFocused = true

       let view = VStack {
           Button("One") {}
           Button("Two") {}
               .focused(Binding(get: { isSecondFocused }, set: { isSecondFocused = $0 }))
       }

       let node = Node(view: VStack(content: view).view)
       node.build()
       let window = Window()
       let rootControl = try XCTUnwrap(node.control)
       window.addControl(rootControl)

       // Initial focus to second
       node.update(using: node.view)
       XCTAssertNotNil(window.firstResponder)

       // Now programmatically clear focus
       isSecondFocused = false
       node.update(using: node.view)
       XCTAssertNil(window.firstResponder, "Expected focus to clear when binding set to false")
   }

   enum Field: Equatable { case one, two }

   func test_FocusedEquals_BindsValueAndRequestsFocus() throws {
       var focused: Field? = .two

       let view = VStack {
           Button("One") {}
               .focused(Binding(get: { focused }, set: { focused = $0 }), equals: .one)
           Button("Two") {}
               .focused(Binding(get: { focused }, set: { focused = $0 }), equals: .two)
       }

       let node = Node(view: VStack(content: view).view)
       node.build()
       let window = Window()
       let rootControl = try XCTUnwrap(node.control)
       window.addControl(rootControl)

       // Programmatic focus to .two
       node.update(using: node.view)
       let outer = try XCTUnwrap(rootControl)
       let inner = try XCTUnwrap(outer.children.first)
       let secondWrapper = try XCTUnwrap(inner.children.dropFirst().first)
       let secondTarget = try XCTUnwrap(secondWrapper.firstSelectableElement)
       XCTAssertTrue(window.firstResponder === secondTarget || window.firstResponder?.isDescendant(of: secondTarget) == true)

       // Simulate user moving focus to first
       let firstWrapper = try XCTUnwrap(inner.children.first)
       let firstTarget = try XCTUnwrap(firstWrapper.firstSelectableElement)
       window.firstResponder?.resignFirstResponder()
       window.firstResponder = firstTarget
       firstTarget.becomeFirstResponder()

       // Binding should now reflect .one
       XCTAssertEqual(focused, .one)
   }
}
