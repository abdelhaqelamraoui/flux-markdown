import WebKit
import os.log

class LocalSchemeHandler: NSObject, WKURLSchemeHandler {
    private let logger = OSLog(subsystem: "com.markdownquicklook.app", category: "LocalSchemeHandler")
    private let allowedFilesLock = NSLock()
    private var allowedFilePaths = Set<String>()
    private let resourceQueue = DispatchQueue(label: "com.xykong.Markdown.images", qos: .userInitiated)
    private var activeTasks: [ObjectIdentifier: UUID] = [:]
    private var loadedBytes: [String: Int] = [:]
    private var resourceGeneration = 0
    var onReadFailure: (() -> Void)?
    var baseDirectory: URL?
    var allowedFileURLs: Set<URL> {
        get {
            allowedFilesLock.lock()
            defer { allowedFilesLock.unlock() }
            return Set(allowedFilePaths.map { URL(fileURLWithPath: $0) })
        }
        set {
            resourceGeneration += 1
            loadedBytes.removeAll()
            allowedFilesLock.lock()
            allowedFilePaths = Set(newValue.map { $0.standardizedFileURL.path })
            allowedFilesLock.unlock()
        }
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }
        
        guard let baseDir = baseDirectory else {
            os_log("🔴 Base directory not set", log: logger, type: .error)
            urlSchemeTask.didFailWithError(NSError(domain: "LocalSchemeHandler", code: -1, userInfo: [NSLocalizedDescriptionKey: "Base directory not set"]))
            return
        }

        let filePath = resolveFilePath(from: url)

        os_log("🔵 Start loading resource: %{public}@", log: logger, type: .debug, filePath)

        guard let fileUrl = resolveContainedFileURL(from: url) else {
            os_log("Local image unavailable or not in the document allowlist", log: logger, type: .error)
            onReadFailure?()
            urlSchemeTask.didFailWithError(NSError(domain: "LocalSchemeHandler", code: -3, userInfo: [NSLocalizedDescriptionKey: "Resource unavailable or not allowed"]))
            return
        }
        
        let key = ObjectIdentifier(urlSchemeTask)
        let token = UUID()
        let generation = resourceGeneration
        activeTasks[key] = token
        resourceQueue.async {
            let granted = baseDir.startAccessingSecurityScopedResource()
            defer { if granted { baseDir.stopAccessingSecurityScopedResource() } }
            let result = Result { try BoundedFileReader.read(fileUrl, maxBytes: Int(MarkdownImageDataCollector.Limits.default.maxImageBytes)) }
            DispatchQueue.main.async {
                guard self.activeTasks[key] == token else { return }
                self.activeTasks.removeValue(forKey: key)
                guard self.resourceGeneration == generation else {
                    urlSchemeTask.didFailWithError(CocoaError(.userCancelled))
                    return
                }
                do {
                    let data = try result.get()
                    var budget = self.loadedBytes
                    budget[fileUrl.standardizedFileURL.path] = data.count
                    let limits = MarkdownImageDataCollector.Limits.default
                    guard budget.count <= limits.maxImageCount,
                          budget.values.reduce(0, +) <= Int(limits.maxTotalBytes) else {
                        throw CocoaError(.fileReadTooLarge)
                    }
                    self.loadedBytes = budget
                    urlSchemeTask.didReceive(self.buildResponse(for: url, data: data))
                    urlSchemeTask.didReceive(data)
                    urlSchemeTask.didFinish()
                } catch {
                    LocalResourceDiagnostics.log(error, operation: "scheme-read")
                    self.onReadFailure?()
                    urlSchemeTask.didFailWithError(error)
                }
            }
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        activeTasks.removeValue(forKey: ObjectIdentifier(urlSchemeTask))
    }

    func resolveFilePath(from url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil

        let cleanURL = components?.url ?? url

        if let host = cleanURL.host, !host.isEmpty {
            return "/" + host + cleanURL.path
        }
        return cleanURL.path
    }

    func resolveContainedFileURL(from url: URL) -> URL? {
        guard baseDirectory != nil else { return nil }

        let fileURL = URL(fileURLWithPath: resolveFilePath(from: url))
        guard ["png", "jpg", "jpeg", "gif", "svg", "webp"].contains(fileURL.pathExtension.lowercased()) else { return nil }
        if isExplicitlyAllowed(fileURL) {
            return fileURL
        }
        return nil
    }

    func buildResponse(for url: URL, data: Data) -> URLResponse {
        let mime = mimeType(for: url)
        let headers: [String: String] = [
            "Content-Type": mime,
            "Content-Length": "\(data.count)",
            "Cache-Control": "no-cache, no-store, must-revalidate"
        ]

        if let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        ) {
            return httpResponse
        }

        return URLResponse(url: url, mimeType: mime, expectedContentLength: data.count, textEncodingName: nil)
    }
    
    private func mimeType(for url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        let cleanPath = components?.url?.pathExtension.lowercased() ?? url.pathExtension.lowercased()
        switch cleanPath {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "svg": return "image/svg+xml"
        case "webp": return "image/webp"
        default: return "application/octet-stream"
        }
    }

    private func isContained(_ url: URL, in baseDirectory: URL) -> Bool {
        let basePath = baseDirectory.resolvingSymlinksInPath().standardizedFileURL.path
        let filePath = url.resolvingSymlinksInPath().standardizedFileURL.path
        if filePath == basePath { return true }
        return filePath.hasPrefix(basePath.hasSuffix("/") ? basePath : "\(basePath)/")
    }

    private func isExplicitlyAllowed(_ url: URL) -> Bool {
        let resolvedPath = url.resolvingSymlinksInPath().standardizedFileURL.path
        allowedFilesLock.lock()
        defer { allowedFilesLock.unlock() }
        return allowedFilePaths.contains(resolvedPath)
    }
}
