import AppKit
import XCTest

final class SearchWindowPlacementTests: XCTestCase {
    @MainActor func testPlacementAppliedBeforeAccessorAttachRetainsStartupPriority() throws {
        let url = URL(fileURLWithPath: "/tmp/pre-attach.md")
        let window = NSWindow(contentRect: CGRect(x: 40, y: 40, width: 800, height: 600),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        defer { window.orderOut(nil) }
        let screen = try XCTUnwrap(NSScreen.screens.first)
        let id = try XCTUnwrap(screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)
        let target = CGRect(x: screen.visibleFrame.minX + 20, y: screen.visibleFrame.minY + 20, width: 800, height: 600)
        DocumentWindowPlacementStore.shared.set(try XCTUnwrap(SearchWindowPlacement(frame: target, displayID: id.uint32Value)), for: url)
        let applied = try XCTUnwrap(WindowAccessor.applyPendingSearchPlacement(to: window, for: url))
        XCTAssertNil(DocumentWindowPlacementStore.shared.consume(for: url))
        XCTAssertEqual(WindowAccessor.takePreAttachSearchFrame(for: window), applied)
        XCTAssertNil(WindowAccessor.takePreAttachSearchFrame(for: window))
    }
    @MainActor func testLaterPlacementCancelsEarlierDelayedRestore() {
        let visible = CGRect(x: 0, y: 0, width: 1500, height: 900)
        let old = CGRect(x: 40, y: 50, width: 800, height: 600)
        let latest = CGRect(x: 300, y: 80, width: 1000, height: 700)
        let window = NSWindow(contentRect: old, styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        defer { window.orderOut(nil) }
        WindowAccessor.applyFrameApplications(to: window, targetFrame: old, visibleFrames: [visible])
        WindowAccessor.applyFrameApplications(to: window, targetFrame: latest, visibleFrames: [visible])
        let settled = expectation(description: "old restore has expired")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            XCTAssertEqual(window.frame, latest)
            settled.fulfill()
        }
        wait(for: [settled], timeout: 2)
    }
    func testExplicitDisplayAndNegativeCoordinatesArePreserved() {
        let frame = CGRect(x: -1700, y: -100, width: 1000, height: 700)
        let request = SearchWindowPlacement(frame: frame, displayID: 2)
        let screens = [SearchWindowPlacement.Screen(id: 1, visibleFrame: CGRect(x: 0, y: 0, width: 1500, height: 900)),
                       SearchWindowPlacement.Screen(id: 2, visibleFrame: CGRect(x: -1920, y: -200, width: 1920, height: 1040))]
        XCTAssertEqual(request?.fittedFrame(screens: screens), frame)
    }

    func testOversizedFrameFitsTheSelectedDisplay() {
        let placement = SearchWindowPlacement(frame: CGRect(x: 1800, y: -300, width: 3000, height: 1500), displayID: 2)
        let visible = CGRect(x: 1600, y: 40, width: 1920, height: 1040)
        XCTAssertEqual(placement?.fittedFrame(screens: [.init(id: 2, visibleFrame: visible)]), visible)
    }

    func testDisconnectedDisplayFallsBackToVisibleGeometry() {
        let placement = SearchWindowPlacement(frame: CGRect(x: 2000, y: 100, width: 800, height: 600), displayID: 99)
        let result = placement?.fittedFrame(screens: [.init(id: 1, visibleFrame: CGRect(x: 0, y: 0, width: 1500, height: 900))])
        XCTAssertEqual(result, CGRect(x: 700, y: 100, width: 800, height: 600))
    }

    func testURIUsesValidatedOptionalGeometry() throws {
        let placement = try XCTUnwrap(SearchWindowPlacement(frame: CGRect(x: -1700, y: 80, width: 1000, height: 700), displayID: 2))
        let url = try XCTUnwrap(DocumentOpenRequest.searchURL(for: URL(fileURLWithPath: "/tmp/中文 note.md"), placement: placement))
        XCTAssertEqual(DocumentOpenRequest(url: url)?.windowPlacement, placement)
        XCTAssertNil(DocumentOpenRequest(url: URL(string: "markdownpreview://open?path=/tmp/a.md&find=1&frame=nan,0,800,600&screen=1")!)?.windowPlacement)
        XCTAssertNil(DocumentOpenRequest(url: URL(string: "markdownpreview://open?path=/tmp/a.md&find=1&frame=0,0,800,600&frame=0,0,800,600&screen=1")!)?.windowPlacement)
        XCTAssertNil(SearchWindowPlacement(frame: CGRect(x: 0, y: 0, width: -1, height: 400), displayID: 1))
    }

    func testPerFilePlacementIsLatestWinsAndConsumedOnce() throws {
        let store = DocumentWindowPlacementStore()
        let a = URL(fileURLWithPath: "/tmp/a.md"), b = URL(fileURLWithPath: "/tmp/b.md")
        let old = try XCTUnwrap(SearchWindowPlacement(frame: CGRect(x: 0, y: 0, width: 800, height: 600), displayID: 1))
        let new = try XCTUnwrap(SearchWindowPlacement(frame: CGRect(x: 1600, y: 0, width: 1000, height: 700), displayID: 2))
        let id = store.set(old, for: a)
        store.set(new, for: a); store.discard(for: a, id: id)
        store.set(old, for: b)
        XCTAssertEqual(store.consume(for: a), new)
        XCTAssertNil(store.consume(for: a))
        XCTAssertEqual(store.consume(for: b), old)
    }
}
