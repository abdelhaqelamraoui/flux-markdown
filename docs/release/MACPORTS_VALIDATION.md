# MacPorts submission validation — 2026-10-28

Scope: respond to macports/macports-ports#32298 review requesting the xcode PortGroup and a variable distname. This does not change the DMG release or the separate issue-61 update investigation.

Acceptance: the published source archive must pass checksums, extract into the configured worksrcdir, compile and stage through the actual MacPorts xcode PortGroup, retaining the Quick Look extension and renderer. Future release metadata updates must preserve `${version}` in archive paths.

## Changes

- PortGroup xcode 1.0 now owns build and destroot; version 1.40.622 and published checksums.
- `distname FluxMarkdown-${version}-macports-source`, `worksrcdir FluxMarkdown-${version}` match the actual tarball.
- Minimum deployment target 12.0 matches the port's existing Darwin >=21 restriction and current Xcode support. This is specific to this port, not a change to the DMG's OS policy.
- DerivedData remains under the work directory so MacPorts' sandbox does not block user-library log writes.
- Swift's nested macro sandbox is disabled using OTHER_SWIFT_FLAGS, following the existing aqua/abendrot pattern. MacPorts' outer sandbox remains enabled. No application entitlements are removed.
- Ad-hoc signing preserves project entitlements. No privileged post-activate Quick Look registration in the wrong user's session; notes describe opening the app and its repair action.
- Tcl argument expansion is used when sharing build/destroot settings; otherwise braces become part of xcodebuild arguments.
- Release script no longer rewrites the variable distname. Regression test first reproduced the old rewrite, then passed after removal.

## Verified

Environment: macOS 27.0.1, arm64, Xcode 27.1; isolated user-prefix MacPorts 2.12.7 built under /tmp. No activation or replacement of the user's installed app.

- Published tarball SHA-256: `744f6f33c931c3331d12e1cd2ecf96a8223e0b4d9ff739b476178e0e2326dc38`; size 23980254.
- `port lint --nitpick`: 0 errors, 0 warnings.
- `port -v destroot`: actual checksum, extract, configure, build and staging succeeded with MacPorts' sandbox enabled.
- Staged app version 1.40.622; embedded MarkdownPreview.appex present; `codesign --verify --deep --strict` passed for app and extension.
- Renderer index.html bundled; no Sparkle.framework in staged app.
- `python3 scripts/tests/macports-export.test.py`: 2 tests passed, including XcodeGen validation of the Sparkle-free export.

Local logs: `/tmp/flux-growth-validation-20261028/port-destroot.log`; port checkout: `/tmp/flux-growth-macports-20261028`.

Limitations: no Intel build or clean-machine GUI activation test was performed. Upstream CI/review and actual installation remain separate from staged-build validation. Source tarball contains the generated Xcode project and prebuilt web renderer; native app and extensions are compiled locally.
