import XCTest
@testable import SwiftTUI

final class EnvironmentEarlyAccessTests: XCTestCase {
   private struct EarlyAccessView: View {
       @Environment(\.foregroundColor) var fg
       let captured: Color
       init() {
           // Access @Environment before the view is installed in a Node
           // Should not crash; should return default value.
           self.captured = fg
       }
       var body: some View {
           Text("Hi").foregroundColor(captured)
       }
   }

   func test_EarlyEnvironmentAccess_ReturnsDefault_NoCrash() throws {
       let view = EarlyAccessView()
       // Building should succeed and not crash
       let node = Node(view: VStack(content: view).view)
       node.build()
       // The captured color should be default when accessed early
       XCTAssertEqual(view.captured, .default)
   }
}
