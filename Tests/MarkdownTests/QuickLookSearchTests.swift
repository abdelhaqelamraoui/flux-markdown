import AppKit
import WebKit
import XCTest

@MainActor
final class QuickLookSearchTests: XCTestCase {
    private final class RecordingWebView: InteractiveWebView {
        var scripts: [String] = []
        override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
            scripts.append(javaScriptString)
            completionHandler?(nil, nil)
        }
    }

    private func event(_ key: String = "f", flags: NSEvent.ModifierFlags = .command, window: Int = 0) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags,
                        timestamp: 0, windowNumber: window, context: nil,
                        characters: key, charactersIgnoringModifiers: key,
                        isARepeat: false, keyCode: 3)!
    }

    private func controller() -> (PreviewViewController, RecordingWebView) {
        let controller = PreviewViewController(nibName: nil, bundle: nil)
        controller.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        let webView = RecordingWebView(frame: controller.view.bounds, configuration: WKWebViewConfiguration())
        controller.webView = webView
        controller.view.addSubview(webView)
        return (controller, webView)
    }

    func testControllerFindOpensSearchIdempotently() {
        let (controller, webView) = controller()
        controller.isWebViewLoaded = true
        controller.isSearchReady = true
        XCTAssertTrue(controller.performKeyEquivalent(with: event()))
        XCTAssertTrue(controller.performKeyEquivalent(with: event("F", flags: [.command, .capsLock])))
        XCTAssertEqual(webView.scripts.count, 2)
        XCTAssertTrue(webView.scripts.allSatisfy { $0.contains("window.showSearch") })
        XCTAssertFalse(webView.scripts.contains { $0.contains("toggleSearch") })
    }

    func testWebViewHandlesFindWithoutRelyingOnDOMDelivery() {
        let webView = RecordingWebView(frame: .zero, configuration: WKWebViewConfiguration())
        var calls = 0
        webView.searchShortcutHandler = { calls += 1 }
        XCTAssertTrue(webView.performKeyEquivalent(with: event()))
        XCTAssertEqual(calls, 1)
        XCTAssertFalse(webView.performKeyEquivalent(with: event(flags: [.command, .shift])))
        XCTAssertFalse(webView.performKeyEquivalent(with: event(flags: [])))
        XCTAssertEqual(calls, 1)
    }

    func testEarlyRequestWaitsUntilRendererIsReady() {
        let (controller, webView) = controller()
        XCTAssertTrue(controller.performKeyEquivalent(with: event()))
        XCTAssertTrue(webView.scripts.isEmpty)
        controller.isWebViewLoaded = true
        controller.completePendingSearchRequest()
        XCTAssertTrue(webView.scripts.isEmpty, "The handshake alone does not create the search UI")
        controller.isSearchReady = true
        controller.completePendingSearchRequest()
        XCTAssertEqual(webView.scripts.count, 1)
        controller.completePendingSearchRequest()
        XCTAssertEqual(webView.scripts.count, 1)
    }

    func testLocalMonitorConsumesOwnEventAndLeavesOtherWindowsAlone() {
        let (controller, webView) = controller()
        controller.isWebViewLoaded = true
        controller.isSearchReady = true
        let window = NSWindow(contentRect: controller.view.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = controller.view
        defer { window.orderOut(nil) }
        XCTAssertNotNil(controller.handleMonitoredKeyDownEvent(event(window: window.windowNumber + 100)))
        XCTAssertTrue(webView.scripts.isEmpty)
        XCTAssertNil(controller.handleMonitoredKeyDownEvent(event(window: window.windowNumber)))
        XCTAssertEqual(webView.scripts.count, 1)
    }
    func testPreviewAppearanceKeepsWebViewAsFirstResponder() {
        let (controller, webView) = controller()
        let window = NSWindow(contentRect: controller.view.bounds, styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = controller.view
        defer { window.orderOut(nil) }
        controller.viewDidAppear()
        let focused = expectation(description: "preview focus applied")
        DispatchQueue.main.async {
            XCTAssertTrue(window.firstResponder === webView)
            focused.fulfill()
        }
        wait(for: [focused], timeout: 2)
    }

    func testStandardFindMenuActionUsesTheSameSearchBridge() {
        let (controller, webView) = controller()
        controller.isWebViewLoaded = true
        controller.isSearchReady = true
        let item = NSMenuItem(title: "Find", action: nil, keyEquivalent: "f")
        item.tag = NSTextFinder.Action.showFindInterface.rawValue
        controller.performTextFinderAction(item)
        XCTAssertEqual(webView.scripts.count, 1)
        var webViewCalls = 0
        webView.searchShortcutHandler = { webViewCalls += 1 }
        webView.performTextFinderAction(item)
        XCTAssertEqual(webViewCalls, 1)
    }

}
