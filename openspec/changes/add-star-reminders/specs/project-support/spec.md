## ADDED Requirements
### Requirement: Usage-aware support invitations
The main application SHALL offer a nonmodal support invitation only after seven elapsed days and three active reading dates, with subsequent invitations no earlier than 14 and then 30 days after the previous display and at most three displays per explicitly enabled cycle.

#### Scenario: First-time user
- **WHEN** the user has not met both usage thresholds
- **THEN** no proactive invitation is displayed

#### Scenario: Returning eligible user
- **WHEN** the cooldown has elapsed and a later eligible reading session occurs
- **THEN** at most one foreground window displays the invitation without taking keyboard focus

#### Scenario: QuickLook session
- **WHEN** a document is previewed using QuickLook
- **THEN** no proactive support invitation is displayed

### Requirement: Durable reminder controls
The application SHALL persist reminder state across upgrades and SHALL stop invitations after a successful main-app support browser handoff, self-reported star, opt-out or display-limit exhaustion without claiming a verified star.

#### Scenario: User declines reminders
- **WHEN** the user selects never remind or disables the settings switch
- **THEN** the visible invitation is dismissed and future invitations cease until explicitly re-enabled

#### Scenario: Browser launch fails
- **WHEN** opening the repository fails
- **THEN** the application offers recovery without recording a successful handoff

#### Scenario: User re-enables reminders
- **WHEN** the user explicitly re-enables the setting
- **THEN** a new capped cycle starts with at least a fourteen-day cooldown and the usage requirements still apply
