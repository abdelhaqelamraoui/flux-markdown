import WebKit

enum RendererBridgePolicy {
    static func accepts(_ message: WKScriptMessage) -> Bool {
        accepts(url: message.frameInfo.request.url, isMainFrame: message.frameInfo.isMainFrame)
    }
    static func accepts(url: URL?, isMainFrame: Bool) -> Bool {
        isMainFrame && url?.scheme == RendererBundleSchemeHandler.scheme && url?.host == "bundle"
    }
}
