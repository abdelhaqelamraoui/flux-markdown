## ADDED Requirements

### Requirement: Nonoverlapping persistent contents
The renderer SHALL display a docked table of contents beside the document in app and expanded QuickLook viewports of at least 900 CSS px, reserving document space instead of covering content. Documents without headings SHALL NOT reserve an empty sidebar.

#### Scenario: Long document in a wide viewport
- **WHEN** a document with headings opens in a wide app or expanded QuickLook viewport
- **THEN** contents can remain visible while the complete document area stays unobstructed

### Requirement: Responsive contents and user choice
Narrow viewports SHALL use a collapsible contents overlay. User visibility choices SHALL persist within the view session across reloads, theme changes, and viewport resizing. Layout transitions SHALL preserve reading position.

#### Scenario: User closes contents before resize
- **WHEN** the user closes contents and then resizes, reloads, or changes theme
- **THEN** contents stays closed and the document keeps its reading position

### Requirement: Compact preview and exported layout
Finder compact previews SHALL retain their compact presentation. Printing, HTML export and PDF export SHALL omit contents controls and sidebar spacing. Contents controls SHALL support keyboard access and both appearance modes.

#### Scenario: Export a docked document
- **WHEN** a document with docked contents is printed or exported
- **THEN** only the document layout is exported without contents controls or reserved sidebar space
