# Release verification: 1.36.561

Published 2026-10-16 after the user accepted the full-width preview and authorized publication.

- [Release](https://github.com/xykong/flux-markdown/releases/tag/v1.36.561) is public and not a prerelease.
- [Pinned release build](https://github.com/xykong/flux-markdown/actions/runs/38868019214) passed: 361 renderer tests, 18 real WebKit cases, 309 native cases with zero failures and one skipped adjacent-Homebrew-checkout test. The skipped check concerns packaging repository layout, not the width change.
- The width regression fails against the old bundle and passes with the fix. App/QuickLook contexts, 1800px/600px widths, sidebar space and oversized-table overflow are checked in real WebKit. User confirmed the installed preview meets expectations.
- Final host, extension and launcher binaries contain arm64/x86_64 with macOS 11 deployment targets. Nested signatures and release entitlements verified. macOS 11 runtime testing was not performed.
- Final DMG installed before publication; subsequent real Homebrew upgrade from 1.36.556 to 1.36.561 succeeded. Installed app and Homebrew metadata report 1.36.561. Default editor snapshots are identical and installed signatures pass strict verification.
- Public Sparkle feed reports version 1.36.561/build 561, macOS 11 minimum, signed enclosure length 36,740,358 bytes.
- DMG SHA-256: `9c3eda663958094aea858cef2c2b8a378dd91f5b6658446d58899892ae18b0f7`.
- MacPorts source SHA-256: `98e8a92392acf6f05af3de3ed3b63d639800d833aae01c0eff85c12cead66d36`.
- GitHub asset digests match the prepared manifest; publication retry downloaded and byte-compared assets. Existing verified Sparkle entry retained during retry. Homebrew cask and official draft updated in tap commit `53873f4`; no official Homebrew submission performed.

Final production install replaces the local development preview. No issue messages were sent.
