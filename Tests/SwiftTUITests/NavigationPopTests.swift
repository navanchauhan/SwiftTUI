import XCTest
@testable import SwiftTUI

final class NavigationPopTests: XCTestCase {
   private struct PopDestination: View {
       @Environment(\.navigationPop) var pop
       var body: some View {
           VStack(alignment: .leading, spacing: 0) {
               Button("Back") { pop?() }
           }
       }
   }

   func test_NavigationStack_EnvPop_ButtonPops() throws {
       let view = NavigationStack {
           NavigationLink(destination: PopDestination()) { Text("Go") }
       }
       let node = Node(view: VStack(content: view).view)
       node.build()

       let rootControl = try XCTUnwrap(node.control)
       let container = try XCTUnwrap(rootControl.children.first)

       // Initially only root page exists
       let navNode = try XCTUnwrap(node.children.first)
       XCTAssertEqual(navNode.children.count, 1)

       // Activate link to push destination
       let linkButton = try XCTUnwrap(container.children.first)
       linkButton.handleEvent("\n")
       XCTAssertEqual(navNode.children.count, 2)

       // Now top page should contain the Back button; activate it to pop
       let backButton = try XCTUnwrap(container.children.first)
       backButton.handleEvent("\n")

       // Popped back to root
       XCTAssertEqual(navNode.children.count, 1)
   }
}
