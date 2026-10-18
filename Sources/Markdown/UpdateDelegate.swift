import Cocoa
import Sparkle
import os.log

class UpdateDelegate: NSObject, SPUUpdaterDelegate {
    static let shared = UpdateDelegate()

    private override init() {}

    func updater(_: SPUUpdater, userInitiatedDownload _: Bool) {
        print("⏳ User initiated download, marking update pending...")
        UpdateRestorationManager.shared.markUpdatePending()
    }

    func updater(_: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("⏳ About to install update: \(item.versionString), marking update pending...")
        UpdateRestorationManager.shared.markUpdatePending()
    }

    func updaterDidFinishLoading(_ updater: SPUUpdater, appcastItem: SUAppcastItem) {
    }

    func updater(_: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        print("✅ Found valid update: \(item.versionString)")
    }

    func updater(_: SPUUpdater, didAbortUpdateWithError error: Error, forItem item: SUAppcastItem?) {
        UpdateDiagnostics.shared.record(error: error,
                                        sourceVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                                        targetVersion: item?.displayVersionString)
        os_log("Update aborted: %{public}@", log: OSLog(subsystem: "com.markdownquicklook.app", category: "Updater"),
               type: .error, UpdateDiagnostics.shared.summary())
        UpdateRestorationManager.shared.clearUpdatePending()
    }
}
