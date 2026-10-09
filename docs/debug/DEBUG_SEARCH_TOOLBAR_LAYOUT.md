# Native search toolbar overlap

## Reproduction and acceptance metric

On the unlocked console, candidate `1.34.475-dev-20261009-031127`, open
`Tests/fixtures/acceptance-all.md` at the default 900-point width and press Cmd+F.
The search options and Close button occupy the same vertical band as the native
reload/zoom/help controls. Screenshot: `/tmp` session capture
`f0c27c04-1a9d-4804-a955-cea6477d4eab-screenshot.png`.

Before implementation, the acceptance metric is: the search toolbar must start
below the native controls; in docked contents layout its horizontal bounds must
also end before the sidebar. In narrow windows the toolbar must fit the viewport
and wrap options instead of clipping them. Search text and repeat Find must work.

## Cause

Search CSS fixes its top at 10px without reserving the native overlay toolbar.
Its fixed input width plus non-wrapping controls also exceed narrow viewports.

## Verified correction

The rebuilt native 900-point window places the toolbar below the native controls
and entirely to the left of the docked contents sidebar. Search for Alpha displays
1/2; repeat Cmd+F preserves the query and Escape removes the toolbar. A settled
1920-point fullscreen screenshot also shows separate document, search and contents
regions. The stylesheet allows controls to wrap within viewport bounds; native
narrow-window visual verification remains pending.
