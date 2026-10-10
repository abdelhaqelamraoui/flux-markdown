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
