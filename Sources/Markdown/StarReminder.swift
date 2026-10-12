import SwiftUI
import WebKit
import os.log

/// All main-app windows share one serialized state and one visible invitation.
final class StarReminderStore: ObservableObject {
    static let shared = StarReminderStore()
    static let key = "starReminderState.v1"
    @Published private(set) var state: StarReminderState
    @Published var owner: UUID?
    private let defaults: UserDefaults
    private var readingDate: Date?
    private var readingSeconds: TimeInterval = 0
    private var observer: NSObjectProtocol?

    init(defaults: UserDefaults = .standard, now: Date = Date()) {
        self.defaults = defaults
        state = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(StarReminderState.self, from: $0) }
            ?? StarReminderState(firstSeen: now)
        save()
        observer = NotificationCenter.default.addObserver(forName: GitHubStar.didOpenRepository,
            object: nil, queue: .main) { [weak self] _ in self?.stop(.supportLinkOpened) }
    }
    deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    private func save() { if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: Self.key) } }
    var enabled: Bool { state.stopReason == nil }
    func setEnabled(_ enabled: Bool) {
        guard enabled != self.enabled else { return }
        if enabled { state.reenable(at: Date()); save() } else { stop(.optedOut) }
    }
    func stop(_ reason: StarReminderState.StopReason) {
        state.stopReason = reason; owner = nil; save()
    }
    func recordReading(seconds: TimeInterval, now: Date) {
        let date = Calendar.current.startOfDay(for: now)
        if readingDate != date { readingDate = date; readingSeconds = 0 }
        readingSeconds += seconds
        if readingSeconds >= 30, state.lastReadingDate.map({ date > $0 }) ?? true {
            state.recordReading(at: now); save()
        }
    }
    func claim(_ id: UUID, now: Date) -> Bool {
        guard owner == nil, state.isEligible(at: now) else { return false }
        state.recordDisplay(at: now); save(); owner = id
        os_log("Star invitation displayed", log: .default, type: .info)
        return true
    }
    func dismiss(_ id: UUID) { if owner == id { owner = nil } }
}

/// One opportunity per opened document; long-running reading never triggers a late invitation.
final class StarReminderSession: ObservableObject {
    let id = UUID()
    private weak var webView: WKWebView?
    private var timer: Timer?
    private var lastTick = ProcessInfo.processInfo.systemUptime
    private var stableSeconds: TimeInterval = 0
    private var attempted = false
    private var probing = false
    private var generation = 0
    private var documentURL: URL?
    private var ready = false
    var preview = true

    func attach(_ webView: WKWebView, url: URL?, preview: Bool) {
        self.webView = webView
        self.preview = preview
        if url != documentURL {
            documentURL = url; generation += 1; ready = false; attempted = false; stableSeconds = 0
            StarReminderStore.shared.dismiss(id)
        }
        if !preview { attempted = true }
        if timer == nil {
            lastTick = ProcessInfo.processInfo.systemUptime
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.tick() }
        }
    }
    func rendering() { ready = false; generation += 1 }
    func rendered() { ready = true }
    func cancelOpportunity() { attempted = true; generation += 1 }
    func invalidate() { generation += 1; timer?.invalidate(); timer = nil; StarReminderStore.shared.dismiss(id) }
    deinit { timer?.invalidate() }

    private func foreground() -> Bool {
        guard let window = webView?.window else { return false }
        return NSApp.isActive && window.isKeyWindow && window.isVisible && !window.isMiniaturized
            && window.occlusionState.contains(.visible) && window.attachedSheet == nil && NSApp.modalWindow == nil
    }
    private func tick() {
        let uptime = ProcessInfo.processInfo.systemUptime
        let delta = uptime - lastTick; lastTick = uptime
        guard ready, preview, documentURL != nil, foreground(), delta > 0, delta < 2.5 else {
            stableSeconds = 0; return
        }
        StarReminderStore.shared.recordReading(seconds: delta, now: Date())
        guard !attempted, !probing else { return }
        stableSeconds += delta
        guard stableSeconds >= 30, let webView else { return }
        attempted = true; probing = true
        let version = generation
        // Read only renderer-owned UI state; never store selected text or document content.
        webView.evaluateJavaScript("""
        (() => {
          const search = document.getElementById('search-container');
          return !window.getSelection()?.toString().length &&
            !(search && getComputedStyle(search).display !== 'none') &&
            !document.querySelector('.help-overlay-visible') &&
            !document.activeElement?.matches('input, textarea, [contenteditable="true"]');
        })()
        """) { [weak self] result, error in
            guard let self else { return }
            self.probing = false
            guard version == self.generation, error == nil, result as? Bool == true,
                  self.ready, self.preview, self.foreground() else { return }
            _ = StarReminderStore.shared.claim(self.id, now: Date())
        }
    }
}

private final class ReminderNativeButton: NSButton {
    var perform: (() -> Void)?
    var dismiss: (() -> Void)?
    @objc func invoke() { perform?() }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { dismiss?() } else { super.keyDown(with: event) }
    }
}

private struct ReminderButton: NSViewRepresentable {
    let title: String
    var primary = false
    var close = false
    let dismiss: () -> Void
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    func makeNSView(context: Context) -> ReminderNativeButton {
        let button = ReminderNativeButton()
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.target = button; button.action = #selector(ReminderNativeButton.invoke)
        return button
    }
    func updateNSView(_ button: ReminderNativeButton, context: Context) {
        button.title = close ? "" : title
        button.setAccessibilityLabel(title)
        button.toolTip = title
        button.image = (primary || close) ? NSImage(systemSymbolName: close ? "xmark" : "star", accessibilityDescription: nil) : nil
        button.imagePosition = close ? .imageOnly : .imageLeading
        button.isBordered = !close
        button.contentTintColor = primary ? .controlAccentColor : .labelColor
        button.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
        button.perform = action; button.dismiss = dismiss
    }
}

struct StarReminderCard: View {
    let session: StarReminderSession
    @ObservedObject private var store = StarReminderStore.shared
    @State private var failed = false
    private func text(_ key: String) -> String { NSLocalizedString(key, comment: "GitHub Star reminder") }
    private var columnWidth: CGFloat {
        ["Star on GitHub", "Remind Me Later", "Don't Remind Me", "I've Already Starred"].map {
            (text($0) as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: 13)]).width + 48
        }.max() ?? 180
    }
    private func dismiss() { store.dismiss(session.id) }
    var body: some View {
        if store.owner == session.id {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(text("Enjoying FluxMarkdown?")).font(.headline)
                    Spacer()
                    ReminderButton(title: text("Remind Me Later"), close: true, dismiss: dismiss, action: dismiss)
                        .frame(width: 24, height: 24)
                }
                Text(text("If FluxMarkdown makes reading easier, give it a Star on GitHub to support development."))
                    .font(.callout).foregroundColor(.secondary).fixedSize(horizontal: false, vertical: true)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: columnWidth), alignment: .leading)], alignment: .leading, spacing: 8) {
                    ReminderButton(title: text("Star on GitHub"), primary: true, dismiss: dismiss) {
                        failed = !GitHubStar.openRepository()
                    }.frame(height: 28)
                    ReminderButton(title: text("Remind Me Later"), dismiss: dismiss, action: dismiss).frame(height: 28)
                    ReminderButton(title: text("Don't Remind Me"), dismiss: dismiss) { store.stop(.optedOut) }.frame(height: 28)
                    ReminderButton(title: text("I've Already Starred"), dismiss: dismiss) { store.stop(.selfReportedStarred) }.frame(height: 28)
                }
                if failed {
                    HStack {
                        Text(text("Could not open GitHub")).foregroundColor(.secondary)
                        ReminderButton(title: text("Copy Link"), dismiss: dismiss) {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(GitHubStar.repository.absoluteString, forType: .string)
                        }.frame(width: 120, height: 28)
                    }.font(.caption)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.controlBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(NSColor.separatorColor).opacity(0.4)))
            .padding(10)
        }
    }
}

struct StarReminderSetting: View {
    @ObservedObject private var store = StarReminderStore.shared
    var body: some View {
        Toggle(NSLocalizedString("Invite me to support the project on GitHub", comment: "Star reminder setting"),
               isOn: Binding(get: { store.enabled }, set: { store.setEnabled($0) }))
            .toggleStyle(SwitchToggleStyle())
    }
}
