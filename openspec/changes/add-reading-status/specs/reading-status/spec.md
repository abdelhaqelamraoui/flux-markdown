## ADDED Requirements
### Requirement: Compact reading orientation
The renderer SHALL show a muted single-line current heading path and scroll position in the existing toolbar without increasing its height.

#### Scenario: Scrolling a long document
- **WHEN** the active heading changes
- **THEN** the path follows the same heading as the contents panel and shows at most two levels with a full-path tooltip
- **AND** position is clamped between 0 and 100 percent

#### Scenario: Short document
- **WHEN** the document cannot scroll
- **THEN** no percentage is shown

#### Scenario: Limited width or left contents
- **WHEN** available toolbar space shrinks or contents move left
- **THEN** status fits the remaining space without overlapping controls or adding a row

#### Scenario: Context and updates
- **WHEN** a QuickLook document renders
- **THEN** its filename can appear when space permits
- **WHEN** previously rendered content changes
- **THEN** a localized update notice appears briefly
- **WHEN** source mode or compact Finder preview is active
- **THEN** reading status is hidden
