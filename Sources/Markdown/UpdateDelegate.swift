import Cocoa
import Sparkle
import os.log

class UpdateDelegate: NSObject, SPUUpdaterDelegate {
    static let shared = UpdateDelegate()
    private let diagnostics: UpdateDiagnostics
    private(set) var targetVersion: String?
    private let clearPending: () -> Void

    init(diagnostics: UpdateDiagnostics = .shared,
         clearPending: @escaping () -> Void = { UpdateRestorationManager.shared.clearUpdatePending() }) {
        self.diagnostics = diagnostics
        self.clearPending = clearPending
        super.init()
    }

    func updater(_: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        print("⏳ About to install update: \(item.versionString), marking update pending...")
        UpdateRestorationManager.shared.markUpdatePending()
    }

    func updater(_: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        targetVersion = item.displayVersionString
        print("✅ Found valid update: \(item.versionString)")
    }

    func updater(_: SPUUpdater, didAbortWithError error: Error) {
        clearPending()
        let nsError = error as NSError
        // Sparkle reports these normal outcomes through the same callback.
        guard !(nsError.domain == "SUSparkleErrorDomain" && [1001, 4007].contains(nsError.code)) else { return }
        diagnostics.record(error: error,
                                        sourceVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
                                        targetVersion: targetVersion)
        os_log("Update aborted: %{public}@", log: OSLog(subsystem: "com.markdownquicklook.app", category: "Updater"),
               type: .error, diagnostics.summary())
    }

    func updater(_: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        targetVersion = nil
    }
}
