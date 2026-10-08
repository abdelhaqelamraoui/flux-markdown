# Issue #54: Cmd+F in QuickLook

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
