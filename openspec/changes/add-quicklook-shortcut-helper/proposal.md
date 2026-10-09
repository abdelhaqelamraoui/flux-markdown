## Status: shortcut work withdrawn — 2026-10-10

The user explicitly stopped further attempts to support Cmd+F directly inside the
Finder Quick Look preview, accepting the system constraints. Shortcut interception,
Accessibility helper development, remote-attestation refinements and inline-preview
keyboard-search acceptance are no longer planned or release gates. The historical
material below records the abandoned approach, not current product
requirements. Retain the verified native search button → containing app → editable
search route and normal Cmd+F in the standalone application. This decision does
not claim that the original Finder shortcut was implemented or that #54 is released.

# Change: Optional Quick Look shortcut helper for issue #54

## Why

Manual testing confirms that Cmd+F opens Finder search, including after clicking
the preview content. The existing extension responders, local event monitor and
native button key equivalent do not establish delivery from Finder. The search
renderer and direct native search action already work in isolated tests.

Apple documents that local monitors only see their own application's events and
global NSEvent monitors cannot suppress delivery. Peek's developer documents an
Accessibility-authorized helper for this same Quick Look shortcut problem. This
supports a helper approach; it does not establish that our helper is already viable.

## What Changes

- Add an optional embedded shortcut helper, disabled by default.
- Add a settings switch explaining that macOS Accessibility authorization is needed.
- Intercept exactly Cmd+F only when Finder is active and its active Quick Look
  preview is positively identified as the current FluxMarkdown preview.
- Invoke that preview's native search action; preserve Finder's usual Cmd+F in all
  other situations. No replacement shortcut is advertised as a fix.
- Retain the magnifying-glass button without any new permission.
- Stop interception when the preview closes, ownership changes, permission is
  revoked, the feature is disabled, or the helper loses its verified target.
- Do not record, retain or transmit typed text, document contents or file paths.

## Impact

- New capability: quicklook-shortcuts.
- New helper target and embedded bundle configured in `project.yml`; generated
  Xcode projects stay untracked.
- Host settings and lifecycle, preview accessibility identity, helper installation
  and cleanup, diagnostics permission/availability flags and release signing.
- This is a new permission and process boundary. Implementation waits for approval
  of this proposal; granting the system permission remains an explicit user action.
- Native Cmd+F is still unresolved until Finder end-to-end tests pass.

## Evidence

- https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html
- https://www.bigzlabs.com/peek.html (developer FAQ, Accessibility Access)
- Local SDK CoreGraphics `CGEvent.h` documents event-tap keyboard trust requirements.
- `docs/debug/DEBUG_ISSUE_54_QUICKLOOK_SEARCH.md` contains failed manual acceptance.
