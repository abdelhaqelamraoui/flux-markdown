# Issue #54: Cmd+F in QuickLook

## Reporter verification — October 9

The user manually tested the installed acceptance candidate and confirmed that
Cmd+F opens Finder search instead of search in the preview, matching the old
behavior. This is a real failed end-to-end acceptance test. The earlier automation
window-binding issue does not explain the manual result. Existing unit tests only
prove handling after an event/action reaches the extension process; they do not
prove Finder forwards that command. #54 remains unresolved.

Next distinguish command interception from missing focus by clicking document
content before Cmd+F. Independently provide a native search control with an AppKit
key equivalent and the same deferred/idempotent bridge. The button must work without
receiving any keyboard event; it must not advertise a guaranteed Finder shortcut.
No global key listener, event tap, host injection or new permission is introduced.

### Button follow-up

A magnifying-glass native toolbar button now calls the same deferred, idempotent
search bridge. Its AppKit key equivalent accepts exactly Cmd+F, excluding Cmd+Shift+F.
The latter regression initially failed because NSButton accepts additional modifier
keys; a per-button matcher fixes that without changing other toolbar controls.
Eight search tests and twelve native toolbar tests pass (20 total). No arbitrary
typed characters are logged by the preview key handlers.

The WebView already reports `needsPanelToBecomeKey = true`; changing that property
would not address the host-routing failure. Apple documents that local event monitors
only observe events delivered to their own application:
https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html
This explains the limit of the existing local monitor, but is not proof that no
supported Quick Look shortcut route exists. No public API found so far guarantees
forwarding Finder's Find command into a remote extension view.

Installed button candidate: `1.34.475-dev-20261009-112059`. Runtime automation still
refuses the preview's coordinate input with `window_not_focused`; a separate qlmanage
preview could not expose its AX window. These are recorded as unverified runtime
checks, not passes. The reporter's click-content-then-Cmd+F result is pending.

Issue: https://github.com/xykong/flux-markdown/issues/54
Baseline: `3911a15`, release `v1.34.475`.
The renderer has a search UI and a DOM key listener. The native QuickLook
controller handles zoom/reload/mode shortcuts but not Cmd+F; the WebView also
has no native find shortcut override. A local event monitor uses `?? event`,
which incorrectly reinstates an event consumed by a live controller.

## Acceptance before implementation

- Cmd+F routed to either the preview controller or its WebView opens and focuses search.
- Repeated delivery never toggles the search closed.
- Cmd+Shift+F and plain F are passed through.
- The local monitor consumes handled events only for its own window.
- A find request before renderer readiness is applied after rendering completes.
- Escape closes the search UI; search never changes the document.

## Validation

Native regressions failed before the bridge existed and now pass (4 cases). The DOM regression exposed repeat delivery closing the search and missing search initialization when source mode renders first; both are fixed. The full renderer suite passes 308 tests / 30 suites, and 23 related native tests pass. Actual Finder runtime verification is the next acceptance step. Validation uses an Xcode build-time macOS 12 override because this SDK no longer supports the project's macOS 11 target. No deployment target setting has been changed.


## Additional focus regression and runtime evidence

`viewDidAppear` moved first responder from the WebView to the controller, and
InteractiveWebView returned true without calling WebKit's becomeFirstResponder.
A new window/appearance test failed before correction and passes after delegating
to WebKit and retaining WebView focus. Five search tests and 24 related native
tests pass; the renderer suite remains 308/308.

Finder loaded the installed extension and emitted Renderer Handshake Received;
the renderer main asset matches the app and extension copies byte-for-byte.
However, the automation provider binds the remote QuickLook accessibility panel
to the underlying Finder CG window. Restoring that window can send Cmd+F to
Finder search rather than the remote preview, so those synthetic key attempts
are not a valid end-to-end pass or a proven preview failure. The native pipe also
failed in the other UI provider. Manual Finder verification is still required
before declaring issue #54 resolved on the reported macOS Tahoe environment.

The standalone App runtime successfully opened the search bar, found Alpha with
counter 1/2, and hid search on Escape. No query text is added to diagnostics.
The bounded Find-action log records readiness flags only, not search contents.

Manual acceptance: select the fixture in Finder, press Space then Cmd+F before
clicking content, confirm focus in the search field, repeat Cmd+F without closing
it, type Alpha and confirm two matches, then Escape. Repeat after clicking inside
the document and in full screen. Do not add done before release and confirmation.
