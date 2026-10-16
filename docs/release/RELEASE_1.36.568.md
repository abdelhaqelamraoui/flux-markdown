# Release verification: 1.36.568

Published 2026-10-16 following explicit authorization to release the #59 fix and mark it corrected.

- [Release](https://github.com/xykong/flux-markdown/releases/tag/v1.36.568), tag commit `9522111861b59ec30146c288b0707b6aceec6743`.
- [Release build](https://github.com/xykong/flux-markdown/actions/runs/38876414384): 361 renderer tests and 18 real WebKit cases pass. Native suite: 315 cases, no failures, one skipped adjacent-Homebrew-checkout test (315 cases previously passed locally without skips).
- Xcode 16.4 produces arm64/x86_64 host, extension and launcher with macOS 11 deployment targets. Bundle provenance, signatures, sandbox and portable read-only home permission verified. No macOS 11 runtime machine was used.
- Final DMG installed before publication. The formal build's actual QLPreviewView self-test returned `quicklook_preview=rendered`.
- Prior Finder A/B acceptance reproduced the old home-folder image failure and verified images in home, Downloads and Documents after the permission fix. A new Finder screenshot attempt during publication was blocked by Accessibility reads despite reported granted permission; it is not counted as a fresh visual acceptance pass. Final entitlement verification and actual self-test passed.
- GitHub published assets match manifest digests; publication retry downloaded and byte-compared both assets. Sparkle public feed reports 1.36.568/build 568 with a signed download enclosure.
- DMG SHA-256: `5064a38108a8a9858ca692f75f04551058169ea540b6d9ee0548638b1a96dac0`.
- MacPorts source SHA-256: `15f4e0f085cfa5ac5304031b63d62182d483fdebfb05f7903d532c594a07890e`.
- Homebrew tap and official draft updated in tap commit `683e760`. Real Homebrew upgrade 1.36.561 → 1.36.568 succeeded. Installed version and brew metadata agree; strict signature verification passes and default editor snapshots are unchanged. No official Homebrew submission performed.
- #59 received `done` and an [English confirmation](https://github.com/xykong/flux-markdown/issues/59#issuecomment-6211966535) with release, fixes, limitations and update instructions. Read-back verified label/comment; issue remains OPEN for the reporter to confirm and close.
- #49/#58 remain unconfirmed. The new self-test/diagnostic features are now published, but this is not proof that the original plain-text fallback reports are fixed. The overall three-issue goal remains blocked on affected-machine evidence.

External-volume/local privacy permissions remain a documented boundary. No broader filesystem access or universal third-party-host support is claimed.
