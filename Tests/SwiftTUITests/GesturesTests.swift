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

  func test_OnTapGesture_Count2_DoubleEnterRequired() throws {
      var fired = false
      let view = Text("Tap").onTapGesture(count: 2) { fired = true }

      let node = Node(view: VStack(content: view).view)
      node.build()
      let stack = try XCTUnwrap(node.control)
      let tapWrapper = try XCTUnwrap(stack.children.first)

      // First enter: should not fire yet
      tapWrapper.handleEvent("\n")
      XCTAssertFalse(fired)
      // Second enter quickly: should fire
      tapWrapper.handleEvent("\n")
      XCTAssertTrue(fired)
  }

  func test_OnTapGesture_Count2_SlowSecondTap_DoesNotTrigger() throws {
       var fired = false
       let view = Text("Tap").onTapGesture(count: 2) { fired = true }

       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let tapWrapper = try XCTUnwrap(stack.children.first)

       // First enter: should not fire yet
       tapWrapper.handleEvent("\n")
       XCTAssertFalse(fired)
       // Wait longer than detection window (0.35s)
       usleep(400_000)
       // Second enter after delay: should reset accumulator, still not fire
       tapWrapper.handleEvent("\n")
       XCTAssertFalse(fired)
       // A quick second enter now should complete the double-tap
       tapWrapper.handleEvent("\n")
       XCTAssertTrue(fired)
  }
}
