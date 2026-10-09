# Quick Look search input cannot accept typing

## Reproduction and evidence

The reporter clicked the native search button in candidate
`1.34.475-dev-20261009-114213`. The HTML search field appeared but could not receive
typed input. This disproves the assumption that the button is a usable inline
fallback, despite the bridge unit tests passing.

The actual MarkdownPreview process log repeatedly reported:
`WARNING: Quick Look extensions should not have any views or subviews claim first responder`
at the same time as the controller attempted WebView focus. Search requests reported
renderer/search readiness, with no JS bridge failure. The remote host's keyboard
focus restriction is therefore directly implicated; changing HTML input attributes
alone does not repair the missing native keyboard recipient.

## Acceptance before implementation

- Clicking preview search opens the same file in the main FluxMarkdown app and
  focuses its working search UI, with no additional permission or helper.
- Chinese, spaces and ampersands in the file path survive the handoff.
- Cold-start, already-open and pending-render search requests are per-file and
  consumed once; repeated search requests retain an existing query.
- Preview creation/appearance/clicks must not explicitly claim first responder.
- Failed file opens discard only their own pending search request.
- Real application typing of Alpha yields 1/2, then Escape closes the search bar.
- The button's label explains that searching takes place in FluxMarkdown.
- Guidance must wrap in narrow previews and remain visible long enough to read.

## Scope

Use the existing app URL/open-document path with an explicit `find=1` flag and an
ephemeral bounded request store. This restores a usable no-permission search action;
it does not claim that Finder Cmd+F or inline Quick Look text input are fixed.

## Runtime route correction

The first real handoff test failed. Both generic NSWorkspace URL opening and
explicit containing-app opening returned failure; the latter reported Cocoa 256
with underlying NSOSStatus -54. Passing the selected file URL with a supported
OpenConfiguration Apple event also failed. The extensionContext host-open request
returned false. No sandbox permissions were broadened to bypass these results.

Therefore automatic handoff is opportunistic only. When the host refuses it, the
button displays localized, wrapping guidance for eight seconds: Finder → Open With
→ FluxMarkdown, then Cmd+F. It never displays an unusable HTML input. The actual
system-provided Open With button successfully launched the main app; Cmd+F followed
by synthetic keyboard typing of Alpha produced query=Alpha and counter=1/2. This
is a verified no-permission manual route, not a claim of automatic handoff success.

26 native URL/search/toolbar regressions passed, including denied-open guidance,
per-file URL encoding and refusing explicit preview first-responder claims.

Final installed candidate: `1.34.475-dev-20261009-121720`. Its actual Quick Look
button is localized as “在 FluxMarkdown 中搜索”. Clicking it displayed the localized
wrapping guidance and no Search query field. Main-app cold-start `find=1` displayed
the input; real keyboard typing of Alpha yielded 1/2. Repeating the request preserved
Alpha and 1/2; Escape removed search and kept the document open. No accessibility
permission, interception, sandbox weakening or default-editor change was introduced.

The final source cleanup was rebuilt and the same 26 regressions passed again.
Delivered candidate: `1.34.475-dev-20261009-122657`, with a verified compressed DMG
and unchanged per-type default-editor handlers. No issue is marked done or released.
