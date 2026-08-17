# Quick Look Full-Screen Scrollbar Drag Lock

## Symptom

In Finder Quick Look full screen, dragging the document scrollbar with the
macOS three-finger drag gesture does not work reliably. After the attempted
drag, two-finger scrolling and other trackpad scrolling can stop responding.
The standalone FluxMarkdown app remains responsive in full screen.

## Environment

- Investigated on 2026-08-17.
- Installed build: FluxMarkdown 1.34.475 (build 475).
- macOS three-finger drag: enabled (`TrackpadThreeFingerDrag=1`).
- macOS three-finger tap: disabled (`TrackpadThreeFingerTapGesture=0`).
- Fixture: `charters.md`, a long Markdown document with a vertical scrollbar.

## Reproduction

1. Select the Markdown fixture in Finder and press Space.
2. Wait for FluxMarkdown Quick Look to render the document.
3. Enter Quick Look full screen.
4. Reveal the vertical scrollbar and use three-finger drag on its thumb.
5. Attempt ordinary two-finger scrolling afterward.

## Observations

- The released extension rendered in real Finder Quick Look and entered full
  screen successfully.
- The document scrollbar was present in the accessibility tree at scroll value
  `0.4000414`, but Quick Look's remote full-screen host exposed the overlay
  scroller as offscreen to pointer automation.
- Computer Use can read and set the accessibility scroll value, but cannot send
  a coordinate drag to the `QuickLookUIService` XPC full-screen window. The
  physical three-finger stream therefore remains a hardware end-to-end check.
- A native AppKit runtime probe found that every `WKWebView` owns an
  `NSPanGestureRecognizer`.
- The Quick Look host adds an `NSClickGestureRecognizer` for double-click
  interception. AppKit reports that the click recognizer and WebKit's pan
  recognizer can prevent each other.
- The standalone app does not install the Quick Look double-click recognizer,
  which matches the reported host-specific behavior.

## Root Cause

The Quick Look double-click recognizer is attached to the outer `WKWebView`, so
AppKit sends it events hit-tested to WebKit's internal scrollbar. Its default
prevention relationship allows it to block WebKit's native pan recognizer.
Quick Look full screen is hosted across the `QuickLookUIService` remote-view
boundary, where the three-finger primary-button drag stream can be cancelled or
retargeted. The competing click recognizer can then prevent WebKit's pan stream
from completing and leave subsequent scrolling unresponsive.

The normal wheel path and renderer are not involved: unmodified wheel events
are forwarded directly to WebKit, and the renderer has no global wheel listener.

## Fix Strategy

- Replace the generic Quick Look double-click recognizer with a recognizer that
  cannot prevent any `NSPanGestureRecognizer`.
- Preserve the reverse relationship so an actual pan can cancel the pending
  double-click recognition.
- Keep primary mouse events undelayed and retain existing double-click behavior.

## Acceptance Criteria

- The Quick Look double-click recognizer returns `false` from `canPrevent` for
  an `NSPanGestureRecognizer`.
- An `NSPanGestureRecognizer` can still prevent the pending double-click
  recognizer when a drag begins.
- The recognizer retains the configured two-click requirement and does not
  delay primary mouse events.
- Quick Look still renders and enters full screen in Finder.
- The full-screen scrollbar remains adjustable, and subsequent scroll input
  remains responsive.
- Existing zoom, scrolling, toolbar, window, renderer, and release builds pass.

## Verification

- Red: the focused test target failed to compile because the required
  non-blocking recognizer did not exist.
- Green: all focused gesture-arbitration tests passed after the implementation.
- Installed signed Debug build
  `1.34.475-dev-20260817-182514` and confirmed it rendered the fixture in real
  Finder Quick Look.
- Entered Quick Look full screen and adjusted the exposed document scrollbar
  from `0.25` to `0.6500414`, then across `0.1999172` and `0.75`; the visible
  document followed the requested positions and remained correctly laid out.
- Exited full screen and closed Quick Look normally.
- Swift functional suite passed `230/230` tests with the pre-existing hanging
  `RenderBenchmarkTests` target excluded.
- Web Renderer passed `28/28` suites and `302/302` tests.
- The clean macOS Release build passed.
- Release signature and entitlement verification passed, including the Quick
  Look extension's required App Sandbox entitlement.
- Computer Use cannot synthesize a physical three-finger gesture or send a
  coordinate drag into the `QuickLookUIService` remote full-screen window. The
  exact hardware gesture remains a manual check; the prevention relationship
  that blocked WebKit's native pan recognizer is covered directly by the AppKit
  regression tests.
