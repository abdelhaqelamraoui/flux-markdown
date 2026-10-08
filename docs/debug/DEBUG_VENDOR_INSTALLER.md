# Homebrew vendor installer and QuickLook recovery (#49/#53/#55)

The user authorized implementation on 2026-10-09. Current Homebrew documentation
supports vendor installer artifacts outside flight-step sandboxing; see
https://docs.brew.sh/Cask-Cookbook#installer-script . The vendor script owns app
placement (no later app artifact), verifies signatures, captures editor handlers,
installs via a temporary sibling, registers/enables the extension, sets its saved
preview priority while retaining other providers, and restores prior editor choices.
Known Spotlight scan error -10822 is warned; actual registration failures are fatal
and restore the previous bundle. The App has a Help → Repair Quick Look action
using the same headless backend.

## Automated checks

- Four signed-stub transaction tests passed: installation/reinstallation, failure
  rollback, failed fresh installation, invalid source. Other files remain unchanged.
- Three native runner/state validation tests passed; extension failure cannot be
  reported as success and editor restoration is attempted even on failure.
- Candidate Ruby syntax passed. A real Loader attempt in an isolated tap hit
  Homebrew's untrusted-tap gate. No trust setting was changed or bypassed; the
  temporary test definition/tap was removed. Full Homebrew Loader/install acceptance
  therefore remains unverified in that context.
- The production tap is intentionally not changed while its public v1.34.475 DMG
  lacks the helper. On release the cask updater verifies a mounted DMG contains the
  helper, fills the new template from the script-managed version/checksum, and then
  promotes it. Acceptance drafts are not publishable with their placeholder checksum.
- The official draft has no deprecated postflight hooks; it still requires a signed/
  notarized release before official submission. This is not a claim of notarization.

## Limits

Registration/priority recovery addresses a demonstrated failure class; it does not
prove the original Sequoia reporter's root cause. Runtime checks on the installed
candidate and default-editor preservation still follow before user acceptance.


## Actual installation observations

The first real install hit editor restore -50 for the public.markdown alias and
rolled back to the old bundle. The implementation now skips writes when handlers
are unchanged and verifies that successful return codes actually changed a handler.
Two added native tests cover unsupported alias writes and unapplied editor changes.
A subsequent real install succeeded and exact current per-type handlers (FluxMarkdown
and Word) were preserved. A separate attempt to simulate VS Code did not apply via
the deprecated setter despite a success code; the modern callback also did not finish
while the console was locked. The original handlers were restored. Do NOT count
that attempted VS Code scenario as a passed preservation test.

The console was independently confirmed locked. Native Finder keyboard/selection
acceptance and the original Sequoia report still need an unlocked console/affected
machine. No credentials or trust policy were changed to bypass these limits.
