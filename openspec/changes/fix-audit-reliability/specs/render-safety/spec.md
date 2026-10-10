## ADDED Requirements
### Requirement: Passive document content
The renderer SHALL preserve supported passive HTML while preventing document content from executing scripts or injecting active navigation containers.
#### Scenario: Event handler in a document
- **WHEN** document HTML contains an onerror handler
- **THEN** the handler is removed before the document is attached to the live DOM

### Requirement: Current render wins
The native hosts and renderer SHALL discard stale rendering work across document and mode changes.
#### Scenario: Older math initialization completes late
- **WHEN** a newer document renders before an older asynchronous render completes
- **THEN** the displayed content and completion state belong to the newer document

### Requirement: Export readiness
PDF export SHALL wait for rendering and bounded image/font readiness, and SHALL fail with a diagnostic on timeout.
#### Scenario: Slow diagram
- **WHEN** diagram rendering takes longer than three seconds
- **THEN** export waits for rendering instead of capturing a partial page

### Requirement: Bounded resource reads
Local document resources SHALL obey type and byte budgets, and preview truncation SHALL preserve a valid UTF8 prefix.
#### Scenario: Multibyte character crosses truncation boundary
- **WHEN** a preview limit splits a valid UTF8 character
- **THEN** the valid prefix is displayed with a truncation notice
