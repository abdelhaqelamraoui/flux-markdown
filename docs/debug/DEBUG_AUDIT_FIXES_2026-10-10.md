# Audit remediation tracking

Baseline: 8cbd40d. Scope and acceptance criteria: [project audit](DEBUG_PROJECT_AUDIT_2026-10-10.md). User authorized remediation after reviewing the audit. OpenSpec: fix-audit-reliability.

Preserve macOS 11 product minimum, passive HTML presentation and existing diagram support. Validate each fix with failing regressions first. Do not publish a release or alter installed application associations as part of this work.

## Results

Implementation and validation in progress.

### Rendering safety and consistency

Three regression tests failed before implementation. DOMPurify now removes active document content before DOM insertion while preserving task checkboxes, details, tables and math presentation. Per-request parser configuration avoids Emoji/KaTeX state drift. JS generations invalidate pending work for preview/source changes; QuickLook checks native generations before async image results, completion and scroll restoration. Removed unconditional Mermaid prefetch; Vega views are finalized.

Validation: 37 Jest suites / 346 tests passed, production build passed, RenderVersion XCTest passed with the documented local target override. Added separate passive-HTML compatibility tests. Native safety verification will be repeated against the final bundle.
