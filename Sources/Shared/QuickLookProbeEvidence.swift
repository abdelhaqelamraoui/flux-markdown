import Foundation

enum QuickLookProbeEvidence {
    static let prefix = "flux-quicklook-probe-"
    static func token(for url: URL) -> String? {
        guard url.pathExtension == "md" else { return nil }
        let name = url.deletingPathExtension().lastPathComponent
        guard name.hasPrefix(prefix), let id = UUID(uuidString: String(name.dropFirst(prefix.count))) else { return nil }
        return id.uuidString
    }
    static func marker(token: String, version: String, stage: String) -> String {
        "FluxQuickLookProbe token=\(token) version=\(version) stage=\(stage)"
    }
    static func rendered(in json: String, token: String, version: String) -> Bool {
        guard let data = json.data(using: .utf8),
              let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return false }
        let expected = marker(token: token, version: version, stage: "rendered")
        return entries.contains { entry in
            entry["eventMessage"] as? String == expected &&
            entry["subsystem"] as? String == "com.markdownquicklook.app" &&
            (entry["processImagePath"] as? String)?.hasSuffix("/MarkdownPreview.appex/Contents/MacOS/MarkdownPreview") == true
        }
    }
}
