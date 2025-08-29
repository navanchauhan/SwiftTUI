import XCTest
@testable import SwiftTUI

final class OnChangeTests: XCTestCase {
 func test_OnChange_FiresOnValueChangeOnly() throws {
     var observed: [Int] = []

     func makeView(_ n: Int) -> some View {
         VStack {
             Text("X").onChange(of: n) { observed.append($0) }
         }
     }

     var root = makeView(0)
     let node = Node(view: root.view)
     node.build()

     // Initial build does not fire
     XCTAssertEqual(observed, [])

     // Update with same value -> no fire
     root = makeView(0)
     node.update(using: root.view)
     XCTAssertEqual(observed, [])

     // Change to 1 -> fire once with 1
     root = makeView(1)
     node.update(using: root.view)
     XCTAssertEqual(observed, [1])

     // Same again -> no additional fire
     root = makeView(1)
     node.update(using: root.view)
     XCTAssertEqual(observed, [1])

     // Change to 2 -> fire with 2
     root = makeView(2)
     node.update(using: root.view)
     XCTAssertEqual(observed, [1, 2])
 }
}
