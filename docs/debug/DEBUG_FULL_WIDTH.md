# Full-width reading layout

2026-10-16: Users report that fullscreen Markdown uses only a small portion of a wide display. The shared renderer applies `max-width: 980px` to `#markdown-preview`, plus 45px horizontal padding inherited from `.markdown-body`. Tables are bounded by that content box.

Acceptance: App and QuickLook preview fill the available reading column at wide and narrow window sizes. A docked contents sidebar reserves only its 240px width and 24px gap. Closing it restores the available column. Keep modest horizontal padding, and keep oversized tables horizontally scrollable inside the reading column without causing page overflow. Window resizing is the user's control over reading width; no separate width preference is added. Source, Finder compact preview and print remain supported.

Regression checks use the production bundle in real WKWebView at 1800px and 600px, inspect actual paragraph and table geometry, and cover both contexts and sidebar states.

## Results

The new wide-layout case failed against the previous bundle, then passed after removing the cap. All 18 production WebKit cases and 10 directory tests pass. The geometry checks cover App and QuickLook contexts at 1800px and 600px, open/closed sidebar space, full-width paragraphs and oversized tables with local overflow. Line-number gutters are included in the measured insets. TypeScript/Vite and native Release builds pass. Actual App inspection at 1800px confirms the text fills the column beside the directory. No arbitrary width preference was added.

Horizontal padding is reduced to 20px (15px in narrow windows); source mode retains its own spacing and Finder compact mode retains 8px. Local preview installation preserves default editor preferences. This change has not been published as a formal release. Local Xcode 27 verification uses the documented macOS 12 override; the project minimum remains macOS 11.

## Published

Released and installed as 1.36.561 after user acceptance on 2026-10-16. See [release verification](../release/RELEASE_1.36.561.md).
