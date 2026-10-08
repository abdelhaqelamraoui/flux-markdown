# Unified acceptance candidate

## Scope

This candidate contains the URL-position feature (#52), responsive contents sidebar
(#50), bare links (#51), native/menu Find bridges and focus fixes (#54), YAML dates
(PR #56), settings history/feedback, QuickLook recovery, and vendor installation
transaction changes (#49/#53/#55). This is not a public release or a claim that every
reporter-environment failure has been reproduced.

## Automated evidence

- 314 renderer tests across 33 suites passed.
- 62 related native tests passed.
- Four signed-stub vendor transaction tests passed.
- Real vendor installation and current per-type editor preservation passed.
- Browser layout, reload visibility, narrow/compact context and original-line
  navigation checked through the actual renderer harness.
- Full Homebrew Loader test stopped at the untrusted scratch-tap gate; no trust
  policy was changed. Candidate syntax passed; promotion waits for the new DMG.

## Still needed before declaring all issues resolved

The local console is locked, so native Finder UI cannot be reliably exercised.
The original #49 Sequoia environment is not available. These are explicitly pending:

1. Finder Space → Cmd+F, type Alpha, repeat Find, Escape, and full screen (#54).
2. Finder rendered previews while VS Code remains default editor (#49).
3. Homebrew clean install/reinstall/upgrade of the new payload in a trusted test
   context, preserving editor choice and real extension behavior (#53/#55).
4. Native App URL navigation for new/already-open/concurrent files and fullscreen.
5. Native sidebar layout at narrow/wide sizes, theme/zoom, print/PDF/HTML export.

## Fixture and commands (after remaining automated/runtime work is complete)

Use `Tests/fixtures/acceptance-all.md`. It contains date metadata, searchable Alpha,
forty headings and code blocks. URL example:

```
markdownpreview://open?path=/Users/xykong/workspace/xykong/flux-markdown/Tests/fixtures/acceptance-all.md&line=166
```

Help → Repair Quick Look uses checked headless registration and preserves current
editors. Help → Report an Issue previews diagnostics; settings history remains local
until the user continues to GitHub. No Issue has been marked done for unshipped fixes.

The current SDK requires a build-time macOS 12 override; Big Sur compatibility is
not verified and production deployment settings are unchanged.
