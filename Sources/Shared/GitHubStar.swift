import AppKit

/// A browser handoff, not an authenticated GitHub starring operation.
enum GitHubStar {
    static let repository = URL(string: "https://github.com/xykong/flux-markdown")!

    @discardableResult
    static func openRepository(using open: (URL) -> Bool = { NSWorkspace.shared.open($0) }) -> Bool {
        open(repository)
    }

    static func showRepository() {
        guard !openRepository() else { return }
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Could not open GitHub", comment: "GitHub support browser error")
        alert.informativeText = repository.absoluteString
        alert.addButton(withTitle: NSLocalizedString("Copy Link", comment: "Copy support URL"))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: "Cancel"))
        if alert.runModal() == .alertFirstButtonReturn {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(repository.absoluteString, forType: .string)
        }
    }
}
