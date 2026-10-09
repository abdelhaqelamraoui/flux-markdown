## 1. Approval and feasibility
- [x] 1.1 Obtain approval to try the development feasibility spike. System permission changes and enabling interception are not authorized by this step.
- [x] 1.2 Inspect public remote AX attribution in a normal preview: marker is visible but its reported owner is Finder, so direct attribution failed.
- [ ] 1.2a Review an authenticated cross-process refinement before further interception work; full-screen attribution is not yet established.
- [ ] 1.3 Verify scoped tap, native search action and safe event consumption in Finder.

## 2. Implementation
- [ ] 2.1 Write failing route/lifecycle tests before implementing the helper.
- [ ] 2.2 Add the embedded helper target and robust target validation/action dispatch.
- [ ] 2.3 Add explicit opt-in, permission status, disable/stop and localized settings.
- [ ] 2.4 Integrate allowlisted diagnostics/history without recording keyboard input.
- [ ] 2.5 Validate compatibility, signed update identity and installation/uninstall cleanup.

## 3. Verification and release
- [ ] 3.1 Complete real Finder positive and negative runtime scenarios from the design.
- [ ] 3.2 Update the unified candidate and acceptance evidence; obtain user acceptance.
- [ ] 3.3 Reply and label done only after a confirmed released fix; do not close the issue.

## 4. User-directed launch-only trial
- [x] 4.1 Replace the lengthy failure hint with the requested double-click/⌘F wording.
- [x] 4.2 Implement an authenticated, sandboxed, on-demand own-app search launch service.
- [x] 4.3 Verify actual Finder button → file → focused input → typed Alpha in Debug and Release candidates.
- [x] 4.4 Verify warm-app query preservation, unchanged editors, release signatures and minimal service entitlements.
- [ ] 4.5 Include this route in unified user acceptance and eventual release. Global shortcut work above remains incomplete.
