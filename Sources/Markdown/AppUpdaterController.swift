import Cocoa
import Sparkle
import Combine

/// Uses Sparkle's normal UI except for actionable, app-localized error recovery.
final class UpdateErrorUserDriver: SPUStandardUserDriver {
    static let downloadURL = URL(string: "https://github.com/xykong/flux-markdown/releases/latest")!
    private let presentAlert: (NSAlert) -> NSApplication.ModalResponse
    private let openURL: (URL) -> Bool
    private let reportIncident: (IncidentDraft) -> Void

    init(hostBundle: Bundle = .main,
         presentAlert: @escaping (NSAlert) -> NSApplication.ModalResponse = { $0.runModal() },
         openURL: @escaping (URL) -> Bool = { NSWorkspace.shared.open($0) },
         reportIncident: @escaping (IncidentDraft) -> Void = { ErrorFeedback.report($0) }) {
        self.presentAlert = presentAlert
        self.openURL = openURL
        self.reportIncident = reportIncident
        super.init(hostBundle: hostBundle, delegate: nil)
    }

    override func showUpdaterError(_ error: Error, acknowledgement: @escaping () -> Void) {
        // Close Sparkle's checking/progress windows before presenting recovery.
        dismissUpdateInstallation()
        let draft = IncidentDraft(ErrorFeedback.capture(.update, error: error, targetVersion: UpdateDelegate.shared.targetVersion))
        var shouldReport = false
        defer { acknowledgement(); if shouldReport { reportIncident(draft) } }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = NSLocalizedString("Could Not Update FluxMarkdown", comment: "Update failure title")
        alert.informativeText = ErrorFeedback.text(FailureKind.update.guidance)
        alert.addButton(withTitle: NSLocalizedString("Download Latest Version", comment: "Open official download page"))
        alert.addButton(withTitle: ErrorFeedback.text("Report This Problem"))
        alert.addButton(withTitle: NSLocalizedString("Close", comment: "Close recovery window"))
        let controls = IncidentFeedbackControls(draft: draft)
        controls.addArrangedSubview(ErrorActionButton(title: ErrorFeedback.text("How to Install…")) {
            let help = NSAlert()
            help.messageText = ErrorFeedback.text("How to Install…")
            help.informativeText = ErrorFeedback.text("Download and open FluxMarkdown.dmg, quit FluxMarkdown, then drag the app into Applications and choose Replace.")
            help.runModal()
        })
        controls.frame.size.height = 120
        alert.accessoryView = controls
        let response = presentAlert(alert)
        if response == .alertSecondButtonReturn { shouldReport = true }
        if response == .alertFirstButtonReturn, !openURL(Self.downloadURL) {
            let fallback = NSAlert()
            fallback.messageText = NSLocalizedString("Could Not Open Download Page", comment: "Browser launch failure")
            fallback.informativeText = NSLocalizedString("Copy the download link and paste it into your browser to download the latest version.", comment: "Manual browser fallback")
            fallback.accessoryView = downloadAddress()
            fallback.addButton(withTitle: NSLocalizedString("Copy Download Link", comment: "Copy official download address"))
            fallback.addButton(withTitle: NSLocalizedString("Close", comment: "Close recovery window"))
            if presentAlert(fallback) == .alertFirstButtonReturn {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(Self.downloadURL.absoluteString, forType: .string)
            }
        }
    }

    private func downloadAddress() -> NSTextField {
        let field = NSTextField(wrappingLabelWithString: Self.downloadURL.absoluteString)
        field.isSelectable = true
        field.frame = NSRect(x: 0, y: 0, width: 420, height: 40)
        return field
    }
}

final class AppUpdaterController: ObservableObject {
    let updater: SPUUpdater
    @Published private(set) var canCheckForUpdates = false
    private var checkObservation: NSKeyValueObservation?

    init() {
        let driver = UpdateErrorUserDriver()
        updater = SPUUpdater(hostBundle: .main, applicationBundle: .main,
                             userDriver: driver, delegate: UpdateDelegate.shared)
        checkObservation = updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] updater, _ in
            self?.canCheckForUpdates = updater.canCheckForUpdates
        }
        do {
            try updater.start()
        } catch {
            // Let application startup finish before showing a configuration failure.
            DispatchQueue.main.async { driver.showUpdaterError(error, acknowledgement: {}) }
        }
    }

    func checkForUpdates() { updater.checkForUpdates() }
}
