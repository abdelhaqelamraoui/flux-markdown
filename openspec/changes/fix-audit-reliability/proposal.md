# Change: Repair audited rendering and release reliability

## Why
The 2026-10-10 audit reproduced executable document HTML, stale render commits, broken native Typst initialization and configuration drift. The user subsequently requested these findings be fixed.

## What Changes
- Sanitize document HTML and validate native bridge origins; retain passive Markdown/HTML presentation.
- Isolate render generations and parser configuration; await export readiness.
- Repair local WASM loading, bounded resource reads and UTF8 truncation.
- Add type checking, reproducible builds, dependency updates and recoverable release publication.
- Preserve macOS 11 support and document the required build toolchain; do not silently raise the product minimum.

## Impact
- Affected specs: render-safety
- Affected code: renderer, native hosts and shared services, tests, build/release scripts.
- Authorization: user instruction “好的. 修复这些问题.” following the audit and recommended remedies.
