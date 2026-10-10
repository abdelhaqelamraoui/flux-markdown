# Build and compatibility contract

The product minimum remains macOS 11. Release CI is pinned to Xcode 16.4 on macos-15 and builds arm64 and x86_64. A deployment target is not a substitute for runtime acceptance on the minimum OS. Vite explicitly targets Safari 14 syntax; browser API/WASM compatibility still requires minimum-system testing.

Xcode 27 rejects the 11.0 target. Local `make app` detects this before invoking xcodebuild. Select a compatible installation for this command with `DEVELOPER_DIR`; no script changes the global xcode-select setting. For local diagnostics on a newer system, `make app LOCAL_DEPLOYMENT_TARGET=12.0` is explicit and temporary. Do not distribute it as a macOS 11 build.

Renderer checks: `npm ci`, `npm run typecheck`, `npm test -- --runInBand`, `npm run build` from web-renderer. `scripts/test-renderer-webkit.sh` then tests the actual bundle offline in WebKit, including native Typst fonts/WASM and diagram engines. Both CI renderer jobs build; the macOS jobs run real WebKit checks.

`make app` uses incremental Xcode builds. Dependencies install with npm ci only when package.json/package-lock.json change or node_modules is missing. `make clean` explicitly cleans the native build. The renderer build uses a Vite HTML hook instead of macOS-specific sed.

## Resource and export behavior

QuickLook reads a UTF8-safe prefix of at most 500 KiB. Full App documents reject input above 32 MiB instead of silently truncating a potentially writable document. Local document resources must be referenced image files, with 32-image, 2 MiB per-image and 8 MiB source-byte budgets shared by inline and scheme selection. Limits refer to compressed source bytes, not decoded image memory.

Active HTML (scripts, event handlers, nested frames and forms) is stripped. Passive details, tables, task lists, SVG/MathML and formula presentation remain supported. CSP additionally blocks document scripts and frames. Its unsafe-eval allowance supports WASM on the existing WebKit baseline; it does not permit inline script attributes. The legacy allowUniversalAccessFromFileURLs setting is removed; bundled modules, local images and all diagram checks pass without it. Native bridge messages must originate from the main bundled renderer frame.

PDF export waits for renderer completion, fonts and images. Missing images or failed diagrams fail export rather than silently producing an incomplete PDF. Resource readiness has a 15-second deadline; CLI export has a 60-second overall deadline. Typst fonts and WASM are packaged locally and do not require a CDN.

## Dependency overrides

KaTeX is unified at the explicitly installed patched version, including the older Markdown plugin and Mermaid. Native WebKit formula/diagram checks and renderer regressions guard compatibility. The test-only @istanbuljs/load-nyc-config dependency uses patched js-yaml 4 through an override; its consumer calls load (compatible with this API). This removes the old argparse/sprintf-js chain. Check overrides whenever updating their parent packages; regenerate the lock in a clean directory if npm preserves an invalid old nested dependency.

Native Typst adds real offline WASM/fonts: the renderer directory is about 37 MiB versus the audited 6.1 MiB incomplete bundle. The existing project embeds the resource directory in both host and extension; this disk-size cost is explicit, although QuickLook uses the lightweight transpilation path and does not load native Typst WASM.
