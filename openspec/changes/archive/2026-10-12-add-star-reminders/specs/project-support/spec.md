## ADDED Requirements
### Requirement: Usage-aware support invitations
The main application SHALL offer a nonmodal support invitation only after seven elapsed days and three active reading dates, with the second invitation no earlier than 14 days after the first display and the third and every subsequent invitation no earlier than 30 days after the previous display. Invitations SHALL have no total display limit while enabled and no stop condition has been met.

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
The application SHALL persist reminder state across upgrades and SHALL stop invitations after a successful main-app support browser handoff, self-reported star or opt-out without claiming a verified star.

#### Scenario: User declines reminders
- **WHEN** the user selects never remind or disables the settings switch
- **THEN** the visible invitation is dismissed and future invitations cease until explicitly re-enabled

#### Scenario: Browser launch fails
- **WHEN** opening the repository fails
- **THEN** the application offers recovery without recording a successful handoff

#### Scenario: User re-enables reminders
- **WHEN** the user explicitly re-enables the setting
- **THEN** reminders resume with at least a fourteen-day cooldown and the usage requirements still apply

#### Scenario: Recurring reminders continue beyond the third display
- **WHEN** the third or any later invitation has been displayed and no stop condition has been met
- **THEN** the next invitation is eligible after at least 30 days and a new active reading date, with no total display limit
- **AND** inactive periods do not accumulate missed invitations to replay
