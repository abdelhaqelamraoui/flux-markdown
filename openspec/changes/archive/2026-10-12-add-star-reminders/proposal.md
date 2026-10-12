# Change: Add usage-aware GitHub Star reminders

## Why
The user requests a design for proactive recurring invitations to support the project.

## What Changes
- Propose a localized, nonmodal main-app reminder after seven days and three active reading dates.
- Retry after 14 days, then recur at intervals of at least 30 days with no total display limit until a stop condition is met.
- Stop after a successful main-app support link handoff, self-reported star or opt-out; provide a settings switch.
- Keep QuickLook free of proactive prompts in the first iteration.

## Impact
- Affected spec: project-support, extending add-github-star-entry.
- Affected code: main-app lifecycle, reading view, settings, GitHubStar helper and tests.
- Design: docs/design/DESIGN_STAR_REMINDERS.md.
- Authorization: the user approved implementation of this design, including continued 30-day reminders without a display cap.
- Scope decision: QuickLook handoff completion synchronization is deferred because the sandboxed launcher cannot write main-app state; no extension permissions are broadened.
