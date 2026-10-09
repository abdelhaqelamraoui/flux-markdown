import XCTest

final class ContentsSideTests: XCTestCase {
    func testDefaultsValidationAndSharedPersistence() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("preferences.plist")
        let domain = "ContentsSideTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let store = SharedPreferenceStore(fileURL: file)
        let first = AppearancePreference(sharedStore: store, localStore: defaults, migrateFromAppGroup: false)
        XCTAssertEqual(first.contentsSide, .right)
        first.contentsSide = .left
        first.flushSharedPreferences()
        let reloaded = AppearancePreference(sharedStore: SharedPreferenceStore(fileURL: file, alwaysReload: true), localStore: defaults, migrateFromAppGroup: false)
        XCTAssertEqual(reloaded.contentsSide, .left)
        store.set("invalid", forKey: "contentsSide")
        store.synchronize()
        XCTAssertEqual(reloaded.contentsSide, .right)
        XCTAssertEqual(DiagnosticSettings.value("left", key: "contentsSide"), "left")
        XCTAssertEqual(DiagnosticSettings.value("invalid", key: "contentsSide"), "invalid")
    }
}
