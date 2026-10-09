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

## Full backlog objective — 2026-10-09

The user clarified the goal: resolve every open issue, including the two feature
requests. Refresh confirms seven open issues (#49–#55), six distinct work items,
and pending PR #56. Public release remains v1.34.475. Triage and proposals are
not implementation completion; locally passing tests are not release completion.

### Remaining work

- [ ] #54: complete real Finder keyboard/focus acceptance, investigate any remaining failure.
- [ ] #49: reproduce provider fallback on the affected environment, obtain targeted reporter evidence, implement and verify the identified fix.
- [ ] #53/#55: define a supported installation/registration path, validate compatible Homebrew versions and real clean-install/upgrade/reinstall behavior, then migrate the tap safely.
- [ ] #52: review the existing positional-navigation proposal, implement URL targets and original source mapping, and verify already-open and concurrent documents.
- [ ] #50: review the existing sidebar proposal, implement responsive nonoverlapping contents, and verify QuickLook, full screen, print and export.
- [ ] PR #56: validate YAML date and recursive array behavior before integration.
- [ ] Publish verified fixes/features with app/extension packaging, Sparkle and Homebrew validation. Resolve the current SDK/deployment-target validation constraint without silently changing supported macOS versions.
- [ ] After confirmed release, reply in each issue's language with the exact version and update instructions, and add done. Leave closing to the reporter.

### Completion criteria

Every distinct issue has a reproduced or otherwise demonstrated cause/requirement,
verified implementation, and a published version users can install. Duplicates
inherit the same verified fix. Requests needing external evidence remain explicitly
pending; proposals and diagnostic scripts alone do not satisfy the corresponding
fix. Feature implementation follows the repository's proposal review requirement.


## Implementation round — 2026-10-09

The user explicitly authorized all existing plans to be implemented before their
acceptance. Positional navigation and responsive contents are implemented; PR #56
is integrated locally with its author preserved and extra regression coverage.
Standard Find menu bridging, per-type editor preservation, headless recovery and
transactional vendor placement/rollback are implemented. Production cask promotion
is guarded by DMG helper presence and stays deferred until release.

314 renderer tests, 62 related native tests and four vendor transaction tests pass.
Actual installation preserved current handlers. Browser geometry/source navigation
checks pass. Native UI/Finder verification is currently blocked: IOConsoleLocked
and CGSSessionScreenIsLocked are true; no app windows are accessible. A scratch
Homebrew Loader test stopped at the trust gate without changing policy.

This is an implemented candidate, not evidence that every issue has been resolved
in its reporter environment. The remaining runtime matrix is documented in
docs/testing/ACCEPTANCE_ALL_ISSUES.md. User acceptance is not requested until
the blocked native checks have been completed or their scope explicitly addressed.

## Unlocked console follow-up — 2026-10-09

IOConsoleLocked is now false. Restarting the candidate restored application AX
access. Native wide/fullscreen contents layout and application search are verified.
Found and corrected search/native toolbar overlap, then verified the rebuilt UI.
Also reproduced a lost cold-start URL event and moved Apple Event registration to
will-finish-launching; cold-start source-line navigation is now visible and logged.
The URL handler no longer prints raw URLs.

Finder preview AX content identifies the candidate renderer, but the automation
provider associates its remote panel with the underlying Finder CG window. Keyboard
and screenshot observations can therefore target Finder instead of Quick Look;
Finder search is still not declared passed. VS Code switching remains unproven:
the modern NSWorkspace completion did not arrive within eight seconds after unlock,
and prior editor choices were restored/read back. See the updated acceptance matrix.

The reporter subsequently confirmed Cmd+F still opens Finder search during manual
Quick Look testing. #54 is a real failed acceptance test, not only an automation
limitation. Added a native search button as a direct fallback; 20 native search and
toolbar tests pass, while the Finder shortcut remains unresolved. See
DEBUG_ISSUE_54_QUICKLOOK_SEARCH.md for the diagnostic comparison and API evidence.
