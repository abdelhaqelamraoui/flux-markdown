## ADDED Requirements

### Requirement: Feedback from every application-controlled error surface
The product SHALL expose a localized Report This Problem action on every application-controlled error surface listed in the implementation coverage inventory, including native dialogs, failure notices, and inline renderer errors. The action SHALL accompany task-specific recovery guidance without adding repeated modal interruptions. Silent failures of foreground user tasks covered by the inventory SHALL receive an actionable visible result. Normal cancellation SHALL NOT be classified as a failure.

#### Scenario: User encounters an update or export failure
- **WHEN** the product displays the failure
- **THEN** recovery actions and a feedback entry are available at that surface

#### Scenario: Invalid input or known preview limitation
- **WHEN** the product displays a syntax/validation error or a preview limitation
- **THEN** it offers correction or an alternative workflow plus a low-disruption feedback entry without asserting a product defect

#### Scenario: Error belongs to the operating system or the extension never runs
- **WHEN** the product cannot control the error window or capture the original event
- **THEN** the application Help feedback entry remains available and diagnostics disclose missing evidence without claiming universal capture

### Requirement: One action prepares a reviewable report
Activating feedback SHALL open a local report preview automatically populated with the selected error context and necessary allowlisted diagnostics. The user SHALL be able to edit, exclude diagnostics, copy, save, or cancel before navigating to GitHub. The product SHALL NOT upload or submit an issue automatically, and SHALL preserve existing edited drafts.

#### Scenario: Report from an error dialog
- **WHEN** the user selects Report This Problem
- **THEN** the original modal completes safely and a report for that event opens without requiring manual log collection

#### Scenario: Another report has user edits
- **WHEN** feedback is requested for a second error
- **THEN** the first draft is preserved and the second event is identified independently

### Requirement: Capture error-time context and distinguish later checks
The product SHALL capture error identity, time, component, operation, phase, bounded error-code chain, and relevant version/settings state at the time an observable failure occurs. Reports SHALL distinguish this snapshot from the current environment and later diagnostic checks. Missing installation provenance or runtime evidence SHALL remain unknown.

#### Scenario: User restarts or changes settings before reporting
- **WHEN** a retained error is reported later
- **THEN** its original source/version/time remain identifiable and new settings or checks are not presented as error-time evidence

#### Scenario: Update failure precedes Sparkle's abort callback
- **WHEN** the user reports an update error before the error dialog acknowledgement completes
- **THEN** the report already contains that failure and the update cycle is acknowledged exactly once

### Requirement: Bounded structured diagnostics
The product SHALL retain at most 100 structured diagnostic events and 64 KiB per source store without time expiration. Structured events SHALL use validated fixed fields and SHALL NOT ingest raw application/system logs. History failures SHALL NOT prevent recovery or feedback. Existing settings-history limits SHALL remain unchanged and users SHALL be able to clear new diagnostic history without changing settings.

#### Scenario: Retention or storage limit
- **WHEN** a source exceeds an event/byte limit or cannot persist diagnostics
- **THEN** oldest events are pruned or missing history is disclosed while reporting remains usable

#### Scenario: Duplicate or repeated error
- **WHEN** callbacks repeat for the same operation
- **THEN** the report preserves one identifiable failure and bounded related events without flooding the user with prompts

### Requirement: Privacy by validated fields
Automatic collection, persistence, cross-process payloads, copied reports and GitHub summaries SHALL exclude document contents, diagram/formula source, search input, screenshots, filenames, private paths, usernames, arbitrary exception text, stack traces, unvalidated URLs and raw system logs. Every untrusted field SHALL be validated at collection and export. Users SHALL review any manually added samples themselves.

#### Scenario: Error includes private content
- **WHEN** native or JavaScript errors contain a private path, URL token, document fragment or search term
- **THEN** only allowlisted classifications and safe codes are retained or exported

#### Scenario: Necessary reproduction sample is absent
- **WHEN** diagnostics cannot identify the cause without a sample
- **THEN** the report asks for a minimal non-private reproduction without automatically attaching the current document

### Requirement: Secure Quick Look and renderer handoff
Quick Look feedback SHALL use a native fallback and an authenticated fixed-target handoff to the installed host application without broadening sandbox permissions. Renderer requests SHALL be schema-validated, size-limited, scoped to the current document generation, and unable to request arbitrary URLs, files or commands. Cross-process error payloads SHALL be limited to 16 KiB and revalidated by the recipient.

#### Scenario: Renderer unavailable
- **WHEN** the renderer cannot load, times out, or terminates
- **THEN** a native recovery/feedback entry remains available independent of JavaScript

#### Scenario: Invalid, stale or malicious handoff
- **WHEN** a feedback payload is malformed, oversized, from an untrusted peer, or belongs to a stale document
- **THEN** it is rejected without reading arbitrary files, leaking content, or mixing another document's diagnostics

#### Scenario: Host launch fails
- **WHEN** the authenticated handoff fails or times out
- **THEN** Quick Look offers a safe copyable summary and instructions to report from the host Help menu

### Requirement: Resilient feedback and honest delivery status
The feedback flow SHALL work locally without network access, preserve edited reports during asynchronous checks, and offer copying/saving if browser navigation fails. GitHub prefill SHALL prioritize the selected error and key environment fields within the existing 6000-byte URL limit, identify omissions, and retain the complete report locally. Failures inside feedback SHALL NOT recursively create new feedback dialogs.

#### Scenario: Browser or saving fails
- **WHEN** a feedback action cannot open GitHub or write the report
- **THEN** the same report remains available with an actionable copy/save alternative and no false submission-success claim

#### Scenario: Report exceeds URL budget
- **WHEN** the complete encoded report exceeds the prefill limit
- **THEN** old history is omitted before the selected error, the UI explains omissions, and the full local report remains accessible

### Requirement: Localized accessible recovery and coverage verification
The product SHALL provide recovery/feedback controls in all five supported UI languages with keyboard and accessibility support. Implementation acceptance SHALL verify every inventory row with a representative fixture, including actual Finder Quick Look with Release entitlements. CLI failures SHALL provide a fixed feedback address and diagnostic guidance without opening GUI automatically.

#### Scenario: Coverage acceptance
- **WHEN** the implementation is declared complete
- **THEN** each inventory row has recorded evidence or an explicit product-control limitation and missing rows are not represented as covered

#### Scenario: Terminal export fails
- **WHEN** an automated CLI export encounters a failure
- **THEN** stderr explains recovery and how to report safely without launching a modal window
