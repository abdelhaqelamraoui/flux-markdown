## ADDED Requirements

### Requirement: Recent preference history
The host app SHALL persist changes to all settings-panel preferences and toolbar appearance choices with timestamps, effective old/new values, application version, session identity, and source. It SHALL distinguish user changes, migration, and observed external changes without attributing an unknown actor.

#### Scenario: User changes language
- **WHEN** the user changes language from system to German
- **THEN** an event records the old/new values and UI source and survives a normal application restart

#### Scenario: Continuous or unchanged input
- **WHEN** a slider is dragged continuously or a setting is assigned its existing effective value
- **THEN** continuous changes are coalesced into a final change and identical values produce no change event

#### Scenario: Existing or external preferences
- **WHEN** the application first observes preferences, migrates legacy preferences, or detects a change made outside its own setters
- **THEN** it records a baseline, migration event, or external observation respectively and never falsely labels them as user actions

### Requirement: Bounded reliable local history
The application SHALL retain the latest 200 setting events and 20 startup snapshots without time-based expiration, capped at 256 KiB, in a private local store written only by the host app. Timestamps SHALL support ordering and environment correlation, not expiration. History failures SHALL NOT prevent changing settings and SHALL be disclosed in diagnostics. Clearing history SHALL NOT change settings.

#### Scenario: Retention limits
- **WHEN** history exceeds a count or size limit
- **THEN** the oldest records are pruned and current settings remain intact

#### Scenario: Infrequent changes across months or years
- **WHEN** retained records span months or years and remain within count and size limits
- **THEN** they remain available after restart and in diagnostic reports regardless of their age

#### Scenario: History failure or clearing
- **WHEN** history is corrupted or cannot be written, or the user clears history
- **THEN** settings continue to work and the report identifies unavailable history, or stored diagnostic history is removed respectively

### Requirement: Environment and language diagnostics
The application SHALL generate a diagnostic report containing allowlisted current settings, recent history, app and OS versions/builds, architecture, and global/application/effective localization state. Startup snapshots SHALL permit comparison of observed environment changes across launches. Reports SHALL exclude document content, file names/paths, usernames, scroll history, raw logs, and unvalidated strings.

#### Scenario: Reporting after an OS upgrade
- **WHEN** the OS version differs from a retained earlier startup snapshot
- **THEN** the report identifies both observed versions and associated setting observations without asserting an unproven cause

#### Scenario: Invalid preference contents
- **WHEN** a preference contains an unknown key or an invalid string containing private information
- **THEN** it is omitted or represented as an invalid value rather than copied verbatim

### Requirement: Bug feedback with reviewable diagnostics
The Report an Issue action SHALL open a local report preview with diagnostics included by default. Users SHALL be able to review/edit, exclude diagnostics, copy, save, or cancel before opening a prefilled GitHub Bug Report form. The app SHALL explain the GitHub destination and public Issue visibility and SHALL NOT submit an Issue automatically.

#### Scenario: Submit preparation
- **WHEN** the user continues with diagnostics enabled
- **THEN** the browser opens the Bug Report form with the selected diagnostic summary and app version prefilled, and final submission remains on GitHub

#### Scenario: Exclusion or cancellation
- **WHEN** the user excludes diagnostics or cancels
- **THEN** no diagnostic history is sent in the GitHub URL, or no browser navigation occurs respectively

#### Scenario: Oversized report or failed navigation
- **WHEN** the encoded URL would exceed 6000 bytes or browser navigation fails
- **THEN** the summary is shortened with an omission notice or omitted if necessary, and the full local report remains available for copying/saving

### Requirement: Feature feedback entry
The application SHALL provide a localized Suggest a Feature action that opens the existing Feature Request form without automatically attaching settings history.

#### Scenario: Suggest a feature
- **WHEN** the user chooses Suggest a Feature
- **THEN** the feature_request.yml form opens without requiring the user to locate the template in the Issue list
