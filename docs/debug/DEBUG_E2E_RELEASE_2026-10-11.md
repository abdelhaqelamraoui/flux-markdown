# End to end release acceptance 2026 10 11

Baseline: 1c063dc. User requested comprehensive local end-to-end validation followed by a new release. This authorizes preparation, local installation validation, GitHub publication, Sparkle feed and Homebrew tap updates. No issue replies are requested.

Environment: macOS 27.0.1, arm64, Xcode 27. Local diagnostics use an explicit macOS 12 target; shipping artifacts must come from the pinned Xcode 16.4 universal macOS 11 build. Existing exclusions for direct Finder QuickLook Command-F and physical gesture acceptance remain as documented in ACCEPTANCE_ALL_ISSUES.md; the supported search-button handoff will be verified.

## Acceptance matrix

- [ ] Renderer tests, typecheck, real WebKit production assets, dependency audit.
- [ ] Native App open, search, source/preview, navigation, theme/zoom, refresh, exports.
- [ ] Finder QuickLook rendering and search handoff from the final payload.
- [ ] Universal release signatures, entitlements, minos, resource provenance, DMG.
- [ ] Final local installation, editor preference preservation and PDF/export checks.
- [ ] Public assets, Sparkle feed and Homebrew version/checksum verification.

Evidence is retained under build/e2e-20261011 (local artifacts). Results will be recorded before publication.

## Preflight findings

- All initial frontend/native tests passed. Real App Cmd-F found Alpha 1/2, next advanced to 2/2, and a disk edit changed the query result to 1/3 without clearing the search.
- Switching to source then reverted to the original two matches: SwiftUI supplied its older FileDocument text on presentation updates. Added DocumentContentState to preserve watched disk bytes until the model changes, with same-document and cross-document regression tests. This blocks publication until the native flow is repeated successfully.
- The unsigned Debug diagnostic copy failed deep verification at Sparkle. It was used only for this UI reproduction. A separately signed local Release build passed all nested signature/entitlement checks; the shipping bundle will still be built remotely for macOS 11.
- Expanded real-WebKit integration to search/refresh, outline/source positions, RTL, theme/font/zoom, help, QuickLook Typst and clean HTML export. The first help check used the wrong class selector; corrected it to the actual help-overlay ID (no product change).

The corrected signed local Release was opened by its exact path. A further disk edit added Alpha final refresh; native source and preview accessibility snapshots both retain it. All 16 production-WebKit cases pass and 297 native tests pass locally. Final-payload checks follow below.
