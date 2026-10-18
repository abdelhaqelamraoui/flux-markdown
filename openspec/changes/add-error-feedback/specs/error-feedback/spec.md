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

### Requirement: Guidance with an executable next step
Every application-controlled error SHALL describe the affected user task and provide concise, evidence-based guidance. The recommended recovery SHALL be directly executable from the error surface when the product can perform it. Recovery SHALL be visually primary, feedback secondary, and technical details or lengthy instructions optional disclosures. If no recovery is available, reporting MAY be primary. The product SHALL preserve user work and SHALL NOT blame the user, invent a cause, offer futile retries, or require reporting before recovery.

#### Scenario: Automatic update cannot complete
- **WHEN** the update error is shown
- **THEN** the user can directly open the official download page, optionally expand manual installation steps, report that incident, or safely dismiss the error

#### Scenario: Failure has a known alternative
- **WHEN** a task fails and choosing another location or opening the host app is a valid alternative
- **THEN** the primary action performs that alternative instead of only displaying directions to find another menu

#### Scenario: Technical information is available
- **WHEN** an error includes developer-oriented detail
- **THEN** the first view remains understandable without reading that detail and it can be inspected separately

### Requirement: One action enters contextual feedback
From an error surface, activating Report This Problem SHALL automatically prepare and retain a safe report and directly open the prefilled GitHub feedback form without a mandatory local editor or another local confirmation. The product SHALL prefill known task, component, version, environment and diagnostic information. Optional explanation, steps and samples SHALL NOT block submission. The destination and included data SHALL be briefly disclosed before activation; report inspection, editing and diagnostic exclusion SHALL be available as optional actions. Generic Help-menu reporting MAY retain the existing manual editor.

#### Scenario: User reports an observed failure
- **WHEN** the user activates Report This Problem once
- **THEN** the original error modal finishes safely and a prefilled GitHub form opens without another required local step or manual diagnostic collection
- **AND** the user can proceed to GitHub's final publish action without supplying already-known or optional fields

#### Scenario: User inspects or excludes diagnostics
- **WHEN** the user chooses the optional report controls before reporting
- **THEN** the user can inspect/edit the report or exclude diagnostics and the resulting GitHub request respects that selection

#### Scenario: Another report has user edits
- **WHEN** feedback is requested for a second error
- **THEN** the first draft is preserved and the second event is identified independently without forcing the first editor into the new report's default path

#### Scenario: GitHub requires sign-in or final publication
- **WHEN** the prefilled form is opened
- **THEN** the product truthfully explains any GitHub sign-in/final publication step and does not claim that opening the form submitted a report

### Requirement: Capture error-time context and distinguish later checks
The product SHALL capture error identity, time, component, operation, phase, bounded error-code chain, and relevant version/settings state at the time an observable failure occurs. Reports SHALL distinguish this snapshot from the current environment and later diagnostic checks. Missing installation provenance or runtime evidence SHALL remain unknown.

#### Scenario: User restarts or changes settings before reporting
- **WHEN** a retained error is reported later
- **THEN** its original source/version/time remain identifiable and new settings or checks are not presented as error-time evidence

#### Scenario: Update failure precedes Sparkle's abort callback
- **WHEN** the user reports an update error before the error dialog acknowledgement completes
- **THEN** the report already contains that failure before navigation and the update cycle is acknowledged exactly once

### Requirement: Bounded structured diagnostics
The product SHALL retain at most 100 structured diagnostic events and 64 KiB per source store without time expiration. Structured events SHALL use validated fixed fields and SHALL NOT ingest raw application/system logs. History failures SHALL NOT prevent recovery or feedback. Existing settings-history limits SHALL remain unchanged and users SHALL be able to clear new diagnostic history without changing settings.

#### Scenario: Retention or storage limit
- **WHEN** a source exceeds an event/byte limit or cannot persist diagnostics
- **THEN** oldest events are pruned or missing history is disclosed while reporting remains usable

#### Scenario: Duplicate or repeated error
- **WHEN** callbacks repeat for the same operation
- **THEN** the report preserves one identifiable failure and bounded related events without flooding the user with prompts

### Requirement: Privacy by validated fields
Automatically collected/generated diagnostic content SHALL exclude document contents, diagram/formula source, search input, screenshots, filenames, private paths, usernames, arbitrary exception text, stack traces, unvalidated URLs and raw system logs at collection, persistence, cross-process handoff, copying and GitHub export. Every untrusted diagnostic field SHALL be validated at collection and export. User-authored notes or minimal samples SHALL be passed as the user's visible edited draft, with size/structure validation and safe encoding; they SHALL NOT be silently treated as automatically collected diagnostics or filtered away as if they were such data. Users SHALL review manually added samples themselves. The product SHALL disclose that prefilled data is transmitted to GitHub when the URL is opened, before public issue submission; it SHALL NOT claim the data remains exclusively local until publication.

#### Scenario: Error includes private content
- **WHEN** native or JavaScript errors contain a private path, URL token, document fragment or search term
- **THEN** only allowlisted classifications and safe codes are retained or exported

#### Scenario: Necessary reproduction sample is absent
- **WHEN** diagnostics cannot identify the cause without a sample
- **THEN** the report asks for a minimal non-private reproduction without automatically attaching the current document

### Requirement: Secure Quick Look and renderer handoff
Quick Look feedback SHALL use a native fallback and an authenticated fixed-target handoff to the installed host application without broadening sandbox permissions. The host SHALL route the selected incident directly to prefilled feedback without requiring the user to navigate a second app window first. Renderer requests SHALL be schema-validated, size-limited, scoped to the current document generation, and unable to request arbitrary URLs, files or commands. Cross-process error payloads SHALL be limited to 16 KiB and revalidated by the recipient.

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
Report preparation SHALL work locally without network access and preserve edited reports during asynchronous checks. Missing or timed-out supplementary diagnostics SHALL NOT block reporting with available information. The product SHALL retain a local report with reopen/copy/save actions, including when a browser accepts navigation but the user later encounters a network or sign-in failure. Browser acceptance SHALL NOT be treated as evidence of page load or publication. GitHub prefill SHALL prioritize the selected error and key environment fields within the existing 6000-byte URL limit, identify omissions, and retain the complete report locally. Failures inside feedback SHALL NOT recursively create new feedback dialogs.

#### Scenario: Optional diagnostics are unavailable
- **WHEN** a supplementary diagnostic collection fails or times out
- **THEN** the user can report using available context and unknown fields are marked unavailable without requiring manual troubleshooting

#### Scenario: Browser or saving fails
- **WHEN** a feedback action cannot open GitHub or write the report
- **THEN** the same report remains available with an actionable copy/save alternative and no false submission-success claim
- **AND** if the original modal has already ended, a continuation panel preserves the same event/report and recovery actions without recursively creating another failure report

#### Scenario: Report exceeds URL budget
- **WHEN** the complete encoded report exceeds the prefill limit
- **THEN** old history is omitted before the selected error, the UI explains omissions, and the full local report remains accessible

### Requirement: Accessible contextual form and repeated activation
The automatic feedback template SHALL avoid required fields that needlessly repeat known information or demand optional reproduction material. Repeated activation for one event SHALL reuse its identity and report and SHALL NOT open duplicate navigation while a handoff is in progress. Template availability and actual prefill behavior SHALL be verified on the repository default branch before distributing a client that depends on it.

#### Scenario: Existing manual form requires extra selections
- **WHEN** automatic feedback is generated
- **THEN** the automatic template supports submission with its prefilled title/summary and available diagnostics without requiring component/system dropdown selection or a sample document

#### Scenario: User double-clicks feedback
- **WHEN** one event is already preparing or opening feedback
- **THEN** repeated activation uses the same in-flight request, and a later explicit reopen preserves the same event identity

### Requirement: Localized accessible recovery and coverage verification
The product SHALL provide recovery/feedback controls in all five supported UI languages with keyboard and accessibility support. Implementation acceptance SHALL verify every inventory row with a representative fixture, including actual Finder Quick Look with Release entitlements. CLI failures SHALL provide a fixed feedback address and diagnostic guidance without opening GUI automatically.

#### Scenario: Coverage acceptance
- **WHEN** the implementation is declared complete
- **THEN** each inventory row has recorded evidence or an explicit product-control limitation and missing rows are not represented as covered

#### Scenario: Terminal export fails
- **WHEN** an automated CLI export encounters a failure
- **THEN** stderr explains recovery and how to report safely without launching a modal window
