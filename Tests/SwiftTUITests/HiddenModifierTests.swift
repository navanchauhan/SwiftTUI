import XCTest
@testable import SwiftTUI

final class HiddenModifierTests: XCTestCase {
   func test_Text_Hidden_PreservesSize_ButDrawsNothing() throws {
       let text = Text("Hello").hidden()
       let node = Node(view: VStack(content: text).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       let needed = control.size(proposedSize: Size(width: 0, height: 1))
       XCTAssertEqual(needed.width.intValue, 5)
       control.layout(size: needed)

       // Should draw nothing
       for col in 0..<needed.width.intValue {
           let c = control.cell(at: Position(column: Extended(col), line: 0))
           XCTAssertNil(c)
       }
   }

   func test_Button_Hidden_IsNotSelectable() throws {
       let button = Button("Go", action: {})
           .hidden()
       let node = Node(view: VStack(content: button).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)

       XCTAssertNil(control.firstSelectableElement)
   }
}
