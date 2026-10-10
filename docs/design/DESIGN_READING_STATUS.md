# Reading status

Approved 2026-10-10. Use existing toolbar height and available horizontal space. Current heading follows the TOC selection; display the last two heading levels with full-path tooltip. Position means scroll position, not confirmed reading. Hide percentage for short documents. QuickLook may show filename; normal app already has a native title. Content changes show a four-second update notice, never for theme-only rerenders. Source and compact Finder hide status. Narrow layouts progressively omit filename, ancestors and percentage; status must never cause toolbar wrapping. Optional clickable navigation, detail statistics, reading estimates and fullscreen title duplication are deferred.

Acceptance: toolbar/document top unchanged, no overlap at 320–2560 px on either directory side; correct hierarchy for skipped heading levels, clamped progress, short-document suppression, localization and clean disposal. No status in exported document or print.

## Verification — 2026-10-10

- 36 renderer suites / 340 tests passed; TypeScript `--module esnext` check and production Vite build passed.
- Browser geometry checked widths 320, 400, 520, 760, 900, 1100 and 2560 on both directory sides. Status stays within spare space; shared row remains 32 px. Existing narrow toolbar fallback unchanged; status does not create its own row.
- Browser checked end-of-document 100%, correct heading hierarchy, QuickLook filename and short/plain-document suppression.
- Release native build succeeded with local macOS 12 deployment override. Signed development app `1.34.475-dev-20261010-110517` installed at `/Applications/FluxMarkdown.app`; signature/sandbox verification passed. Installed app and QuickLook renderer hashes match the frontend artifact.
- Native app screenshot and accessibility inspection confirmed status `Unified acceptance › Section 2`, `位置 6%` on the left and native circle group followed by directory on the right. Evidence: `build/reading-status/native.png` (local, not committed).
- Real QuickLook runtime and macOS 11 acceptance have not been repeated for this change. No public release performed.
