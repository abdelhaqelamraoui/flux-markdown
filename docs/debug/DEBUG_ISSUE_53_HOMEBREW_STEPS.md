# Issues #53 / #55: Homebrew postflight migration

Sources:
- https://github.com/xykong/flux-markdown/issues/53
- https://github.com/xykong/flux-markdown/issues/55 (duplicate, labeled accordingly)
- https://docs.brew.sh/Cask-Cookbook#cask-artifact-trust-and-sandboxing
- https://docs.brew.sh/Cask-Cookbook#stanza-flight_steps

## Acceptance before migration

Removing the warning must preserve actual extension registration on clean install,
upgrade and reinstall, including Apple Silicon/Intel prefixes and non-GUI users.
Style checks or ignoring failures do not satisfy acceptance. Application opening
and preview selection must be checked separately; user editor preferences must
not be used to conceal a registration failure.

## Experiments and source findings (2026-10-08)

1. The shipping tap still uses legacy postflight with xattr, lsregister,
   qlmanage, pluginkit and duti. The tap worktree has not been changed.
2. The comment on #53 reports a real reinstall regression after a steps port.
3. Current Homebrew documentation explicitly says sandboxed operations cannot
   use LaunchServices registration/launch and network_access does not lift that
   restriction. It still allows legacy flight blocks temporarily for third-party taps.
4. Local Homebrew is 5.1.15-221-g259096e. A parse-only scratch Cask using
   postflight_steps with a read-only pluginkit run fails with CaskInvalidError:
   undefined method run for Homebrew::InstallSteps::DSL. No install or registration
   was performed. This confirms a compatibility issue on this local version; it
   does NOT reproduce the newer Homebrew XPC failure in the comment.
5. The local Installer artifact sorts BEFORE App. Merely moving postflight
   commands to an installer script referencing the final app is also unsafe on
   a fresh install: the final application may not yet exist.
6. The adjacent tap has no flux-markdown-official.rb, despite older repository
   instructions naming that draft. Any future change must inventory real assets.

## Disposition

Do not ship a rename-only change or hide failed registration with must_succeed:false.
The warning remains open until a supported registration path is validated. Proposed
next direction: a vendor-owned installer/package that owns application placement
and registration with explicit uninstall bookkeeping, or an upstream-supported
registration allowance. This changes packaging rather than just a stanza name.
A concrete packaging proposal is required before implementation.

## Prepared response (English; not posted)

Thank you for the detailed migration testing. This is more than a stanza rename:
registration must still work on a fresh installation. Homebrew's current sandbox
policy restricts LaunchServices operations, and network_access is not a solution
for those restrictions. The local older Homebrew DSL also does not accept run in
postflight_steps, so we need compatibility validation as well.

The legacy third-party-tap form remains supported temporarily. We are keeping
registration behavior while evaluating a supported installation path. The warning
is not yet fixed; a migration will only be shipped after real install/reinstall
and QuickLook verification. #55 tracks the same problem.
