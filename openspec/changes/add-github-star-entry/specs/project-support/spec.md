## ADDED Requirements
### Requirement: Discoverable project support
The application SHALL provide an explicitly labelled GitHub Star entry without interrupting document reading.
#### Scenario: User seeks project support
- **WHEN** a user opens the welcome page or Help menu
- **THEN** a localized GitHub Star entry is available

### Requirement: Honest browser handoff
The lightweight support entry SHALL open the canonical repository in the default browser and SHALL explain that the user completes starring on GitHub.
#### Scenario: Repository page opens
- **WHEN** a user activates the entry
- **THEN** the app opens https://github.com/xykong/flux-markdown and does not report a completed star

#### Scenario: Browser cannot open
- **WHEN** opening the repository URL fails
- **THEN** the user can obtain the same URL and retry manually

#### Scenario: QuickLook sandbox handoff
- **WHEN** the user activates the repository link in QuickLook
- **THEN** the authenticated XPC launcher opens only the fixed project repository, without accepting an arbitrary target or broadening sandbox permissions
