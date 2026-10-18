import AppKit

/// A browser handoff, not an authenticated GitHub starring operation.
enum GitHubStar {
    static let didOpenRepository = Notification.Name("FluxMarkdown.GitHubRepositoryOpened")
    static let repository = URL(string: "https://github.com/xykong/flux-markdown")!

    @discardableResult
    static func openRepository(using open: (URL) -> Bool = { NSWorkspace.shared.open($0) }) -> Bool {
        let success = open(repository)
        if success { NotificationCenter.default.post(name: didOpenRepository, object: nil) }
        return success
    }

    static func showRepository() {
        guard !openRepository() else { return }
        ErrorFeedback.present(ErrorFeedback.capture(.browser), recoveryTitle: "Copy Link", recovery: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(repository.absoluteString, forType: .string)
        })
        return
    }
}
