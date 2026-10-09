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

The user unlocked the console on October 9. Native application verification now
works after restarting the candidate. The original #49 Sequoia environment is not
available. These are explicitly pending:

1. Finder Space → Cmd+F, type Alpha, repeat Find, Escape, and full screen (#54).
2. Finder rendered previews while VS Code remains default editor (#49).
3. Homebrew clean install/reinstall/upgrade of the new payload in a trusted test
   context, preserving editor choice and real extension behavior (#53/#55).
4. Concurrent-file URL navigation.
5. Native sidebar layout at narrow sizes, theme/zoom and printing.

The unlocked console verified Chinese native controls, YAML date display, docked
900-point sidebar without covering the document, and a settled 1920-point full
screen layout. Application Cmd+F, Alpha match count 1/2, repeat Find retaining the
query, and Escape were verified. Search initially overlapped the native toolbar;
the follow-up stylesheet fix moved it below the toolbar and before the sidebar.

Native HTML export saved `/tmp/flux-unlocked-export.html`; the document contains all
forty sections and the metadata date, and excludes search/contents markup. Opening
the exported file in Chrome verified full-width readable content without a sidebar
or a reserved sidebar gap.

Cold-start URL navigation initially lost the launch event. Registering the Apple
Event handler in `applicationWillFinishLaunching` fixed this: source line 166
opened at Section 20, with a successful native navigation result and screenshot.
Already-running application navigation also reached its target.
Fragment `#section-40` visibly reached Section 40 in the final candidate. The three
DocumentPosition and six QuickLookSearch native regressions passed again after
the launch-handler change (nine tests, zero failures).

Native PDF export produced an unencrypted 21-page A4 document; text extraction
contains all forty headings and the date and no contents sidebar. The first rendered
page shows readable full-width text without toolbar/contents controls. All 21 pages
were rendered and reviewed as a contact sheet. Section 2 is left as an orphan
heading at the end of page 1, so pagination polish remains a recorded follow-up;
the existing print CSS already requests `page-break-after: avoid`.

Finder Space produced candidate-version rendered content in the accessibility
tree. The automation provider binds that remote panel to the underlying Finder
CG window, so its screenshot/keyboard recipient can be wrong. Cmd+F in Finder
is still unproven; synthetic input success is not a pass. The supported modern
default-editor setter did not complete within eight seconds even while unlocked;
the previous editor values were restored and read back. VS Code preservation
therefore remains unproven.

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


## Candidate artifact

Installed development version: `1.34.475-dev-20261009-102822`.

DMG: `build/artifacts/FluxMarkdown-Acceptance.dmg`

SHA-256: `750713d0b8c287958eb8864154ac8435992de295a982bb25dd19337289a6080e`.

The compressed image verifies successfully and contains the signed development app
and vendor installer. It has not been published, notarized, or promoted into the
production tap. Remaining runtime checks are listed above; the console is unlocked.
