# Design

## Feasibility result, October 9

The user approved a development trial, expressing concern about permission friction.
A standalone read-only probe was built without embedding or persistence. It does not
create taps, request authorization or perform accessibility actions. Its actual
runtime inspection found one search-button UUID marker in the Quick Look AX tree,
but AXUIElementGetPid attributed that control to Finder. Authentication therefore
failed and interception remains disabled. The direct AX route in the design below
has not passed its feasibility gate. A cross-process attestation refinement would
be needed before continuing; a marker-only predicate is not an acceptable shortcut.

The CLI trust query returned true in the current launch context without any permission
change. This does not establish independent helper authorization or ordinary-user
setup behavior. Keep this probe outside the normal app/distribution dependency graph.

## Scope and permission boundary

The preview remains sandboxed. The optional helper is a separate embedded background
application with its own stable signing identity and Accessibility authorization.
Neither installation nor migration silently enables it or requests permission.
The main app displays an explicit enable control, explains the permission and offers
disable/stop. Refusal leaves previews and the native search button functional.

## Route

1. The helper establishes that Finder is the frontmost application and that its
   focused preview contains a FluxMarkdown search control with a per-view identity.
2. A feasibility spike must confirm this identity survives the Quick Look remote
   accessibility bridge in normal and full screen windows. Do not infer identity
   from a filename extension, window title, "Markdown Preview", geometry, or an
   unverified notification alone.
3. Prefer a supported event tap scoped to Finder's process (the SDK declares
   CGEventTapCreateForPid). If unavailable, a session tap still applies the same
   strict frontmost/preview predicates. Do not use private APIs or inject into Finder.
4. The callback examines only event type, numeric key code and modifier flags.
   Exactly Cmd+F is eligible; other keys and Cmd+Shift+F pass through unchanged.
   No Unicode keyboard text is read.
5. Invoke the positively identified native search button through its accessibility
   action. This reuses the existing deferred/idempotent renderer bridge and avoids
   an app-group IPC dependency (app groups were removed for ad-hoc signing in #13).
6. If ownership, freshness or action delivery is uncertain, preserve the original
   event. Finder behavior takes precedence over a guessed preview recipient.

## Target validity and timing

Prototype target attribution and event dispatch before building the full setting.
Check actual accessible remote-process identity and signing where exposed. A marker
must not itself be treated as proof of the executing process. If public AX metadata
cannot reliably attribute the active preview, design an authenticated per-preview
lease transport as a separately reviewed refinement; do not relax the predicate.

AX lookups/action calls must not block the event tap. Maintain a bounded, fresh
target snapshot using window/focus observations, invalidate on focus/visibility/
connection changes, and use a watchdog. A safe action-confirmation/consumption
sequence must be demonstrated so Finder is not suppressed when search fails to
open. Repeated Cmd+F focuses existing search instead of toggling it closed.

## Lifecycle and compatibility

Start the helper only after explicit opt-in. First prototype launch-on-demand with
no login item or LaunchAgent. If startup persistence proves necessary, add a user
controlled login item using the supported ServiceManagement APIs, with macOS 11/12
compatibility or a clearly stated minimum version. Do not raise deployment targets
silently. Stop the tap and helper on disable/revocation/loss of target; handle system
sleep, secure input and event-tap timeout without repeated permission prompts.

Distribution embeds the helper in the app. Vendor install, reinstall and upgrade
must replace the helper consistently and preserve opt-in; uninstall removes any
registration owned by this app. Release signing/notarization must preserve helper
identity to avoid a permission request for every update.

## Diagnostics

Only opt-in, permission granted/denied, helper running/stopped and fixed error codes
are diagnostic fields. No input events, search queries, document text, paths, or
other applications' UI content are stored or sent. The settings change is recorded
through the existing allowlisted settings history.

## Required proof before completion

- Real Finder: Space then Cmd+F before any click, after clicking text, and full screen.
- Alpha: two matches, repeat Find retaining query, Escape closing search only.
- Another document/provider, Finder alone, other app, missing/revoked permission,
  stale preview identity, helper crash, secure input and tap timeout: unchanged input.
- Multiple preview lifetimes and rapid file switching never target a stale view.
- Installation, update, disable and uninstall do not leave interception running.

If the feasibility tests fail, keep #54 unresolved and report the specific missing
public API behavior. Do not declare the search button or unit tests a shortcut fix.
