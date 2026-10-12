import XCTest

final class GitHubStarTests: XCTestCase {
    func testBrowserHandoffUsesOnlyThePublicRepositoryURL() {
        var opened: [URL] = []
        XCTAssertTrue(GitHubStar.openRepository { opened.append($0); return true })
        XCTAssertEqual(opened.map(\.absoluteString), ["https://github.com/xykong/flux-markdown"])
        XCTAssertNil(opened.first?.query)
    }
    func testBrowserFailureIsNotReportedAsSuccess() {
        XCTAssertFalse(GitHubStar.openRepository { _ in false })
    }
}
