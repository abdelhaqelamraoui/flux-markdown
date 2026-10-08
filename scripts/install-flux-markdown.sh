#!/bin/bash
# Vendor-owned Homebrew installer. This script owns placement because Homebrew's
# installer artifact runs before app artifacts; no postflight sandbox is used.
set -euo pipefail
source_app=""
app_dir=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --source) [ "$#" -ge 2 ]; source_app="$2"; shift 2 ;;
        --appdir) [ "$#" -ge 2 ]; app_dir="$2"; shift 2 ;;
        *) printf '%s\n' 'Usage: install-flux-markdown.sh --source APP --appdir DIRECTORY' >&2; exit 2 ;;
    esac
done
[[ "$source_app" = /* && "$app_dir" = /* ]] || { printf '%s\n' 'Absolute source and application directory required.' >&2; exit 2; }
[ -d "$source_app" ] && [ -x "$source_app/Contents/MacOS/FluxMarkdown" ] || exit 2
identifier=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$source_app/Contents/Info.plist")
[ "$identifier" = 'com.xykong.Markdown' ] || exit 2
/usr/bin/codesign --verify --deep --strict "$source_app"
# Preserve the legacy third-party tap's quarantine handling, without altering bytes.
/usr/bin/xattr -cr "$source_app"
editor_state=$("$source_app/Contents/MacOS/FluxMarkdown" --default-md-state)
mkdir -p "$app_dir"
target="$app_dir/FluxMarkdown.app"
work=$(mktemp -d "$app_dir/.flux-install.XXXXXX")
placed=false
cleanup() {
    status=$?
    trap - EXIT
    if [ "$status" -ne 0 ] && [ "$placed" = true ]; then
        rm -rf "$target"
        if [ -e "$work/previous.app" ] || [ -L "$work/previous.app" ]; then
            mv "$work/previous.app" "$target"
            if [ -d "$target/Contents/PlugIns/MarkdownPreview.appex" ]; then
                /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$target" >/dev/null 2>&1 || true
                /usr/bin/pluginkit -a "$target/Contents/PlugIns/MarkdownPreview.appex" >/dev/null 2>&1 || true
            fi
        fi
        printf '%s\n' 'Registration failed; previous application restored.' >&2
    fi
    rm -rf "$work"
    exit "$status"
}
trap cleanup EXIT
/usr/bin/ditto "$source_app" "$work/FluxMarkdown.app"
/usr/bin/codesign --verify --deep --strict "$work/FluxMarkdown.app"
if [ -e "$target" ] || [ -L "$target" ]; then mv "$target" "$work/previous.app"; fi
# Set the flag before rename so a failed placement also restores the old bundle.
placed=true
mv "$work/FluxMarkdown.app" "$target"
"$target/Contents/MacOS/FluxMarkdown" --repair-quicklook --editor-state "$editor_state"
printf '%s\n' 'FluxMarkdown installed and Quick Look registered. Existing editor preferences preserved.'
