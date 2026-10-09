## Status: shortcut work withdrawn — 2026-10-10

The user explicitly stopped further attempts to support Cmd+F directly inside the
Finder Quick Look preview, accepting the system constraints. Shortcut interception,
Accessibility helper development, remote-attestation refinements and inline-preview
keyboard-search acceptance are no longer planned or release gates. The historical
material below records the abandoned approach, not current product
requirements. Retain the verified native search button → containing app → editable
search route and normal Cmd+F in the standalone application. This decision does
not claim that the original Finder shortcut was implemented or that #54 is released.

# Quick Look shortcut helper feasibility

The user approved trying the proposal on October 9, while explicitly questioning
whether requiring Accessibility would deter normal users. This authorizes a
development feasibility spike, not enabling system permissions or making the
helper a mandatory product component.

## Acceptance before implementation

Build a separate, non-embedded probe which never creates an event tap, performs AX
actions, prompts for permission, or changes settings. Without Accessibility it must
return a bounded `permission-required` result and exit. With explicit permission,
it may inspect only roles, identifiers, actions and process identity in Finder's
focused window, never values, titles, text or paths in diagnostic output.

Add a per-preview UUID accessibility identifier to the native search button.
Eligibility requires all of: trusted reader, frontmost Finder, focused window,
valid UUID marker, button role/Press action, valid dynamic extension signature and
the expected extension executable within this app. A marker alone is insufficient.
Test positive eligibility, malformed markers, wrong executable/signer, missing
permission, another foreground app and absent Press action before implementation.

Only if the real remote AX bridge exposes verifiable identity may the interception
phase proceed. If it reports only Finder's process identity, fail closed on target
selection and leave events unchanged. Unit tests do not establish remote viability.

## Product decision

Do not embed, auto-launch, register a login item or expose an enable setting during
this spike. Keep the no-permission native search button as the default path. A
successful prototype is evidence for an optional advanced feature, not a reason
to demand Accessibility from every user. Permission acceptance must be measured
with users; no adoption rate is inferred from this single concern.

## Results

- Four eligibility tests failed to compile before the policy existed and now pass.
- 24 policy/search/toolbar tests passed after implementation.
- Probe built and signed at `build/artifacts/FluxMarkdownShortcutProbe.app`, outside
  the main application dependency graph. Its source contains no event tap creation,
  permission prompt or AX action execution.
- Installed marker-only candidate: `1.34.475-dev-20261009-114213`; the standalone
  probe is not embedded or auto-started. Existing editor handlers were preserved.
- The CLI trust query returned true under this launch context. No authorization
  request was made. This is not proof of independent helper TCC authorization; the
  ordinary-user denied-permission runtime case was not reproduced in this session.
- With another foreground app, the probe returned `finder-not-frontmost` and exited.
- In Finder without Quick Look, it visited a bounded 256 nodes, found zero markers
  and returned `target-not-verified` with interception disabled.
- Space opened the actual candidate preview. The probe reported candidateCount=1,
  hostOwnedCandidateCount=1, authenticatedCandidateCount=0. Public AX attributed the
  button to Finder. It returned `target-not-verified` and left interception disabled.
- No document values, titles, text, search queries or paths were printed by the probe.

The direct AX identity strategy fails its initial feasibility gate. A secure remote
attestation route must be designed/reviewed before any tap is created. #54 remains
unresolved; neither the marker nor the passing policy tests proves shortcut support.
Given the permission cost, retain the native search button as the default product
path and keep the helper as a development experiment pending further evidence.

## Repeatable developer commands

```sh
xcodebuild -project FluxMarkdown.xcodeproj -target QuickLookShortcutProbe \
  -configuration Debug MACOSX_DEPLOYMENT_TARGET=12.0 ARCHS=arm64 \
  CONFIGURATION_BUILD_DIR=/tmp/flux-shortcut-probe-build build
build/artifacts/FluxMarkdownShortcutProbe.app/Contents/MacOS/FluxMarkdownShortcutProbe
build/artifacts/FluxMarkdownShortcutProbe.app/Contents/MacOS/FluxMarkdownShortcutProbe \
  --probe --app /Applications/FluxMarkdown.app --wait-seconds 15
```

Default invocation only reports existing trust. The probe never grants or prompts
for permission. `--probe` is read-only, bounded, and exits without an event listener.
