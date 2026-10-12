# Change: Add a GitHub Star entry

## Why
Users need a discoverable way to support FluxMarkdown with a GitHub star.

## What Changes
- Add a star entry to the welcome page, Help menu and in-document feature guide (App and QuickLook).
- Recommended behavior: open the canonical repository in the default browser, with clear copy explaining that the user clicks Star on GitHub.
- Handle browser-opening failure with a copyable repository URL; do not claim a star was recorded simply because the page opened.
- Localize native entry points in the five existing application languages and the feature guide in its existing languages.

## Impact
- Affected specs: project-support
- Affected code: native welcome/help, shared repository link, renderer feature guide, localization.
- Authorization: user requested the feature and delegated the implementation choice after asking for community practices; the browser handoff minimizes friction and avoids an additional account-authorization flow.
