import XCTest

final class QuickLookRegistrationTests: XCTestCase {
    func testRegistrationFailureIsReportedAndEditorStateIsRestored() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let app = directory.appendingPathComponent("FluxMarkdown.app")
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents/PlugIns/MarkdownPreview.appex"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let editors = ["net.daringfireball.markdown":"com.microsoft.VSCode"]
        var restored: [String:String] = [:], calls: [String] = []
        let result = QuickLookRegistration.repair(appURL: app, editors: editors, order: [], runner: { executable, args in
            calls.append(executable)
            return RegistrationCommandResult(status: args.first == "-a" ? 9 : 0, output: "")
        }, restore: { restored = $0; return [] })
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(result.errors, ["extension-add:9"])
        XCTAssertEqual(restored, editors)
        XCTAssertFalse(calls.contains("/usr/bin/defaults"))
    }

    func testOnlyKnownSpotlightErrorIsToleratedAndOrderPreservesOtherProviders() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let app = directory.appendingPathComponent("FluxMarkdown.app")
        try FileManager.default.createDirectory(at: app.appendingPathComponent("Contents/PlugIns/MarkdownPreview.appex"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        var arguments: [[String]] = []
        let result = QuickLookRegistration.repair(appURL: app, editors: [:], order: ["com.example.Other",QuickLookRegistration.identifier], runner: { executable, args in
            arguments.append(args)
            return executable.hasSuffix("lsregister") ? RegistrationCommandResult(status: 1, output: "scan failed (-10822)") : RegistrationCommandResult(status: 0, output: "")
        }, restore: { _ in [] })
        XCTAssertTrue(result.succeeded)
        XCTAssertEqual(result.warnings, ["launchservices-spotlight-scan"])
        let order = try XCTUnwrap(arguments.first { $0.contains("displayOrder") })
        XCTAssertEqual(Array(order.suffix(2)), [QuickLookRegistration.identifier,"com.example.Other"])
        XCTAssertTrue(arguments.contains(["-e","use","-i",QuickLookRegistration.identifier]))
    }

    func testMalformedEditorStateIsRejectedBeforeCommands() {
        XCTAssertFalse(QuickLookRegistration.validEditorState(["arbitrary":"com.example.Editor"]))
        XCTAssertFalse(QuickLookRegistration.validEditorState(["net.daringfireball.markdown":"/Users/private/file"]))
        XCTAssertTrue(QuickLookRegistration.validEditorState(["net.daringfireball.markdown":"com.microsoft.VSCode"]))
    }
    func testUnchangedEditorHandlersDoNotRequireUnsupportedAliasWrites() {
        var writes = 0
        let errors = QuickLookRegistration.restoreEditors(["public.markdown":"com.microsoft.Word"],
            current: { _ in "com.microsoft.Word" }, set: { _, _ in writes += 1; return -50 })
        XCTAssertTrue(errors.isEmpty)
        XCTAssertEqual(writes, 0)
    }

    func testSuccessfulReturnCodeDoesNotHideAnUnappliedEditorChange() {
        let errors = QuickLookRegistration.restoreEditors(["net.daringfireball.markdown":"com.microsoft.VSCode"],
            current: { _ in "com.xykong.Markdown" }, set: { _, _ in 0 })
        XCTAssertEqual(errors, ["editor-restore-unconfirmed"])
    }

    func testInstallerSnapshotPreservesExplicitSelfDuringTemporaryRemoval() {
        let handlers: [[String: Any]] = [["LSHandlerContentType": "net.daringfireball.markdown", "LSHandlerRoleAll": "com.xykong.markdown"]]
        let state = QuickLookRegistration.editorState(current: { type in
            type == "net.daringfireball.markdown" ? "com.apple.dt.Xcode" : "com.microsoft.Word"
        }, handlers: handlers)
        XCTAssertEqual(state["net.daringfireball.markdown"], "com.xykong.Markdown")
        XCTAssertEqual(state["public.markdown"], "com.microsoft.Word")
    }

    func testSnapshotDoesNotOverrideOtherEditorsOrConflictingSpecificRoles() {
        for handlers: [[String: Any]] in [
            [["LSHandlerContentType": "net.daringfireball.markdown", "LSHandlerRoleAll": "com.microsoft.VSCode"]],
            [["LSHandlerContentType": "net.daringfireball.markdown", "LSHandlerRoleAll": "com.xykong.Markdown", "LSHandlerRoleViewer": "com.microsoft.VSCode"]],
            []
        ] {
            let state = QuickLookRegistration.editorState(current: { _ in "com.microsoft.VSCode" }, handlers: handlers)
            XCTAssertEqual(state["net.daringfireball.markdown"], "com.microsoft.VSCode")
        }
    }

}
