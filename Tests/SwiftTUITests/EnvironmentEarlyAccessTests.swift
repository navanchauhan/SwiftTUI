import XCTest
@testable import SwiftTUI

final class EnvironmentEarlyAccessTests: XCTestCase {
   func test_EnvironmentWrappedValue_NoNode_Default() throws {
       // Construct a standalone Environment wrapper; node is nil.
       var env = Environment(\.foregroundColor)
       // Accessing wrappedValue should not crash and should return the default.
       let value = env.wrappedValue
       XCTAssertEqual(value, .default)
   }
}