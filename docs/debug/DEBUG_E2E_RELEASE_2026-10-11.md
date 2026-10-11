# End to end release acceptance 2026 10 11

Baseline: 1c063dc. User requested comprehensive local end-to-end validation followed by a new release. This authorizes preparation, local installation validation, GitHub publication, Sparkle feed and Homebrew tap updates. No issue replies are requested.

Environment: macOS 27.0.1, arm64, Xcode 27. Local diagnostics use an explicit macOS 12 target; shipping artifacts must come from the pinned Xcode 16.4 universal macOS 11 build. Existing exclusions for direct Finder QuickLook Command-F and physical gesture acceptance remain as documented in ACCEPTANCE_ALL_ISSUES.md; the supported search-button handoff will be verified.

## Acceptance matrix

- [x] Renderer tests, typecheck, real WebKit production assets, dependency audit.
- [x] Native App open, search, source/preview, navigation, theme/zoom, refresh, exports.
- [x] Finder QuickLook rendering and search handoff from the final payload.
- [x] Universal release signatures, entitlements, minos, resource provenance, DMG.
- [x] Final local installation, editor preference preservation and PDF/export checks.
- [x] Public assets, Sparkle feed and Homebrew version/checksum verification.

Evidence is retained under build/e2e-20261011 (local artifacts). Results will be recorded before publication.

## Preflight findings

- All initial frontend/native tests passed. Real App Cmd-F found Alpha 1/2, next advanced to 2/2, and a disk edit changed the query result to 1/3 without clearing the search.
- Switching to source then reverted to the original two matches: SwiftUI supplied its older FileDocument text on presentation updates. Added DocumentContentState to preserve watched disk bytes until the model changes, with same-document and cross-document regression tests. This blocks publication until the native flow is repeated successfully.
- The unsigned Debug diagnostic copy failed deep verification at Sparkle. It was used only for this UI reproduction. A separately signed local Release build passed all nested signature/entitlement checks; the shipping bundle will still be built remotely for macOS 11.
- Expanded real-WebKit integration to search/refresh, outline/source positions, RTL, theme/font/zoom, help, QuickLook Typst and clean HTML export. The first help check used the wrong class selector; corrected it to the actual help-overlay ID (no product change).

The corrected signed local Release was opened by its exact path. A further disk edit added Alpha final refresh; native source and preview accessibility snapshots both retain it. All 16 production-WebKit cases pass and 297 native tests pass locally. Final-payload checks follow below.

## PDF visual release blocker

The mixed-diagram PDF was rendered page by page. Native Typst glyphs were effectively absent and Graphviz node labels were invisible. The sanitized Typst SVG lacked use elements (only glyph defs/selection text survived); its embedded global svg { fill: none } rule affected subsequent diagrams. Candidate v1.35.537 is not approved for publication. Cancel its in-progress remote build and prepare a new immutable version after fixing and visually verifying this regression.


The SVG fix now retains only fragment-local use references, removes Typst's global styles/selection overlay in an inert HTML template, and applies scoped glyph styling. Rendering Typst as a standalone block also avoids code-block backgrounds. A sum formula exposed non-XML selection metadata, so the implementation deliberately avoids strict XML parsing. Actual PDF pages now show the Typst sum, Graphviz a/b labels, Mermaid and Vega together; native math dimensions track the surrounding font. Renderer regressions and strengthened real-WebKit checks cover these failures.


## Final candidate acceptance

- Version 1.35.539, tag commit cb3064c46eb8e6868d4d3f1b0887716e82fc3c52. Remote release build 38103547388 succeeded on Xcode 16.4: 355 renderer tests, all 16 real WebKit cases and 297 native tests (one adjacent-tap environment skip; the local suite passed without this skip).
- Downloader verified provenance, archive checksum, nested signatures, arm64/x86_64 and macOS 11 minos for the app, extension and XPC service. DMG and MacPorts source archive were prepared before publication.
- The exact DMG payload was copied to a writable staging directory (the vendor/Homebrew install contract) and installed into /Applications. A direct invocation against the read-only mounted source first rejected xattr removal without changing the installed app. The supported staged install succeeded, signatures verified and before/after default-editor JSON matched byte for byte.
- Installed app and Finder QuickLook both display v1.35.539. Preview process path is /Applications/FluxMarkdown.app/Contents/PlugIns/MarkdownPreview.appex. Real Finder Space preview shows metadata, contents, text and status; the search button opens the correct file in the app and accepts Alpha with result 1/5.
- A real 500 KiB boundary splitting a Chinese character displays Large UTF8 and Preview truncated in Finder, with no Encoding Error.
- Both native menu HTML/PDF exports and CLI success/failure paths were exercised. Final shipping PDF was rendered and inspected: Typst sum, Graphviz labels, Mermaid and Vega all visible. Native HTML includes current watched text and styles, excludes application controls. Theme cycle, zoom/reset, settled contents navigation to Section 20 and full-screen layout were observed; theme and zoom were restored.
- Installed resource index matches the remote artifact. All 16 WebKit cases passed again against /Applications resources.
- DMG SHA256: cd7aed84f3d42c83cb3c7c4f7733d79c1f249fc6d85c7de9e3d1590f121f9cd8.
- Source SHA256: 20fcf718c918698c48761112736d359df5f4ae4c928b588c97ca2ed05a02f6db.

Physical macOS 11/Intel and hardware-only trackpad gestures are not claimed verified on this arm64 macOS 27 host. Direct Finder Command-F remains the explicitly excluded system behavior; the supported search-button handoff passed.


## Published outcome

Published [v1.35.539](https://github.com/xykong/flux-markdown/releases/tag/v1.35.539). Both public asset digests match the prepared SHA256 values above. The public Sparkle feed's version, macOS minimum, enclosure URL/length and EdDSA signature match the locally signed feed. Homebrew tap commit e9931fe publishes the same version and DMG checksum; the official-compliant draft was updated alongside the tap.

The real Homebrew upgrade from its recorded 1.35.525 to 1.35.539 succeeded, including removal/reinstallation, registration and strict nested signature checks. Brew metadata reports installed=1.35.539 and the expected checksum. Default editor snapshots before testing, after vendor installation and after Homebrew upgrade are identical.

Publication was resumed after the tap commit: the script downloaded and byte-compared both existing GitHub assets, completed feed/tap checks and exited successfully. Publication status is complete. The source archive was additionally extracted and built without Sparkle locally (explicit macOS 12 diagnostic target on Xcode 27); shipping macOS 11 universal checks remain those of the verified remote build.

Temporary acceptance plug-in registrations created during this task were removed; the installed production extension remains enabled. No issue comments or closures were performed.
