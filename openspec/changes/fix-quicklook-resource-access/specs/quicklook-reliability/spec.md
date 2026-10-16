## ADDED Requirements
### Requirement: Local preview resources
QuickLook SHALL render explicitly referenced supported images in accessible user-home locations without embedding the build machine's home path, with bounded reads and symlink rejection.
#### Scenario: Image read fails
- **WHEN** a referenced image cannot be read
- **THEN** diagnostics distinguish permission, missing-file and resource-limit failures
### Requirement: Honest preview status
The application SHALL distinguish registration success from confirmed preview execution and expose reviewable diagnostics without document contents.
#### Scenario: Large preview
- **WHEN** QuickLook truncates a document
- **THEN** a notice outside the parsed Markdown identifies incomplete content and offers opening the main application
