# October 2026 release acceptance

Baseline: 1447335; 36 local commits beyond origin/master. User authorizes pre-release acceptance and publication, including Homebrew and released issue replies. Existing direct QuickLook Cmd+F and automatic dismissal exclusions remain in effect. #49 reporter-specific failure remains unconfirmed and is not claimed fixed.

## Blocking evidence

- `make app` on local Xcode 27 fails: minimum supported deployment target is macOS 12; project promises macOS 11. Do not raise the deployment target to make the build pass.
- Use pinned Xcode 16.4 on GitHub's macos-15 runner, which currently lists that toolchain, to build and test the shipping macOS 11 target. Preserve both Intel and Apple Silicon slices and verify signed nested bundles.
- CHANGELOG currently overclaims direct preview Command-F; correct to the verified one-click main-app search handoff.
- PR #56 now includes unrelated fork/distribution/review changes. Only the original attributed YAML-date fix is in this release; do not merge the expanded PR wholesale.
- Production Homebrew tap still uses deprecated postflight. Installer candidate needs real lifecycle tests; only trust the task's specific cask during testing, using Homebrew's supported trust command.

## Acceptance checklist

- [x] Full frontend/native suites and release macOS 11 build
- [x] Runtime URL routing across concurrent documents, sidebar/status and retained search route
- [x] Signed payload, both architectures, deployment target, package resources
- [x] Real Homebrew install, reinstall and upgrade; preserve editor choices
- [x] Release notes accurately reflect scope and contributors
- [x] Published DMG/source archive, tag, Sparkle feed and Homebrew verified
- [x] Released fixes receive matching-language replies and done labels; unresolved reports remain explicit

## Toolchain validation follow-up

Release build 38021740061 compiled the macOS 11 target on Xcode 16.4 but failed
`QuickLookGestureArbitrationTests.testDoubleClickRecognizerCannotPreventWebViewPan`.
The test required WKWebView to expose a native NSPanGestureRecognizer, an OS-dependent
implementation detail. The override unconditionally permits every NSPan subclass;
the test now always checks a real AppKit pan and additionally all WebKit pans present
on that runtime. No production gesture behavior or runtime test is skipped.

## Completed local preflight

- Internal Markdown links, notification tests and four signed installer transaction tests pass.
- Native concurrent URI opens for `/tmp/flux-release-navigation/first.md` and `second.md`
  independently retain `Alpha 20` and `Beta 20`; switching windows without another
  navigation request confirms isolation (both show 67%).
- Packaging now refuses mismatched versions and development acceptance bundles;
  both failure paths tested before producing a DMG.
- Sparkle signing key is available locally (old published DMG signing preflight passed).
- Scratch Homebrew cask `xykong/release-acceptance/flux-markdown-acceptance` explicitly
  trusted via `brew trust --cask`; old 1.34.475 app-artifact install succeeded into
  `/tmp/flux-homebrew-acceptance/Applications`. No global trust checks disabled.
- Native line-based requests also remain file-scoped: line 19 in first.md lands at
  Alpha 5 (15%); line 99 in second.md lands at Beta 25 (85%).
- Real scratch Homebrew migration reinstall, new-installer reinstall, uninstall and
  clean install all succeeded. Before/after editor snapshots are byte-identical:
  Markdown UTI remains FluxMarkdown and public.markdown remains Microsoft Word.
  PluginKit lists the extension enabled. Genuine newer-version upgrade awaits the
  final versioned payload; no deprecated postflight hook was used by the candidate.
- Local Sparkle preflight signature exactly matches the published 1.34.475 enclosure,
  proving the signing key has not silently changed.

## Final package and runtime acceptance

- CI 38021901527: 340 frontend tests pass; 283 native tests, zero failures, one
  environment skip (adjacent tap checkout absent). The skipped draft-placement
  condition was independently checked against the real adjacent checkout.
- Release build 38022209755 for tag v1.35.521 / 873222ec6c1523796987814b94402444cb008e3f
  passed tests and produced the signed universal app. App, extension and launch
  service each have arm64 + x86_64 slices with minos 11.0 / SDK 15.5.
- Xcode 27's local lipo rejects multiple verify_arch values despite its help text;
  verifying each architecture separately succeeds. No binary changes required.
- Real Finder preview became observable by selecting its CoreGraphics layer-3
  window ID, which the normal window list omits. Wide screenshot confirms separate
  document/sidebar, status and rightmost contents entrance. Actual search-button
  click opened first.md in the app, focused the field and accepted Alpha (1/31).
  Full-size remote renderer was also captured; host compositing and transition
  screenshots must not be confused with settled document layout.
- Final DMG SHA256: ae24257526fcb0c78fb571f9c616da55f75623e1780d3061c4bcc676d8350d4c.
- Real Homebrew upgrade of the scratch cask from 1.34.475 to the final 1.35.521
  payload succeeded with no deprecated flight hooks. Editor snapshots remained
  identical. Installation is isolated in /tmp/flux-homebrew-acceptance/Applications.
- MacPorts source archive is now generated from the immutable release tag, not
  whichever administrative commit happens to be HEAD during packaging.

## Homebrew 7 production upgrade regression

`brew update` moved the local Homebrew from 5.1 to 7.0.9. Unlike the scratch
installation, the production upgrade from recorded 1.21.266 removes the app at
/Applications before invoking the new installer. A temporary bash trace (local
cask only, restored afterwards) captured the cause: the snapshot returned Xcode
for net.daringfireball.markdown while the application was absent, although the
persisted explicit LSHandlerRoleAll remained com.xykong.markdown. Registration
then restored the real FluxMarkdown association; the installer incorrectly tried
to preserve the transient Xcode fallback and rejected its own result. Homebrew
rolled back. Original editor choices remained intact. #53/#55 have not received
done labels or release replies.

Fix criterion: preserve an explicit preference for this application through its
own temporary removal, without overriding explicit other-editor choices, ignoring
errors, or disabling restoration checks. Conflicting role-specific preferences
must keep the system-resolved choice. Re-test the actual production upgrade on
Homebrew 7 before publishing a patch.

## Homebrew 7 patch acceptance

The new snapshot honors an unambiguous persisted LSHandlerRoleAll preference for
FluxMarkdown when Homebrew's temporary removal causes a resolved fallback. Other
editor and conflicting role-specific preferences continue to use the system's
resolved handler. Restoration still checks the actual LaunchServices result and
still fails/rolls back on a real mismatch; errors are not suppressed.

- Added two regressions (temporary self-removal and other/conflicting roles), with
  the unchanged failed-restoration regression retained. Seven focused tests pass.
- v1.35.525 / 9a21bac0197cf146ff80c449f5c8959176268a4f was built by release run
  38022936344 with macOS 11 target, both architectures and verified nested signatures.
- Temporarily pointed only the local production cask to the exact prepared DMG,
  then restored its original text. The real Homebrew 7 upgrade from the recorded
  1.21.266 into /Applications succeeded. This reproduces the earlier failing path.
- Independent raw LSCopyDefaultRoleHandlerForContentType reads (not the modified
  snapshot helper) before/after are identical: com.xykong.Markdown for the Markdown
  UTI and com.microsoft.Word for public.markdown.
- The patch will supersede 1.35.521 for recommended installation. Feature fixes in
  1.35.521 remain valid; installation issues #53/#55 are only resolved by this patch.

## Published outcome — 2026-10-10

Recommended release: [v1.35.525](https://github.com/xykong/flux-markdown/releases/tag/v1.35.525).

- DMG SHA256 `abba51a66a00f7b914c4d0d80940d2ecd2358867e0c215bc5ecac93ba6d45c6d`.
  Downloaded the public asset and matched its bytes to the prepared package.
- Source archive SHA256 `0ba3a31e2704d22189613ec7dfc66f71b5a18092ab0398b5af28bba2c45b0762`.
  GitHub's uploaded asset digest matches the prepared archive.
- Public Sparkle feed's version, URL, size, EdDSA signature and macOS 11 minimum
  match the shipped DMG. Tap commit `1eee259` publishes the same version/checksum.
- Homebrew 7 online reinstall and isolated clean install passed after the real
  1.21.266 → 1.35.525 production upgrade. Independent resolved editor snapshots
  stayed unchanged. Scratch installation/tap/trust entry were removed afterwards.
- Final installed app reports v1.35.525; PluginKit reports its extension enabled.
  Installed app/extension renderer hashes match the verified remote build.
- Native 760-point window acceptance now uses the existing validated search-handoff
  frame URL instead of unreliable border dragging. Directory defaults closed;
  selecting Alpha 10 closes the overlay, updates the breadcrumb and returns focus
  to the directory button. Restoring 1279×812 brings back the docked sidebar.
  Dark appearance and native zoom were visually checked; system appearance and
  zoom 1 were restored. Evidence is in `build/release-acceptance/` (local only).
- Release build ran 340 renderer tests and 285 native tests with zero failures;
  one native environment skip concerns the absent adjacent tap checkout, whose
  condition was independently verified locally. macOS 11 and Intel compatibility
  are build-validated, not a claim of testing on physical macOS 11/Intel machines.
- #50/#51/#52/#53/#55 received English release replies and `done`; all remain open.
  The first three replies recommend the installation patch as well. #54 received
  an accurate released-alternative explanation without `done`; #49 remains an
  unconfirmed reporter-environment issue. No issue was closed.
