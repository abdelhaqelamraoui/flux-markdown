# PR #56 review — 2026-10-10

Reviewed PR head `94cbdafc2642181375c61cfc594f2f3055611b22` against upstream
`654a847`. PR title/body still describe YAML dates, but the current diff changes
66 files. GitHub reports DIRTY and no current status checks/reviews. Read-only
`git merge-tree` confirms conflicts without modifying the worktree.

## Recommendation

Do not merge the current branch wholesale. The original attributed YAML-date
commit is already integrated as d811cab and shipped in 1.35.521/1.35.525 with
additional nested/array/cyclic-alias regressions. Ask for separate upstream-based
PRs for toast localization, license/About resources, and optional review mode.
Fork branding, Nix-only updater removal and personal fork publication should stay
on the contributor's fork. Closing the superseded original PR would require a
separate explicit user instruction; this review performs no external submission.

## Findings

1. **P1 — Removes upstream update/distribution behavior.** `project.yml` removes
   Sparkle, Info.plist removes SU settings, and appcast.xml is deleted.
   `scripts/release.sh:12–27` only accepts xluffy-fork remotes; release.yml:14 only
   builds for that repository. Merging makes upstream release fail and removes
   the feed used by existing users and Homebrew livecheck. These are intentional
   fork choices, incompatible with the upstream PR's stated date-fix scope.
2. **P1 — Exit/export destroys newly added inline markup.**
   `web-renderer/src/review-mode.ts:717–719` replaces a review-word-added wrapper
   with its textContent, discarding nested links/emphasis. Actual extracted module
   probe: old `hello old world tail`, new `hello <a href="https://new.test">new link</a>
   world tail`: one link during review, zero after clear; exported HTML loses href.
   Unwrap child nodes or restore original DOM rather than flattening it.
3. **P1 — Review state is not block/document isolated.** review-mode.ts:58–59
   derives IDs solely from type and normalized current text. Two distinct modified
   blocks with identical new text receive the same ID; marking one gives total=2,
   remaining=0. index.ts:906 falls back to baseUrl (directory), and native render
   callers do not provide documentKey. Thus sibling files also share storage keys.
   Use full document identity plus distinguishable block/baseline identity, while
   testing duplicate content, movement and repeated edits.
4. **P2 — Semantic-only changes are omitted.** review-mode.ts:77 compares only
   normalized textContent. Changing href from old.test to new.test with the same
   visible link text yields zero changes in the extracted-module probe. Images,
   destination changes and formatting need an explicit comparison policy and tests.
5. **P2 — Review mode activates on ordinary refresh without user choice.**
   index.ts:899 defaults reviewMode to enabled, baseline uses prevContent. Existing
   file-watch refreshes therefore replace transient diffs with persistent review
   controls, while no native review preference or toolbar entry exists. Make the
   feature opt-in and integrate it with current reading controls, localization and
   host persistence; define baseline lifecycle before upstream adoption.

## Validation and limits

- Extracted the exact PR review-mode.ts and transpiled it with installed TypeScript,
  executing controller/DOM cases with jsdom and the installed diff dependency.
  Reproduced link loss, duplicate reviewed state and href-only omission.
- Upstream YAML frontmatter/date regression tests were run to confirm the already
  accepted contribution. This does not claim the full PR passes CI or native runtime.
- Did not execute fork publishing scripts, install the fork, merge, close, or post
  review/comments to GitHub. Current production app and source remain unchanged.
