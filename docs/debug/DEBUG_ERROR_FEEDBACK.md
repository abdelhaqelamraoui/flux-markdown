# Contextual error feedback implementation

Baseline: c252863; user approved implementing and validating add-error-feedback.

Acceptance: every inventoried app-owned failure offers task guidance, useful recovery and contextual reporting; a single activation opens a populated GitHub form, with optional inspection/exclusion, bounded safe diagnostics and non-recursive fallback. Validate source/event identity, malicious fields, missing diagnostics, repeated activation, Sparkle completion, renderer failure without JS and actual Quick Look handoff. Do not claim default-branch template availability before publication.

Evidence and per-surface acceptance will be recorded here. Local diagnostic builds explicitly use macOS 12 on Xcode 27; shipping minimum remains macOS 11.

## GitHub handoff decision

Verified the repository's real logged-in GitHub editor with a non-private title/body fixture: `/issues/new?title=...&body=...` opens the populated blank issue editor with no mandatory category/platform fields. No issue was submitted. Runtime uses this existing, verified route so feedback works before a newly added template reaches the default branch. `app_error.yml` and a tested template URL variant remain available for future template adoption; its publication is not a dependency of this release's default route. This is the graceful compatibility path for the approved one-click experience, not an extra user step.

## Implementation and evidence

- Shared `ErrorIncident` has typed operation/source/phase/reason, UUID scope, bounded error chain, failure-time version/environment/settings, recent related settings changes and operation events. JSON is validated again at IPC boundaries; 100 events / 64 KiB storage, 16 KiB requests. Raw error strings, document source and private paths are excluded. Optional notes remain user-controlled.
- `ErrorFeedback` implements one-action browser routing, duplicate-click suppression, optional local review/exclusion, retained drafts, copy/save fallback and history clearing. Native notices do not depend on WebKit. NSError recovery options expose file-open feedback through the system document error presenter.
- Quick Look's authenticated XPC service accepts only validated report payloads and fixed host-app destinations. The host preserves extension snapshots instead of replacing them with its own current state. A separate bounded operation opens the selected document in the matching host for recovery.
- The default runtime route uses the verified GitHub plain Issue editor. The optional specialized template is ready locally but not published; no client workflow depends on it.
- Initial new native tests failed because ErrorIncident/Store/Registry did not exist; initial renderer test failed before the feedback module existed. The existing updater presentation tests were updated for the new three-button behavior and verify that error capture precedes handoff and Sparkle acknowledgement occurs exactly once.
- Native functional suite passed 345 tests before the final additional UI/localization coverage tests. Final counts and CI outcome are recorded below. The unrelated benchmark suite waits indefinitely for its old harness handshake and was stopped; functional tests use the repository CI's documented `-skip-testing:MarkdownTests/RenderBenchmarkTests`. Real production-renderer WebKit checks run separately.
- Renderer suite: 374 passing tests, including every supported error class, stale document controls, redacted payloads, input-error replacement and image recovery. Actual WebKit: 19 passing cases, including a real Mermaid failure, one report message, stale-button rejection and exclusion of feedback UI from HTML export. Print CSS hides the same controls.
- Installed a backup-preserved Release-entitlement candidate locally. Deep signature and release-entitlement checks passed. Actual QLPreview self-test returned `quicklook_preview=rendered`. In Finder Space, the non-private Mermaid fixture showed recovery guidance and report/review buttons. One click opened the prefilled GitHub editor through the extension → XPC → host route; the report identified `Source: quicklook`, the correct candidate version, failure-time settings and renderer event. The fixture source sentinel was absent. No Issue was submitted.
- A later native accessibility capture intermittently returned `cgWindowNotFound`; this does not negate the completed Finder handoff, but further visual coverage is backed by native view/layout/action tests rather than claimed as additional screenshots.
- MacPorts source transformation passes with the new updater wrapper stripped; shared error feedback has no Sparkle dependency. Product minimum remains macOS 11; local Xcode 27 tests explicitly override to 12.0.

## Coverage inventory

| Surface | Implementation / verification |
| --- | --- |
| Update errors | Real Sparkle user-driver path; failure captured before dismissal, report after acknowledgement; download/review/close remain accessible; unit checks include repeated failed update cycles. |
| Document read/encoding/size | `DocumentReadFailure` exposes localized Foundation recovery options for choosing a file, reporting, review and closing; tested without opening another modal. OS-owned inaccessible failures still use Help fallback. |
| Reload | Main app/extension attach native persistent notice; main app retry retains current content. Registry deduplicates repeated same-kind/code errors within one document. |
| HTML/PDF export | Explicit foreground failure paths now attach native retry/save-location guidance; no feedback is generated for cancelled save panels. Generic action tests cover both operation kinds; CLI invalid-input probe separately verifies text-only guidance. |
| Renderer load/navigation/timeout/termination | Native notice survives failed JS; main app bounded handshake timer plus retry preserving queued content; extension offers matching host app. Narrow native layout tested at 360 px. |
| Local images/preview limit | Native extension notice offers host opening; web images have inline feedback removed on successful load. Known limits remain classified separately. |
| Quick Look repair/self-test | Failed outcomes use shared guidance/feedback; successful behavior unchanged. Actual installed Release self-test passed. |
| Search and external destinations | Inline regex guidance and focus recovery; search launcher/native link failures use shared notices; editor child-process failures checked after termination. |
| Renderer/Source/Mermaid/Typst/GraphViz/Vega/KaTeX | Existing error classes wired to bounded metadata-only bridge; technical details folded; direct editor/reload/host recovery; module-load failures get reload/reinstall guidance. DOM coverage tests and real Mermaid WebKit/Finder path pass. |
| Feedback failures | Injected browser failure preserves same draft; report opt-out, Unicode URL budget, missing store, copyable summary and no recursive feedback verified. |
| CLI | stderr adds actionable input/output guidance and a prefilled report URL with safe summary; no GUI feedback launch. |
| OS windows / extension not invoked / crash before capture | Cannot add a button to code that never runs; Help feedback remains the documented fallback. These are not represented as captured incidents. |

## Remaining release-only gate

If switching the runtime to `app_error.yml`, publish it on the default branch and verify it first. The current verified title/body route does not require that publication. No release, master push, issue reply or done label is included in this task.
