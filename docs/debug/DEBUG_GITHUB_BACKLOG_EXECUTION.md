# GitHub backlog execution — 2026-10-08

Baseline: `3911a15`. Public release is still `v1.34.475`.

| Item | Outcome | Remaining dependency |
| --- | --- | --- |
| #51 | Bare URL linkification fixed; five focused regressions and real App click-to-browser verification pass | Publish a tested release before done/release reply |
| #54 | Native responder bridge, pending-render handling, repeat-safe DOM Find, and WebKit focus correction committed | Manual Finder remote-window Cmd+F acceptance; synthetic automation was not reliably targeted |
| #49 | Read-only sanitized collector and corrected support guidance; platform label changed to Sequoia | Obtain reporter-environment evidence; root cause remains unconfirmed |
| #53 | Migration compatibility/source investigation recorded | Supported packaging/registration design and real install/reinstall matrix before replacing legacy flight block |
| #55 | duplicate label added; existing comment already links #53 | Track the same migration; keep open |
| #52 | Positional URL navigation proposal/spec/design/tasks created and strictly validated | Proposal review before feature implementation |
| #50 | Nonoverlapping responsive TOC sidebar proposal/spec/design/tasks created and strictly validated | Proposal review before feature implementation |

## Validation

- Renderer: 308 tests, 30 suites passed.
- Native: 24 related tests passed, including five QuickLook search cases.
- App/extension Debug build and development installation/signature verification passed.
- Installed development version: `1.34.475-dev-20261008-203804`.
- Actual App renders the five references as blue links, native bridge opens the Caddy URL,
  and the browser visibly shows Welcome — Caddy Documentation at the expected URL.
- App Cmd+F displays search, Alpha matches show 1/2, and Escape hides the search UI.
- Finder actually loads the extension and completes renderer handshake, but the automation
  provider confuses the remote panel with the underlying Finder window for keyboard focus.
  This is not an end-to-end Find shortcut pass. A manual acceptance question has been sent
  to the user; no answer has been assumed.
- Validation used MACOSX_DEPLOYMENT_TARGET=12.0 as a build-time override for this SDK.
  The project's macOS 11 target was not changed; macOS 11 compatibility is not claimed.

## GitHub state and release discipline

#49 and #55 labels were read back to verify the edits; both remain OPEN.
No done labels or release claims were added because the fixes have not shipped.
English reporter-reply drafts for #49/#53 are in the corresponding debug documents;
they have not been posted. The tap worktree is unchanged.

## Additional PR review

PR #56 diff was inspected: the Date-object conversion addresses the YAML date-only symptom.
Its array renderer also changes nested-object/null handling, so date arrays, nested values,
nulls and escaping should be covered before release. The PR was not merged or declared
validated; tests quoted by its author are not a substitute for local review validation.
