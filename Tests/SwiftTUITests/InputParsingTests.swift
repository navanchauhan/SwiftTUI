import XCTest
@testable import SwiftTUI

final class InputParsingTests: XCTestCase {
   func test_ArrowKeyParser_ParsesAllDirections() {
       var p = ArrowKeyParser()
       func feed(_ s: String) { for ch in s { _ = p.parse(character: ch) } }

       feed("\u{1b}[A")
       XCTAssertEqual(p.arrowKey, .up)
       p.arrowKey = nil

       feed("\u{1b}[B")
       XCTAssertEqual(p.arrowKey, .down)
       p.arrowKey = nil

       feed("\u{1b}[C")
       XCTAssertEqual(p.arrowKey, .right)
       p.arrowKey = nil

       feed("\u{1b}[D")
       XCTAssertEqual(p.arrowKey, .left)
   }

   func test_SGRMouseParser_PressAndRelease() {
       var p = SGRMouseParser()
       func feed(_ s: String) { for ch in s { _ = p.parse(character: ch) } }

       // Left press at (10,5) 1-based -> (9,4) 0-based
       feed("\u{1b}[<0;10;5M")
       if let e = p.event {
           XCTAssertEqual(e.kind == .press, true)
           XCTAssertEqual(e.button == .left, true)
           XCTAssertEqual(e.column, 9)
           XCTAssertEqual(e.line, 4)
       } else {
           XCTFail("Expected mouse press event")
       }
       p.event = nil

       // Left release at (10,5)
       feed("\u{1b}[<0;10;5m")
       if let e = p.event {
           XCTAssertEqual(e.kind == .release, true)
           XCTAssertEqual(e.button == .left, true)
           XCTAssertEqual(e.column, 9)
           XCTAssertEqual(e.line, 4)
       } else {
           XCTFail("Expected mouse release event")
       }
   }
}
