# Release verification: 1.36.556

Published 2026-10-12. User authorized verification followed by publication.

## Payload and automated checks

- Release tag: `v1.36.556`, commit `4b6066c8f108701abeb0b6c1fce713a844db6ead`.
- [Release build](https://github.com/xykong/flux-markdown/actions/runs/38255524827) succeeded using Xcode 16.4 on macOS 15.
- Renderer: 41 suites / 361 tests passed. Production WebKit: all 16 cases passed.
- Native: 309 cases, zero failures, one skipped because CI lacks the adjacent Homebrew tap checkout. Both HomebrewTapTests passed locally, including that skipped check.
- Five isolated publication failure/retry tests passed.
- Host app, QuickLook extension and trusted launcher contain arm64 and x86_64 with macOS 11 deployment targets. Nested signatures and release entitlements passed verification. Minimum-OS runtime acceptance was not performed on a macOS 11 machine.
- Final DMG installed locally before publication. Preview showed the formal version, without prematurely displaying a reminder. PDF export produced a valid 25-page document.

## Published channels

- [GitHub release](https://github.com/xykong/flux-markdown/releases/tag/v1.36.556) is public, not a draft or prerelease. Both uploaded asset digests match the prepared manifest; publication retry also downloaded and byte-compared the assets.
- DMG SHA-256: `9ffaf9f604cadeec22780b67c9025cdd5cc6b66cd709d8f28f909609eba68eba` (36,738,769 bytes).
- MacPorts source SHA-256: `f6640ed5ae495c44f680b432de9c9ebf5d1e8db6860fff2152ccd29b815df363`.
- Public Sparkle feed contains version 1.36.556 / build 556, minimum system 11.0, the matching download length and EdDSA signature.
- Homebrew tap and official-cask draft updated in tap commit `11aa088`. The draft was not submitted to the official Homebrew repository.
- Real `brew upgrade --cask xykong/tap/flux-markdown` succeeded from recorded 1.35.547 to 1.36.556. Installed app and Homebrew metadata agree, and strict nested signature verification passes.
- Default editor snapshots remained byte-identical. Reminder state remained semantically identical across both vendor installation and Homebrew upgrade (JSON key order may change).

## Publication recovery

The Homebrew updater intentionally returned status 2 for prepared but uncommitted cask changes. Those two files were committed and pushed explicitly. A noninteractive retry encountered the existing-feed replacement prompt; it was answered `n` to retain the already verified feed, then publication completed. No existing release assets were overwritten. Final publication status is complete.

The machine now has the formal release rather than the prior development preview. Reminder UI scenarios, cooldowns, keyboard behavior, accessibility names and layouts were verified during implementation; see [reminder design and acceptance](../design/DESIGN_STAR_REMINDERS.md). No GitHub account was starred or unstarred during testing.
