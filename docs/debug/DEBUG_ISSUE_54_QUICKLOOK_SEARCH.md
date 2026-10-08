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
