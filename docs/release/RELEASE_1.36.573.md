# Release verification: 1.36.573

Published 2026-10-16 after the user accepted the cross-screen window-size fix.

- [GitHub Release](https://github.com/xykong/flux-markdown/releases/tag/v1.36.573) is public. DMG SHA-256: `9eb61766992295f52485769d601c93f9cd437ee1d21294e66bb3b750bba621a0`.
- [Release build](https://github.com/xykong/flux-markdown/actions/runs/38920875831) passed renderer, WebKit and macOS native validation. The targeted WindowSizePersistenceTests passed 41 cases locally; full release CI used the repository's native suite.
- Final dual-architecture Release artifact passed signatures, nested entitlements, macOS 11 deployment checks and release manifest verification.
- The formal DMG was installed locally. Homebrew upgrade from 1.36.568 to 1.36.573 succeeded after refreshing the local tap; installed app and cask metadata report 1.36.573, and strict nested signature verification passes.
- Sparkle feed and Homebrew tap are updated. Tap commit: `18476dd`. The official Homebrew draft was updated; no official submission was performed.
- Default editor preferences were preserved by the installer. No issues were closed or messaged as part of this release.
