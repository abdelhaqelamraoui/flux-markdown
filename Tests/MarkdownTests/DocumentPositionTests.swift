import XCTest

final class DocumentPositionTests: XCTestCase {
    func testSearchHandoffIsEncodedAndExplicit() throws {
        let file = URL(fileURLWithPath: "/tmp/中文 note & test.md")
        let url = try XCTUnwrap(DocumentOpenRequest.searchURL(for: file))
        let request = try XCTUnwrap(DocumentOpenRequest(url: url))
        XCTAssertEqual(request.fileURL, file)
        XCTAssertTrue(request.wantsSearch)
        for flag in ["", "0", "true", "1&find=1"] {
            let request = try XCTUnwrap(DocumentOpenRequest(url: URL(string: "markdownpreview://open?path=/tmp/a.md&find=\(flag)")!))
            XCTAssertFalse(request.wantsSearch)
        }
        XCTAssertNil(DocumentOpenRequest.searchURL(for: URL(string: "https://example.com/a.md")!))
    }
    func testURLTargetPrecedenceValidationAndEncodedPath() throws {
        let request = try XCTUnwrap(DocumentOpenRequest(url: URL(string: "markdownpreview://open?path=%2Ftmp%2F%E4%B8%AD%E6%96%87%20note.md&line=213#heading")!))
        XCTAssertEqual(request.fileURL.path, "/tmp/中文 note.md")
        XCTAssertEqual(request.position, .line(213))
        for value in ["0", "-1", "1.5", "abc", "999999999999999999999999999", "1%3Balert(1)"] {
            let item = try XCTUnwrap(DocumentOpenRequest(url: URL(string: "markdownpreview://open?path=/tmp/file.md&line=\(value)#heading")!))
            XCTAssertEqual(item.position, .anchor("heading"))
        }
        XCTAssertEqual(DocumentOpenRequest(url: URL(string: "markdownpreview://open?path=/tmp/a.md&line=1&line=2")!)?.position, nil)
        XCTAssertNil(DocumentOpenRequest(url: URL(string: "https://example.com?path=/tmp/a.md")!))
        XCTAssertNil(DocumentOpenRequest(url: URL(string: "markdownpreview://open?path=relative.md")!))
    }

    func testRequestsArePerFileLatestWinsAndConsumeOnce() {
        let store = DocumentPositionStore()
        let a = URL(fileURLWithPath: "/tmp/a.md"), b = URL(fileURLWithPath: "/tmp/b.md")
        store.set(.line(1), for: a)
        let stale = store.set(.line(2), for: a)
        store.set(.anchor("section"), for: a)
        store.discard(for: a, id: stale)
        store.set(.line(10), for: b)
        XCTAssertEqual(store.consume(for: a), .anchor("section"))
        XCTAssertNil(store.consume(for: a))
        XCTAssertEqual(store.consume(for: b), .line(10))
    }

    func testPositionEncodingDoesNotGenerateExecutableUserInput() throws {
        let target = DocumentPosition.anchor("\";alert(1);//")
        let encoded = try JSONSerialization.data(withJSONObject: target.arguments)
        let object = try JSONSerialization.jsonObject(with: encoded) as! [String: String]
        XCTAssertEqual(object["anchor"], "\";alert(1);//")
    }
}
