## ADDED Requirements

### Requirement: URL position targets
The app SHALL accept a positive 1-based source line target or heading fragment with a local file path. A valid line SHALL take precedence over a fragment; invalid or duplicated line parameters SHALL fall back to a valid fragment or existing opening behavior.

#### Scenario: Valid and invalid targets
- **WHEN** a URL specifies a valid line and a fragment, or an invalid line alone
- **THEN** the app uses the line target, or opens using existing behavior respectively

### Requirement: Original source line mapping
Navigation SHALL use original file line numbers including front matter, independently of gutter visibility. It SHALL select the most specific block covering the target, the next block for blank lines, or the final block for targets beyond the last block.

#### Scenario: Front matter and code blocks
- **WHEN** the target falls after front matter or inside a fenced code block with the gutter hidden
- **THEN** the corresponding original source block is located correctly

#### Scenario: Empty or out of range
- **WHEN** the file is empty or the target is beyond its final block
- **THEN** no scroll is attempted, or the final block is selected respectively

### Requirement: Isolated explicit navigation
Explicit targets SHALL override saved scroll once, including for already open documents. Pending requests SHALL be isolated by file and current render version and applied only after rendering completes. Target input SHALL NOT be evaluated as JavaScript.

#### Scenario: Concurrent or stale rendering
- **WHEN** two documents are opened with distinct targets and an older render finishes later
- **THEN** each current document receives only its own target and stale renders do not move the current view

#### Scenario: No explicit target
- **WHEN** a document opens without a valid explicit target
- **THEN** existing scroll restoration behavior is preserved
