import XCTest
import WebKit

private final class ImageTask: NSObject, WKURLSchemeTask {
    let request: URLRequest
    var callbacks = 0
    var error: Error?
    var finished: (() -> Void)?
    init(_ url: URL) { request = URLRequest(url: url) }
    func didReceive(_ response: URLResponse) { callbacks += 1 }
    func didReceive(_ data: Data) { callbacks += 1 }
    func didFinish() { callbacks += 1; finished?() }
    func didFailWithError(_ error: Error) { self.error = error; callbacks += 1; finished?() }
}

final class LocalResourceBudgetTests: XCTestCase {
    func testCancelledTaskReceivesNoCallbacks() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let image = directory.appendingPathComponent("image.png")
        try Data([1]).write(to: image)
        let handler = LocalSchemeHandler()
        handler.baseDirectory = directory
        handler.allowedFileURLs = [image]
        let task = ImageTask(URL(string: "local-md://\(image.path)")!)
        let webView = WKWebView()
        handler.webView(webView, start: task)
        handler.webView(webView, stop: task)
        let settled = expectation(description: "queue drained")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { settled.fulfill() }
        wait(for: [settled], timeout: 2)
        XCTAssertEqual(task.callbacks, 0)
    }
    func testOversizedSchemeReadFails() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let image = directory.appendingPathComponent("image.png")
        try Data(repeating: 0, count: 2 * 1024 * 1024 + 1).write(to: image)
        let handler = LocalSchemeHandler()
        handler.baseDirectory = directory
        handler.allowedFileURLs = [image]
        let task = ImageTask(URL(string: "local-md://\(image.path)")!)
        let failed = expectation(description: "rejected")
        task.finished = { failed.fulfill() }
        handler.webView(WKWebView(), start: task)
        wait(for: [failed], timeout: 2)
        XCTAssertNotNil(task.error)
        XCTAssertEqual(task.callbacks, 1)
    }
}
