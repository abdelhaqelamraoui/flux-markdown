# Search handoff window placement

The user accepts keeping the preview open, and requests that search open the app on
the preview's display, preferably at the same size and position. This is an explicit
placement override for that handoff, not a change to default-editor behavior.

## Acceptance before implementation

- Capture the preview's own NSWindow frame in AppKit screen points and display ID,
  not pixel coordinates or the global mouse position.
- Pass optional validated geometry through the existing private XPC/own-app URI.
  Do not log/store it in feedback settings history.
- The explicit handoff takes priority over saved/default startup geometry. Delayed
  startup frame restores must not undo it.
- Reposition an already-open document as well as a newly created window.
- Preserve exact geometry when it fits; otherwise constrain the frame to the
  target screen's visible frame. Support negative display origins and Retina points.
- If a display was disconnected or geometry is invalid, use a safe visible screen
  without preventing file opening/search.
- Do not exit an existing full-screen app window or create overlapping duplicates.
- Test pure geometry, URI validation, file-scoped request consumption and stale
  frame reapply cancellation, then verify real preview/app frames where accessible.

## Results

- New placement/URI tests failed before implementation. A negative raw width
  regression initially failed because CGRect's computed width normalizes a negative
  size; validation now checks raw size components. 60 placement, startup geometry,
  navigation and search regressions pass.
- Geometry is optional, file-scoped, bounded and consumed once. It travels in the
  existing authenticated XPC/own-app URL, without being added to diagnostics history.
- New-window attachment and early renderer callbacks share a weak-window pre-attach
  override; saved geometry cannot supersede it. A per-window revision cancels old
  delayed frame restore callbacks when a later explicit placement is applied.
- The actual preview's existing screen-environment log reported AppKit frame
  (1686,995,1279x812) on the upper/right external display. These are points, not pixels.
  Current display arrangement includes an external frame beginning at (1512,982).
- A direct own-app search URI using that frame and a disconnected-display ID verified
  visible-screen fallback. The installed main app's real window matched x=1686,
  width=1279, height=812 and Quartz y=-825 (982-(995+812)), consistent with the
  requested AppKit position. The app URI and warm-app geometry route are verified.
- There was also an old DerivedData app process with the same bundle ID. Inspection
  initially read its unrelated 1477x971 window. Measurements above target the installed
  app by exact process identity; the other process was not closed or modified.
- The automation provider could not read AX windows on the external display and
  reports its screen index as null for above-primary coordinates. Consequently the
  complete preview-icon click/geometry path and interactive full-screen placement
  remain pending runtime checks, rather than claimed passes. Preview capture uses
  its own window frame/screen and does not use the mouse or whichever display is main.
- Release build and strict nested signature/entitlement validation pass. No new
  permission, default-editor change or preview dismissal is introduced.

## Release candidate receiver verification

Installed Release-configured candidate `1.34.475-dev-20261010-002450` also passed
real cold and warm window placement requests. Cold start requested AppKit frame
(1780,1150,900x650); the installed process's actual Quartz window was
(1780,-818,900x650), correctly using 982-(1150+650). A separate already-running
installed process (PID 92795, window 6698) accepted (1686,-825,1279x812), matching
the preview's measured content frame, then moved the same window to
(1780,-818,900x650) on another request.
Thus explicit placement overrides saved sizing and repositions an existing document.
The handoff uses the extension's content/service-window bounds, so host preview
chrome can differ slightly from the main app's title bar/borders.

The additional pre-attach-priority regression passes; the final related native
suite has 60 tests with zero failures. Temporary frame-match instrumentation was
removed; only a bounded placement-present flag remains in the app URL event log.
