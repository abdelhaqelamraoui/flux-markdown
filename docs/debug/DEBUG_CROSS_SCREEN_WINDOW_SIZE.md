# Cross-screen window size preservation

2026-10-16: Main App windows could become smaller when dragged between displays. WindowAccessor persisted the post-transition frame but did not capture the pre-move size or restore AppKit scale-induced changes.

The fix captures the frame and screen ID at `NSWindow.willMoveNotification`. On `didMove`, if the screen ID changed and the system altered the size outside live resize/full-screen, it keeps the current dragged origin and restores the pre-move width/height. User resize, same-screen moves and full-screen transitions are excluded.

Acceptance: 41 WindowSizePersistenceTests pass, including cross-screen restoration, same-screen movement, user live resize and full-screen exclusions. A real App window drag between the two configured displays must preserve frame size; the source version is installed as a local preview for this check.

Local Release build and installation succeeded. The 41-window-test suite passes. A direct accessibility move on the installed pre-fix build showed a frame height change from 999 to 949 when moving to the other screen; the patched build was installed and the frame-preservation policy is covered by tests. Full drag automation could not be completed reliably because the external display window became inaccessible to the accessibility bridge after synthetic repositioning; this is recorded as a limitation rather than claimed as a full visual drag pass.
