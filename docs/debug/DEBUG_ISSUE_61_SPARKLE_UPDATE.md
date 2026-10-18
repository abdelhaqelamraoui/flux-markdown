# Issue #61: in-app update fails

## Baseline and acceptance

- Report: https://github.com/xykong/flux-markdown/issues/61
- Reported installed version: 1.36.568, macOS 26.4.1 (25E253), arm64.
- Screenshot: Sparkle reports “An error occurred while running the updater.” No underlying error is included.
- Source baseline: 1.36.582. Local host: macOS 27.0.1 (26A434).
- Reproduction target: an unmodified published 1.36.568 app checks for and installs a published newer release.
- Acceptance: capture the failing stage and underlying error, add a regression check before implementation, and verify the corrected update flow with real Sparkle installation. Preserve the existing installed app and document any environment differences or remaining limitations.
- No release or issue reply is included in this investigation.

## Investigation

- Current update delegate logs only localizedDescription using print; nested NSError details are not retained in the application diagnostic report.
- Published updates use Sparkle 2.8.1. Installer launcher XPC service is enabled in Info.plist.
- Existing historical update scripts either replace the installed app or change its signed Info.plist; do not use these as faithful reproduction of the reported update.

## Findings and change

- Copied the published 1.36.568 DMG app with `ditto` to an isolated build directory. Deep strict signature verification passed. Its actual Sparkle flow downloaded, verified EdDSA, extracted, installed 1.36.582 and relaunched; the resulting bundle also passed deep strict signature verification. The reported failure was **not reproduced** on this macOS 27 host.
- Sparkle logged a mismatch between the old/new ad-hoc code signatures, but accepted the valid EdDSA signature and completed installation. That message alone is not evidence of a failed update.
- The main host has no app-sandbox entitlement, but enabled `SUEnableInstallerLauncherService` and retained sandbox-only installer exceptions. [Sparkle's official customization guide](https://sparkle-project.org/documentation/customization/#sandboxing-settings) explicitly says not to enable that service for a non-sandboxed application. Removed the key and the host's obsolete installer exceptions. The Quick Look extension retains its sandbox.
- Added a bounded, persistent latest-failure diagnostic containing date, source/target versions, and at most eight allowlisted NSError domain/code pairs. Unknown domains become `other`. No descriptions, arbitrary userInfo, private URLs or document paths are persisted or exported. The host logs that safe summary via os_log, and Help → Report an Issue includes it alongside settings history.
- Last failure is explicitly historical; a later successful update does not turn it into current-status evidence.

## Verification

- Red: the new configuration test failed against the original Info.plist. Diagnostics tests initially failed to compile because the diagnostic type was absent.
- Green: 23 native tests passed: UpdateDiagnosticsTests, FeedbackDiagnosticsTests, ReleaseEntitlementsTests. Covers persistence across a new store instance, nested errors, privacy, depth bounds, no-history state, and Debug/Release host configuration.
- Renderer production build/typecheck passed while generating the project.
- Local Release candidate built with an explicit diagnostic-only macOS 12 minimum on Xcode 27.1. Its version/build were overridden at build time to 1.36.568/568 solely to exercise a real upgrade to published 1.36.582. No source version file was changed, and this local candidate is not a distributable macOS 11 build.
- Candidate deep strict signature and release-entitlement checks passed.
- The corrected Release candidate then completed the real public-feed download, EdDSA verification, extraction, installation and relaunch into 1.36.582 in its isolated directory. The installed version and deep strict signature were verified after the update. This tests updating **from** the corrected launcher configuration; the public target is unchanged. Local logs remain under ignored `build/issue-61/` and are not committed.

## Remaining reporter evidence

- This is a configuration correction and diagnostic improvement, **not a confirmed resolution of #61**. The reported host runs macOS 26.4.1, whereas local testing uses 27.0.1. The exact failed target version and underlying error are still unknown.
- An already failing old updater cannot receive its own launcher correction until the user installs a corrected app manually (DMG or Homebrew). Do not promise that simply publishing a new target fixes installation from every old build.
- On the affected machine, capture one failing attempt using Console / a bounded log stream filtered to subsystem `org.sparkle-project.Sparkle` and processes FluxMarkdown, Autoupdate, Installer, Updater. Preserve the failure before cache resets or reinstalls; review/redact private paths before sharing. The new diagnostic section only exists in builds containing this change.
- No GitHub reply, `done` label, issue closure or release has been performed.
