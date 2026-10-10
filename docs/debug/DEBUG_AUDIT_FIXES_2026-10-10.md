# Audit remediation tracking

Baseline: 8cbd40d. Scope and acceptance criteria: [project audit](DEBUG_PROJECT_AUDIT_2026-10-10.md). User authorized remediation after reviewing the audit. OpenSpec: fix-audit-reliability.

Preserve macOS 11 product minimum, passive HTML presentation and existing diagram support. Validate each fix with failing regressions first. Do not publish a release or alter installed application associations as part of this work.

## Results

Remediation implemented; final results and runtime limits are recorded below.

### Rendering safety and consistency

Three regression tests failed before implementation. DOMPurify now removes active document content before DOM insertion while preserving task checkboxes, details, tables and math presentation. Per-request parser configuration avoids Emoji/KaTeX state drift. JS generations invalidate pending work for preview/source changes; QuickLook checks native generations before async image results, completion and scroll restoration. Removed unconditional Mermaid prefetch; Vega views are finalized.

Validation: 37 Jest suites / 346 tests passed, production build passed, RenderVersion XCTest passed with the documented local target override. Added separate passive-HTML compatibility tests. Native safety verification will be repeated against the final bundle.

### Native resources and export

Typst now uses Vite-resolved compiler/renderer WASM, bundled New Computer Modern fonts with the embedded versions' GUST license, independent retryable initialization and serialized compiler access. Production WebKit checks passed, including offline native Typst SVG, all three other diagram engines, CSP, bridge origin validation and export readiness.

CLI export awaits render completion and bounded font/image readiness, with a 60-second process deadline and explicit navigation failures. QuickLook reads and refreshes are asynchronous and UTF8-safe. App refreshes are asynchronous, and full App documents have a 32 MiB rejection limit (never silently truncate an editable document). Local image routes only serve explicitly referenced, budget-approved image files. Collector and scheme routes share 32-image / 2 MiB per image / 8 MiB source-byte policies, and cancelled scheme tasks cannot receive callbacks. Reference-style and parenthesized image names are covered.

Validation: native suite passed after the asynchronous toolbar feedback integration was updated; new resource syntax/budget test first failed and then passed. Production dependencies currently have zero npm audit findings. Remaining test-tool dependencies are being upgraded separately.


### Final validation on 2026-10-11

- Clean npm ci, independent typecheck and all 40 Jest suites / 353 tests passed. Updated Jest to 30 and removed the vulnerable test-only YAML/argparse chain with a targeted, documented override; full npm audit is now zero, including development dependencies.
- Production build and ten actual WebKit cases passed with universal file access disabled. Cases include CSP/HTML safety, native bridge origin checks, stale render protection, offline Typst, Mermaid, Graphviz, Vega, a resource delayed past three seconds, local images and export readiness.
- 295 native tests passed with explicit local MACOSX_DEPLOYMENT_TARGET=12.0 on Xcode 27. Added cancellation and oversize scheme-task tests. Also corrected the App's theme fast path so font/plugin changes trigger a full render.
- The built Debug application's real CLI exported a one-page PDF containing KaTeX, native Typst and Mermaid. No installation, association change or publication was performed.
- Release publication has five isolated failure/retry tests; no GitHub/tap operations are invoked by those tests. Existing asset mismatches stop publication; failed feed/tap stages return failure; release notes are retained for manifest verification on retry.
- One parse now supplies tokens to both outline and HTML. The before/after parse-only benchmark on the 16,564-byte fixture measured medians of 1.048 ms (two parses) and 0.499 ms (one parse), 30 alternating samples after five warmups. Reproduce with node benchmark/parse-reuse.cjs. These numbers do not measure whole-app launch time.

### Compatibility and remaining validation boundaries

The product still targets macOS 11; Xcode 16.4 release CI and explicit Safari 14 syntax targets are retained. Physical macOS 11/Intel Finder acceptance and the complete three-layer cold-start benchmark require their target environments and were not executed here. Existing historic OpenSpec changes are not falsely marked deployed or archived.

Native Typst now actually bundles its offline assets, increasing dist to about 37 MiB; the existing host/extension packaging duplicates that directory. QuickLook continues to use transpilation. This is a deliberate disk-space cost of repairing the native path, not a claimed startup optimization. See docs/dev/BUILD_COMPATIBILITY.md for compatibility, resource limits, export failure policy and dependency overrides.
