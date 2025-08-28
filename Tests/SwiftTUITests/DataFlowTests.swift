import XCTest
@testable import SwiftTUI
#if canImport(Combine)
import Combine
#endif

@MainActor
final class DataFlowTests: XCTestCase {

    // Simple observable model for testing
    #if canImport(Combine)
    final class Model: ObservableObject {
        let uid: Int = Int.random(in: 0...Int.max)
        var value: Int
        init(value: Int = 0) { self.value = value }
    }
    #endif

    func test_StateObject_PersistsObjectAcrossUpdate() throws {
        #if canImport(Combine)
        struct MyView: View {
            @StateObject var model = Model(value: 1)
            var body: some View {
                Text("UID: \(model.uid)")
            }
        }

        let node = Node(view: VStack(content: MyView()).view)
        node.build()
        let stack = try XCTUnwrap(node.control)
        let text = try XCTUnwrap(stack.children.first)
        text.layout(size: Size(width: 20, height: 1))
        var initial: [Character] = []
        for i in 0..<10 { // capture "UID: xxxxx"
            initial.append(text.cell(at: Position(column: Extended(i), line: 0))?.char ?? " ")
        }

        node.update(using: node.view)
        text.layout(size: Size(width: 20, height: 1))
        for i in 0..<10 {
            XCTAssertEqual(text.cell(at: Position(column: Extended(i), line: 0))?.char ?? " ", initial[i])
        }
        #else
        throw XCTSkip("Combine not available; skipping @StateObject test")
        #endif
    }

    func test_EnvironmentObject_InjectionAndRead_RendersValue() throws {
        #if canImport(Combine)
        struct EnvView: View {
            @EnvironmentObject var model: Model
            var body: some View { Text("Value: \(model.value)") }
        }

        // Inject a specific model value and verify it renders
        let view = EnvView().environmentObject(Model(value: 42))
        let root = Node(view: VStack(content: view).view)
        root.build()
        let stack = try XCTUnwrap(root.control)
        let text = try XCTUnwrap(stack.children.first)
        text.layout(size: Size(width: 20, height: 1))

        // Expect the substring "Value: 42" in the first line
        let expected: [Character] = Array("Value: 42")
        for (i, ch) in expected.enumerated() {
            XCTAssertEqual(text.cell(at: Position(column: Extended(i), line: 0))?.char, ch)
        }
        #else
        throw XCTSkip("Combine not available; skipping @EnvironmentObject test")
        #endif
    }
}
