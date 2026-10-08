# Issue #51: Bare URLs are not clickable

## Initial evidence

Issue: https://github.com/xykong/flux-markdown/issues/51
Baseline: `3911a15`; public release `v1.34.475`.
Both configure markdown-it with `linkify: false`. The reporter's five bare URLs
produce zero anchors, while explicit `[text](URL)` syntax works.

## Acceptance defined before implementation

- The exact reported URLs become five anchors in app and QuickLook contexts.
- Trailing punctuation is excluded; inline/fenced code remains literal.
- Explicit Markdown links retain their labels and targets.
- Generated links use the existing native linkClicked bridge.
- Unsafe schemes do not become clickable links.

## Validation

New regressions initially failed (4 failures / 5 tests). After enabling the existing markdown-it linkifier, all 5 pass; the complete renderer suite passes 307 tests across 29 suites. `make generate` rebuilt the renderer successfully. Combined native runtime verification follows with issue #54. This fix is committed locally and has not been released.


## Installed runtime verification

The installed App shows all five URL references as blue links while the inline
code URL stays literal. A real click on the Caddy reference produced native
linkClicked/open-external logs for the correct URL; the browser visibly opened
https://caddyserver.com/docs/ (Welcome — Caddy Documentation). App/extension
renderer assets match the rebuilt main asset. Finder also loads the installed
extension and renders the fixture; native AX output compresses inline anchors
into text containers and therefore is not an anchor-count assertion.
