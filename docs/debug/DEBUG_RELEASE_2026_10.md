# October 2026 release acceptance

Baseline: 1447335; 36 local commits beyond origin/master. User authorizes pre-release acceptance and publication, including Homebrew and released issue replies. Existing direct QuickLook Cmd+F and automatic dismissal exclusions remain in effect. #49 reporter-specific failure remains unconfirmed and is not claimed fixed.

## Blocking evidence

- `make app` on local Xcode 27 fails: minimum supported deployment target is macOS 12; project promises macOS 11. Do not raise the deployment target to make the build pass.
- Use pinned Xcode 16.4 on GitHub's macos-15 runner, which currently lists that toolchain, to build and test the shipping macOS 11 target. Preserve both Intel and Apple Silicon slices and verify signed nested bundles.
- CHANGELOG currently overclaims direct preview Command-F; correct to the verified one-click main-app search handoff.
- PR #56 now includes unrelated fork/distribution/review changes. Only the original attributed YAML-date fix is in this release; do not merge the expanded PR wholesale.
- Production Homebrew tap still uses deprecated postflight. Installer candidate needs real lifecycle tests; only trust the task's specific cask during testing, using Homebrew's supported trust command.

## Acceptance checklist

- [ ] Full frontend/native suites and release macOS 11 build
- [ ] Runtime URL routing across concurrent documents, sidebar/status and retained search route
- [ ] Signed payload, both architectures, deployment target, package resources
- [ ] Real Homebrew install, reinstall and upgrade; preserve editor choices
- [ ] Release notes accurately reflect scope and contributors
- [ ] Published DMG/source archive, tag, Sparkle feed and Homebrew verified
- [ ] Released fixes receive matching-language replies and done labels; unresolved reports remain explicit

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
