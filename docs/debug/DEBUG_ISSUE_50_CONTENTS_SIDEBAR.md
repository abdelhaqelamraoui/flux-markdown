# #50 contents sidebar implementation

Baseline: `c34965a`. User approved the refined design on 2026-10-10.
Acceptance: docs/design/DESIGN_ISSUE_50_CONTENTS_SIDEBAR.md.

## Initial regressions and diagnosis

The old visibility flag made a docked directory turn into an open overlay on
resize, and narrow interactions overwrote wide preference. The first regression
run failed six sidebar cases and the missing measured-controls module.

After isolated state tests passed, actual browser navigation still left the overlay
open. The document's capture-phase link bridge stopped propagation before the
TableOfContents link handler could run. An integration test reproduced the failure.
The global bridge must leave directory-owned navigation to its own handler.

HTML export also preserved collapsed quote placeholders and hidden quote styles.
A second integration test failed before expanding these controls in the export
clone; the live document must retain its collapsed state.

## Validation

- 35 renderer suites / 332 tests pass; TypeScript validates with `--module esnext`.
  The existing tsconfig uses `es6`, which rejects pre-existing dynamic imports.
- Browser geometry passes at 520, 760, 899, 900, 901 and 1100 CSS px: no page overflow
  or docked body/contents overlap; 900 is the measured docking boundary.
- Closing a docked directory while reading preserves the same block's vertical
  offset exactly (0 px drift in the observed run). Narrow navigation closes its
  overlay, lands below controls and marks the target chapter after smooth scrolling
  settles. Returning to wide restores the hidden docked preference.
- All 100 blockquotes collapse and expand using the actual top button. Dark-mode
  controls/search and 100%, 150%, 200% document zoom were checked.
- HTML export has no toolbar, directory or quote placeholders. It restores 20 px
  body padding and full document width. Browser print hides all chrome, removes the
  grid column and expands quotes. Compact Finder context hides tools with 8 px padding.
- Native Release build passes; final bundle passes strict deep signature and release
  entitlement verification. Installed candidate: `1.34.475-dev-20261010-012536`.
- The native app's wide layout and directory button were visually/semantically
  verified on candidate 004402. The final layout passed native 2560-point
  full-screen screenshot validation on candidate 011253, with centered text and a
  visible directory. Candidate 012536 adds the verified Escape-priority refinement.
  Current editor handlers were preserved by the vendor installer.

## Native runtime limits and packaging notes

The GUI drag provider did not resize the native test window, so native narrow-window
coverage is not claimed. qlmanage's window observation returned
`permission_denied` for accessibility. Browser checks cover QuickLook/compact
contexts, but actual expanded QuickLook acceptance is still pending. No system
permission was changed, no issue was marked done and no release was published.

An initial CODE_SIGNING_ALLOWED=NO build left an invalid nested Sparkle signature;
that package was rejected before installation. Rebuilding with normal ad-hoc signing
fixed it; strict signature/entitlement verification passes. Native validation uses
a build-time macOS 12 override for this SDK, without changing project macOS 11
support settings or claiming Big Sur compatibility.


## Full-screen paint investigation

The latest native full-screen screenshot showed centered document content but did
not show the contents panel, although AX exposed its links. Before changing layout
again, temporarily measure sidebar/container rectangles and computed display through
the existing JS-to-native logger. No text, headings or paths are included. This will
distinguish off-screen layout from screenshot/compositor observation limitations.

The native log confirmed a 2560×1440 viewport, 980 px centered document at x=658,
and visible 240×1310 contents at x=2300/y=110. Coordinates and AX were correct while
the screenshot omitted the sticky layer. Keep the actual grid column, but fix the
navigation panel to that column's viewport position, avoiding the full-screen sticky
compositing path. Temporary geometry logging was removed before the final build.

Final native screenshot (candidate 011253) confirms the contents panel and centered
document are both painted correctly in full screen after changing the panel's
viewport positioning. The grid still owns the reserved 240 px column; no padding
hack or document overlay is used. Browser geometry was repeated at seven widths,
including 2560 px; all document/panel overlap checks remain false.

The final input regression also verifies Escape priority when the search field is
focused behind narrow contents. Capture-phase handling closes only contents and
returns focus to its button; search stays open. The integration test failed before
the phase change, passes afterward, and the browser repeated this exact scenario.

## Follow-up: excessive top whitespace

The user rejected the permanent extra toolbar row and layout-reserved search row.
Two regressions first failed: search changed reserved height, and search without
tools created an empty row. They now pass with measured compact shared controls
and a floating search sibling outside the reserved chrome.

Browser checks at 320/400/520/760/900/1100 CSS px show no horizontal overflow.
Wide-view toolbar starts at y=10, height=32, beside the existing native controls;
first document content moved from y=155 to y=80. Showing search at scrollY=1500
preserves that scroll position and the 64 px body inset; search occupies a 520×44
floating panel at y=68, centered within the document column. Small viewports wrap
only when the controls cannot fit beside the native controls.

334 tests pass. New navigation offsets and reading-anchor sampling avoid the
floating search panel without reintroducing document reflow.

Native verification on `1.34.475-dev-20261010-020640` confirms directory and native
icons share the top row. App Cmd+F opens the floating panel without moving the
metadata table; typing Alpha returns 1/2. Release build, deep signature and sandbox
checks pass. SHA-256 comparison confirms both installed app and extension contain
the latest renderer. The previous native package was rebuilt after detecting stale
resource copies; only the matching final package is retained as the current candidate.
