import XCTest

final class PreviewFileReaderTests: XCTestCase {
    func testTruncationPreservesMultibytePrefix() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("hello中tail".utf8).write(to: url)
        let result = try PreviewFileReader.read(url, limit: 6)
        XCTAssertTrue(result.content.hasPrefix("hello"))
        XCTAssertTrue(result.isTruncated)
        XCTAssertFalse(result.content.contains("Preview truncated"))
        XCTAssertFalse(result.content.contains("Encoding Error"))
    }
    func testTruncationFlagClearsWhenFileFitsAndDoesNotMutateSource() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("```text\nabcdef".utf8).write(to: url)
        let original = try Data(contentsOf: url)
        XCTAssertTrue(try PreviewFileReader.read(url, limit: 10).isTruncated)
        XCTAssertFalse(try PreviewFileReader.read(url, limit: original.count).isTruncated)
        XCTAssertEqual(try Data(contentsOf: url), original)
    }
    func testMalformedUTF8FailsRatherThanSilentlyReplacingBytes() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: url) }
        try Data([0xff, 0x61]).write(to: url)
        XCTAssertThrowsError(try PreviewFileReader.read(url, limit: 100))
    }
    func testLocalImagesHaveBoundedReads() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("huge.png")
        try Data(repeating: 0, count: 33).write(to: url)
        XCTAssertThrowsError(try BoundedFileReader.read(url, maxBytes: 32))
        XCTAssertEqual(try BoundedFileReader.read(url, maxBytes: 33).count, 33)
    }
}
