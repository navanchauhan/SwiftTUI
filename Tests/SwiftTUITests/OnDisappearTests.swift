import XCTest
@testable import SwiftTUI

final class OnDisappearTests: XCTestCase {
   func test_OnDisappear_FiresOnRemoval() throws {
       var fired = false

       func makeView(show: Bool) -> some View {
           VStack {
               Group {
                   if show { Text("Hello") } else { EmptyView() }
               }
               .onDisappear { fired = true }
           }
       }

       let v1 = makeView(show: true)
       let node = Node(view: VStack(content: v1).view)
       node.build()

       // Attach to a window to simulate a real layout tree
       let window = Window()
       let root = try XCTUnwrap(node.control)
       window.addControl(root)

       // Update the node to a view tree without the child
       let v2 = makeView(show: false)
       node.update(using: VStack(content: v2).view)

       // Expect onDisappear closure has fired during removal
       XCTAssertTrue(fired)
   }
}