# Change: Add usage-aware GitHub Star reminders

## Why
The user requests a design for proactive recurring invitations to support the project.

## What Changes
- Propose a localized, nonmodal main-app reminder after seven days and three active reading dates.
- Retry after 14 and then 30 days, capped at three displays per user-enabled cycle.
- Stop after a successful main-app support link handoff, self-reported star, opt-out or exhaustion; provide a settings switch.
- Keep QuickLook free of proactive prompts in the first iteration.

## Impact
- Affected spec: project-support, extending add-github-star-entry.
- Affected code: main-app lifecycle, reading view, settings, GitHubStar helper and tests.
- Design: docs/design/DESIGN_STAR_REMINDERS.md.
- Status: proposal only; the current request authorizes design, not implementation.
- Open implementation decision: whether reliable QuickLook handoff completion synchronization is included; it must not require broader extension permissions or claim unverified completion.
