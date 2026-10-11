import XCTest

final class DocumentContentStateTests: XCTestCase {
    func testExternalRefreshSurvivesSourceAndPreferenceRerenders() {
        var state = DocumentContentState()
        let file = URL(fileURLWithPath: "/tmp/flow.md")
        XCTAssertEqual(state.resolve(modelText: "old", fileURL: file), "old")
        state.receivedDiskText("new", for: file)
        XCTAssertEqual(state.resolve(modelText: "old", fileURL: file), "new")
        XCTAssertEqual(state.resolve(modelText: "old", fileURL: file), "new")
        XCTAssertEqual(state.resolve(modelText: "model edit", fileURL: file), "model edit")
    }
    func testDiskRefreshDoesNotLeakToOtherDocuments() {
        var state = DocumentContentState()
        let first = URL(fileURLWithPath: "/tmp/first.md")
        let second = URL(fileURLWithPath: "/tmp/second.md")
        _ = state.resolve(modelText: "same", fileURL: first)
        state.receivedDiskText("new first", for: first)
        XCTAssertEqual(state.resolve(modelText: "same", fileURL: second), "same")
        state.receivedDiskText("late first", for: first)
        XCTAssertEqual(state.resolve(modelText: "same", fileURL: second), "same")
    }
}
