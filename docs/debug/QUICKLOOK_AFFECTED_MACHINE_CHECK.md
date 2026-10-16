# QuickLook fallback: affected-machine acceptance

Applies to unresolved reports #49 and #58. Local disabled-extension recovery passes but does not prove these reports are fixed.

1. Before repair, open Help → Report an Issue and copy the reviewable diagnostic report. It now includes installed-copy registration/enabled state, duplicate count, signature result, current document UTI when a document is open, default editor, and last explicit self-test result/version/date. It does not include document contents or registration paths.
2. Run Help → Test Quick Look. Record whether the generated test document renders and the final verified/unconfirmed result. This is a real QLPreviewView request; it is not a substitute for checking Finder.
3. Select the original affected file in Finder and press Space. Record rendered text versus source text and whether FluxMarkdown controls appear.
4. Run Help → Repair Quick Look; then choose Test Quick Look. Repeat the Finder check. Retain both before/after reports.
5. If unconfirmed, collect the extension launch/render log around this explicit test. Review/redact paths before sharing logs. Registration success alone is not sufficient to mark fixed.

Optional local commands (do not change editor associations):

```sh
/Applications/FluxMarkdown.app/Contents/MacOS/FluxMarkdown --quicklook-diagnostics
/Applications/FluxMarkdown.app/Contents/MacOS/FluxMarkdown --quicklook-self-test
```

The test creates and removes its own temporary document and window. It records only test status/version/time locally. A failed or cancelled test reports unconfirmed; OS-log visibility restrictions can also cause an unconfirmed result. Never infer that the default editor shown in Finder is the preview provider.
