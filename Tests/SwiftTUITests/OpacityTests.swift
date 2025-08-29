import XCTest
@testable import SwiftTUI

final class OpacityTests: XCTestCase {
   func test_Text_Opacity_FaintApplied_WhenLessThanOne() throws {
       let view = Text("Hi").opacity(0.5)
       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 2, height: 1))

       let c0 = control.cell(at: Position(column: 0, line: 0))
       XCTAssertEqual(c0?.char, "H")
       XCTAssertTrue(c0?.attributes.faint == true)
   }

   func test_Text_Opacity_NoFaint_WhenOneOrMore() throws {
       let view = Text("X").opacity(1.0)
       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 1, height: 1))

       let c0 = control.cell(at: Position(column: 0, line: 0))
       XCTAssertEqual(c0?.char, "X")
       XCTAssertFalse(c0?.attributes.faint == true)
   }

   func test_Text_Opacity_Zero_TreatedAsFaint() throws {
       let view = Text("Z").opacity(0.0)
       let node = Node(view: VStack(content: view).view)
       node.build()
       let stack = try XCTUnwrap(node.control)
       let control = try XCTUnwrap(stack.children.first)
       control.layout(size: Size(width: 1, height: 1))

       let c0 = control.cell(at: Position(column: 0, line: 0))
       XCTAssertEqual(c0?.char, "Z")
       XCTAssertTrue(c0?.attributes.faint == true)
   }
}
