# Close the preview after search handoff

The reporter verified one-click app/file/search opening but observed both the Finder
Quick Look panel and the app window remaining open. The desired transition leaves
only the main app visible.

## Acceptance before implementation

- Successful search launch requests dismissal of the originating preview once.
- Failed launch preserves the preview and displays the existing short hint.
- A reply for an older request or a different/newly prepared preview must not close
  the current preview.
- Use the extension's own public completion/dismissal API; do not close Finder
  windows, terminate processes, synthesize Escape, or require Accessibility.
- Verify the actual Finder panel disappears (not merely its content), with the
  app search focused and accepting Alpha (1/2), including warm app and full screen.

The SDK documents NSExtensionContext.completeRequestReturningItems as eventually
dismissing the associated view controller. Test this on the real Quick Look host;
mock callbacks alone do not prove panel closure.

## Results and rollback

Two request-generation/dismissal regressions failed before the experimental seam
existed and passed after it. This proves only guarded callback dispatch, not actual
Finder window closure. The experiments were not retained as production behavior.

1. `extensionContext.completeRequest(returningItems: nil)` ended the extension view
   and process, but the actual Finder Quick Look panel remained as a file-icon
   preview. This fails the acceptance metric.
2. Closing the controller's `view.window` removed the embedded WebView but left the
   Finder panel and its toolbar visible. The installed development version was
   confirmed in the AX tree before invoking search, and the actual extension process
   ran from `/Applications/FluxMarkdown.app`. This also fails the metric.

The first GUI automation attempts had focus/remote-window binding errors after a
display configuration change. Restarting the automation helper and using Finder's
observed Quick Look menu action allowed actual Markdown preview tests. Only those
real panel observations count as the evidence above.

Both experimental code paths and their misleading callback-only tests were removed.
Restored the previously verified Release-configured one-click-search candidate
`1.34.475-dev-20261009-130822`. No Finder window or other application is closed by
the product. No process termination, global keyboard event, private API, app hiding,
Accessibility authorization or sandbox change was introduced to force panel closure.

Automatic Finder-panel dismissal remains unresolved. Public extension-request
completion dismisses the view controller, not necessarily the host-owned panel:
https://developer.apple.com/documentation/foundation/nsextensioncontext/completerequest(returningitems:completionhandler:)
