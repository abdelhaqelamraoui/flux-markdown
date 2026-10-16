# Change: Restore QuickLook local resources and diagnose fallback

## Why
Issues #59, #58 and #49 report broken QuickLook images and plain-text fallback. The user approved the prioritized investigation/fix plan and local acceptance on 2026-10-16.

## What Changes
- Restore portable read-only home-directory image access in the release extension, conditional on actual sandbox/Finder validation, preserving reference and size restrictions.
- Log resource failures accurately and show truncation outside Markdown content.
- Surface registration/runtime diagnostics in the app and distinguish registration repair from confirmed preview execution.

## Impact
- QuickLook release sandbox and packaging checks; image loader, native preview notice, feedback and repair.
- No release or issue replies are authorized by this work item.
