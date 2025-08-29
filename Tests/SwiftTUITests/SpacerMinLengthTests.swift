import XCTest
@testable import SwiftTUI

final class SpacerMinLengthTests: XCTestCase {
   func test_VStack_SpacerMinLength_Respected() throws {
       let view = VStack(alignment: .leading, spacing: 0) {
           Text("Top")
           Spacer(minLength: 2)
           Text("Bottom")
       }
       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(root.children.first)

       // Layout a 4-line tall area: expect spacer to take at least 2 lines
       container.layout(size: Size(width: 10, height: 4))

       // Children order matches content order: [Top, Spacer, Bottom]
       let top = try XCTUnwrap(container.children[safe: 0])
       let spacer = try XCTUnwrap(container.children[safe: 1])
       let bottom = try XCTUnwrap(container.children[safe: 2])

       XCTAssertEqual(top.layer.frame.size.height.intValue, 1)
       XCTAssertGreaterThanOrEqual(spacer.layer.frame.size.height.intValue, 2)
       XCTAssertEqual(bottom.layer.frame.size.height.intValue, 1)
       // Sum should be 4
       XCTAssertEqual(top.layer.frame.size.height + spacer.layer.frame.size.height + bottom.layer.frame.size.height, Extended(4))
   }

   func test_HStack_SpacerMinLength_Respected() throws {
       let view = HStack(spacing: 0) {
           Text("L")
           Spacer(minLength: 3)
           Text("R")
       }
       let node = Node(view: VStack(content: view).view)
       node.build()
       let root = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(root.children.first)

       // Layout a 5-column wide area
       container.layout(size: Size(width: 5, height: 1))
       let left = try XCTUnwrap(container.children[safe: 0])
       let spacer = try XCTUnwrap(container.children[safe: 1])
       let right = try XCTUnwrap(container.children[safe: 2])

       XCTAssertEqual(left.layer.frame.size.width.intValue, 1)
       XCTAssertGreaterThanOrEqual(spacer.layer.frame.size.width.intValue, 3)
       XCTAssertEqual(right.layer.frame.size.width.intValue, 1)
       XCTAssertEqual(left.layer.frame.size.width + spacer.layer.frame.size.width + right.layer.frame.size.width, Extended(5))
   }
}

// Helper to avoid out-of-bounds
fileprivate extension Array {
   subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
