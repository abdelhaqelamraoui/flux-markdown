# Issues #52 / #50 implementation

The user approved both existing OpenSpec proposals on 2026-10-09 as part of the
full-backlog implementation request. Acceptance was defined in those proposals
and new failing tests before implementation.

## Position navigation

A validated URL request accepts an absolute path, positive decimal source line,
and optional fragment. The bounded file-scoped store uses UUIDs for replacement
and cancellation. Render completions await the actual JavaScript Promise, are
scoped to file/render generation, and pass targets as structured arguments.
New requests also notify already-open documents. Explicit navigation is consumed
once, separately from ordinary view updates.

Source ranges refer to original file lines including front matter, nested blocks,
fences, source view rows and replaced diagram wrappers. The smallest covering
block wins; blank lines move to the next block, beyond-end lines to the final
block. The gutter does not need to be visible. Switching files with identical
text now forces a full render instead of incorrectly using the theme fast path.

## Contents sidebar

Wide (>=900 CSS px) app and expanded QuickLook windows dock contents on the right
and reserve real document space. Narrow windows use the overlay, preserving the
user's visibility choice across reloads and resize. Compact Finder hides it,
no-heading documents reserve no sidebar, and source display clears the outline.
Print/export does not retain panel controls or its layout spacing. The contents
observer is refreshed after the document DOM is replaced and is disposed when
the container changes. Collapse and contents controls share the panel header area.

## Verification so far

- 14 focused renderer tests passed, including original source mapping and sidebar behavior.
- Full renderer suite: 312 tests / 32 suites passed.
- Three native request parsing/store/argument safety tests passed.
- App and extension compiled with the existing SDK's temporary macOS 12 override.
- Unified runtime and export verification will follow before user acceptance.


## Actual browser layout checks

The local harness rendered date metadata and forty sections. Settled wide geometry
showed document right=820, sidebar left=840 at width 1100 (no overlap); closing and
rerendering kept contents closed. Width 700 fell back to overlay. Original line 82
(blank before Section 20) selected the following heading at original line 83 and
placed it about 60 px below the viewport top. Beyond-end navigation showed the final
content. Finder context hid the panel and cleared reserved width. A browser download
attempt timed out; no export-download pass is claimed. Automated export tests pass.
