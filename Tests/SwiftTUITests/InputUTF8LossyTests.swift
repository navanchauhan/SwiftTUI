import XCTest
@testable import SwiftTUI

final class InputUTF8LossyTests: XCTestCase {
   func test_InvalidUTF8_ThenArrow_ParserContinues() throws {
       // Invalid byte sequence 0xC3 0x28 followed by ESC [ A (arrow up)
       let invalid: [UInt8] = [0xC3, 0x28]
       let arrowUp = Array("\u{1b}[A".utf8)
       let bytes = invalid + arrowUp

       // Lossy UTF-8 decoding should replace invalid bytes with U+FFFD but keep ESC sequence intact
       let s = String(decoding: bytes, as: UTF8.self)

       var p = ArrowKeyParser()
       for ch in s { _ = p.parse(character: ch) }

       XCTAssertEqual(p.arrowKey, .up, "Arrow parser should still detect the Up key after invalid bytes")
   }
}
