import XCTest

final class QuickLookDiagnosticScriptTests: XCTestCase {
    func testCollectorDoesNotExposePathsOrMalformedMetadataAndDoesNotModifyBundle() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let app = directory.appendingPathComponent("private-person-private-doc.app")
        let contents = app.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
        let info = contents.appendingPathComponent("Info.plist")
        let metadata: [String: Any] = ["CFBundleShortVersionString": "/Users/private-person/private-doc.md", "CFBundleVersion": "475"]
        let bytes = try PropertyListSerialization.data(fromPropertyList: metadata, format: .xml, options: 0)
        try bytes.write(to: info)
        let root = URL(fileURLWithPath: #file).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [root.appendingPathComponent("scripts/diagnose-quicklook.sh").path, "--app", app.path]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self)
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertTrue(output.contains("app_version=invalid"))
        XCTAssertTrue(output.contains("selected_preview_provider=unknown"))
        XCTAssertFalse(output.contains("private-person"))
        XCTAssertFalse(output.contains(app.path))
        XCTAssertEqual(try Data(contentsOf: info), bytes)
    }
}
