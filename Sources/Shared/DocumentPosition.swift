import Foundation

enum DocumentPosition: Equatable {
    case line(Int)
    case anchor(String)
    case search
    var arguments: [String: Any] {
        switch self {
        case .line(let line): return ["line": min(line, 9_007_199_254_740_991)]
        case .anchor(let anchor): return ["anchor": anchor]
        case .search: return ["find": true]
        }
    }
}

struct DocumentOpenRequest {
    let fileURL: URL
    let position: DocumentPosition?
    let wantsSearch: Bool

    static func searchURL(for fileURL: URL) -> URL? {
        guard fileURL.isFileURL, fileURL.path.hasPrefix("/"), !fileURL.path.contains("\0") else { return nil }
        var components = URLComponents()
        components.scheme = "markdownpreview"
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "path", value: fileURL.path), URLQueryItem(name: "find", value: "1")]
        return components.url
    }
    init?(url: URL) {
        guard url.scheme?.lowercased() == "markdownpreview",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let paths = components.queryItems?.filter { $0.name == "path" } ?? []
        guard paths.count == 1, let path = paths.first?.value,
              path.hasPrefix("/"), !path.contains("\0") else { return nil }
        fileURL = URL(fileURLWithPath: path).standardizedFileURL
        let searches = components.queryItems?.filter { $0.name == "find" } ?? []
        wantsSearch = searches.count == 1 && searches.first?.value == "1"
        let lines = components.queryItems?.filter { $0.name == "line" } ?? []
        if lines.count == 1, let value = lines.first?.value, !value.isEmpty,
           value.utf8.allSatisfy({ (48...57).contains($0) }), let line = Int(value), line > 0 {
            position = .line(line)
        } else if let anchor = components.fragment, !anchor.isEmpty, anchor.utf8.count <= 1024 {
            position = .anchor(anchor)
        } else { position = nil }
    }
}

/// File-scoped, bounded, single-use explicit navigation. UUIDs prevent failed
/// older opens from removing a newer request for the same document.
final class DocumentPositionStore {
    static let shared = DocumentPositionStore()
    static let searchRequests = DocumentPositionStore()
    static let notification = Notification.Name("FluxMarkdown.documentPositionRequested")
    private var requests: [String: (UUID, DocumentPosition)] = [:]
    private var order: [String] = []
    private let lock = NSLock()
    private func key(_ url: URL) -> String { url.standardizedFileURL.resolvingSymlinksInPath().path }
    @discardableResult func set(_ position: DocumentPosition, for url: URL) -> UUID {
        lock.lock(); defer { lock.unlock() }
        let path = key(url), id = UUID()
        requests[path] = (id, position)
        order.removeAll { $0 == path }; order.append(path)
        while order.count > 100 { requests.removeValue(forKey: order.removeFirst()) }
        return id
    }
    func consume(for url: URL) -> DocumentPosition? {
        lock.lock(); defer { lock.unlock() }
        let path = key(url)
        order.removeAll { $0 == path }
        return requests.removeValue(forKey: path)?.1
    }
    func discard(for url: URL, id: UUID) {
        lock.lock(); defer { lock.unlock() }
        let path = key(url)
        guard requests[path]?.0 == id else { return }
        requests.removeValue(forKey: path); order.removeAll { $0 == path }
    }
}
