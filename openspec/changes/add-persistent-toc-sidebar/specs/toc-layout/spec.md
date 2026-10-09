## ADDED Requirements

### Requirement: Nonoverlapping persistent contents
The renderer SHALL display a docked table of contents beside the document in app and expanded QuickLook viewports of at least 900 CSS px, reserving document space instead of covering content. Documents without headings SHALL NOT reserve an empty sidebar.

#### Scenario: Long document in a wide viewport
- **WHEN** a document with headings opens in a wide app or expanded QuickLook viewport
- **THEN** contents can remain visible while the complete document area stays unobstructed

### Requirement: Responsive contents and user choice
Narrow viewports SHALL use a collapsible contents overlay. Docked visibility preferences SHALL persist within the view session across reloads, theme changes, and viewport resizing, independently of the temporary overlay state. Layout transitions SHALL preserve reading position.

#### Scenario: User closes contents before resize
- **WHEN** the user closes contents and then resizes, reloads, or changes theme
- **THEN** contents stays closed and the document keeps its reading position

### Requirement: Compact preview and exported layout
Finder compact previews SHALL retain their compact presentation. Printing, HTML export and PDF export SHALL omit contents controls and sidebar spacing. Contents controls SHALL support keyboard access and both appearance modes.

#### Scenario: Export a docked document
- **WHEN** a document with docked contents is printed or exported
- **THEN** only the document layout is exported without contents controls or reserved sidebar space


### Requirement: Reserved reading controls
The renderer SHALL place contents and blockquote controls beside the existing native controls when space permits, using a compact extra row only when necessary. Search SHALL use a temporary horizontally centered floating panel over the document area without reserving layout height or shifting the document. Permanent controls SHALL NOT cover document text or docked contents.

#### Scenario: Floating search and contents visible
- **WHEN** search opens while contents is docked
- **THEN** the search panel is centered over the document column, the reading position stays unchanged and no extra toolbar row is allocated

### Requirement: Independent docked preference and temporary overlay
The renderer SHALL retain docked visibility preference independently of narrow overlay visibility. Shrinking to a narrow viewport SHALL close the overlay; returning to a wide viewport SHALL restore docked preference. Successful narrow-overlay navigation SHALL close the overlay.

#### Scenario: Narrow navigation preserves wide preference
- **WHEN** a user hides docked contents, shrinks the window, opens the overlay and selects a heading, then widens the window
- **THEN** navigation succeeds, the temporary overlay closes and docked contents remains hidden

#### Scenario: QuickLook overlay dismissal
- **WHEN** the user clicks outside an open contents overlay in expanded QuickLook
- **THEN** the overlay closes without requiring keyboard focus or interception of system shortcuts

### Requirement: Persistent side selection and aligned entrance
The application SHALL offer Left and Right contents positions in Appearance settings, default to Right and persist the choice through the existing shared settings. App and QuickLook renderer options SHALL carry the choice. The entrance and temporary/docked directory SHALL appear on the selected side. Right-side shared controls SHALL leave 12 CSS px before native tools. Changing side SHALL preserve visibility, reading position and the current search query; floating search SHALL center over the document column.

#### Scenario: User selects left
- **WHEN** the user changes contents position to Left
- **THEN** the app moves directory and entrance left without reopening closed contents or resetting search, and reopening the app or a QuickLook preview uses Left

#### Scenario: Missing or invalid setting
- **WHEN** no valid position is stored
- **THEN** the directory and entrance use Right
