## ADDED Requirements

### Requirement: Explicit optional shortcut authorization
The application SHALL keep the Quick Look shortcut helper disabled by default and
SHALL require explicit opt-in and macOS Accessibility authorization before activating
cross-process shortcut interception. The preview SHALL remain usable without it.

#### Scenario: Permission declined
- **WHEN** the user declines or revokes Accessibility authorization
- **THEN** interception remains stopped and the native search button remains available

### Requirement: Exclusive verified preview routing
The helper SHALL intercept exactly Cmd+F only for the positively identified active
FluxMarkdown Quick Look preview while Finder is frontmost. It SHALL preserve events
when ownership or delivery is uncertain and SHALL use only public APIs.

#### Scenario: Active supported preview
- **WHEN** the user presses Cmd+F in a verified active FluxMarkdown preview
- **THEN** preview search opens or refocuses with its query retained and Finder search does not open

#### Scenario: Another recipient or modifier
- **WHEN** Finder has no active FluxMarkdown preview, another app is active, or the user presses Cmd+Shift+F
- **THEN** the helper leaves the event and normal application behavior unchanged

### Requirement: Bounded lifecycle and input privacy
The helper SHALL stop interception on disable, permission loss, preview closure or
target invalidation. It SHALL NOT read Unicode keystroke text or retain/transmit
keyboard input, search queries, document contents, or file paths.

#### Scenario: Stale target
- **WHEN** the active preview closes or the verified target becomes stale
- **THEN** interception stops and subsequent Cmd+F is delivered normally

#### Scenario: Diagnostic export
- **WHEN** diagnostics are generated while the helper is enabled
- **THEN** only allowlisted availability/permission/status flags and fixed error codes may be included
