# Issue #49: QuickLook falls back to plain text

Issue: https://github.com/xykong/flux-markdown/issues/49
The body identifies Sequoia 15.7.7 (24G720), despite the Tahoe title/form/label.
The app renders correctly; registration, enabling, cache resets and reinstall
were already attempted. This is not yet a reproduced renderer defect.

The Open with VS Code button describes the file-opening action, not proof that
VS Code supplied the preview. A default-editor change must not be offered as a
confirmed fix without evidence. The current Info.plist already declares Owner
and the reported UTI. Our installation scripts also modify file associations;
that can violate the reporter's desire to keep VS Code as their editor.

## Acceptance before diagnostic implementation

Provide a read-only collector for OS/build, installed app and extension version,
signature verification, Gatekeeper assessment, extension registrations and their
states, QuickLook preference ordering, and optional file UTI. It must not change
contexts, associations, registration, caches or settings, or collect file contents,
user paths, names, raw logs or arbitrary plist values. Multiple registrations
must be visible as counts, not falsely equated to the selected provider.

## Evidence / limits

Our development machine is macOS 27.0.1, not the reporter's Sequoia. PlugInKit
currently lists installed and DerivedData copies. Local success cannot establish
the reporter's root cause. The existing support doc's deterministic claim that
the default editor/Owner alone controls provider selection is too strong and
must be qualified.

The collector passes a native process test using a deliberately malformed version field and a private-looking bundle path: the field becomes invalid, no paths/names appear, and the bundle bytes remain unchanged. A local read-only probe reports two enabled registrations and valid signatures; selected provider remains unknown. The support guide now qualifies the old Owner/default-editor claim. The GitHub platform label has been corrected to Sequoia; the issue remains open. A reporter reply requesting targeted diagnostics is prepared below. A fix/release claim requires reproduction on the affected environment.

## Prepared reporter reply (English; not posted)

Thank you for the detailed investigation. Your report identifies macOS Sequoia 15.7.7 (24G720), so I corrected the platform label. Please confirm whether this is still the affected macOS version.

The “Open with Visual Studio Code” button does not identify the Quick Look preview provider. You should be able to keep VS Code as your editor while investigating previews. Registration and a + status alone do not prove Finder selected FluxMarkdown.

Please capture the following before another reinstall or cache reset:
- The currently installed FluxMarkdown version and macOS build.
- Whether a fresh minimal Markdown file also fails.
- Whether there are multiple registrations for com.xykong.Markdown.QuickLook.
- Whether logs for the failed Finder preview show preparePreviewOfFile, Renderer Handshake Received, or an extension/WebKit error. Please remove personal file paths and names before sharing the relevant lines.

This remains under investigation; the cause has not yet been reproduced on Sequoia.
