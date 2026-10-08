#!/bin/bash
# Read-only, allowlisted diagnostics for issue #49. No file contents or paths in output.
set -u
app_path="/Applications/FluxMarkdown.app"
probe_file=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --app) [ "$#" -ge 2 ] || exit 2; app_path="$2"; shift 2 ;;
        --file) [ "$#" -ge 2 ] || exit 2; probe_file="$2"; shift 2 ;;
        *) printf '%s\n' 'Usage: diagnose-quicklook.sh [--app APP_BUNDLE] [--file MARKDOWN_FILE]'; exit 2 ;;
    esac
done
scalar() {
    local value="$1"
    if [ -z "$value" ]; then printf '%s' unknown
    elif [[ "$value" =~ ^[a-zA-Z0-9._-]+$ ]] && [ "${#value}" -le 128 ]; then printf '%s' "$value"
    else printf '%s' invalid
    fi
}
plist() {
    /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist" 2>/dev/null || true
}
field() { printf '%s=%s\n' "$1" "$(scalar "$2")"; }
printf '%s\n' 'FluxMarkdown QuickLook diagnostics (read-only; no document contents or paths)'
field macos_version "$(/usr/bin/sw_vers -productVersion)"
field macos_build "$(/usr/bin/sw_vers -buildVersion)"
field architecture "$(/usr/bin/uname -m)"
field app_version "$(plist "$app_path" CFBundleShortVersionString)"
field app_build "$(plist "$app_path" CFBundleVersion)"
field app_display_version "$(plist "$app_path" FMDisplayVersion)"
field app_document_rank "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDocumentTypes:0:LSHandlerRank' "$app_path/Contents/Info.plist" 2>/dev/null || true)"
extension_path="$app_path/Contents/PlugIns/MarkdownPreview.appex"
field extension_version "$(plist "$extension_path" CFBundleShortVersionString)"
field extension_point "$(plist "$extension_path" NSExtension:NSExtensionPointIdentifier)"
if /usr/bin/codesign --verify --deep --strict "$app_path" >/dev/null 2>&1; then
    printf '%s\n' 'app_signature_verification=passed'
else
    printf '%s\n' 'app_signature_verification=failed'
fi
if /usr/bin/codesign --verify --strict "$extension_path" >/dev/null 2>&1; then
    printf '%s\n' 'extension_signature_verification=passed'
else
    printf '%s\n' 'extension_signature_verification=failed'
fi
if /usr/sbin/spctl --assess --type execute "$app_path" >/dev/null 2>&1; then
    printf '%s\n' 'gatekeeper_assessment=accepted'
else
    printf '%s\n' 'gatekeeper_assessment=rejected-or-unavailable'
fi
registrations=$(/usr/bin/pluginkit -m -A -D -i com.xykong.Markdown.QuickLook 2>/dev/null)
registration_status=$?
if [ "$registration_status" -eq 0 ]; then
    printf '%s\n' "$registrations" | /usr/bin/awk '
        /com\.xykong\.Markdown\.QuickLook\(/ {
            total++; if ($1 == "+") enabled++; if ($1 == "-") disabled++;
        }
        END { printf "extension_registrations=%d\nextension_enabled_registrations=%d\nextension_disabled_registrations=%d\n", total, enabled, disabled }'
else
    printf '%s\n' 'extension_registrations=unavailable'
fi
first_id=$(/usr/bin/defaults read com.apple.preferences.extensions.QuickLook displayOrder 2>/dev/null |
    /usr/bin/sed -E 's/[",()]//g; s/^[[:space:]]+//; s/[[:space:]]+$//' |
    /usr/bin/grep -E '^[a-zA-Z0-9_-]+(\.[a-zA-Z0-9_-]+)+$' | /usr/bin/head -n 1)
if [ -z "$first_id" ]; then printf '%s\n' 'flux_first_in_saved_order=unknown'
elif [ "$first_id" = "com.xykong.Markdown.QuickLook" ]; then printf '%s\n' 'flux_first_in_saved_order=true'
else printf '%s\n' 'flux_first_in_saved_order=false'; fi
if command -v duti >/dev/null 2>&1; then
    field default_md_handler "$(duti -x md 2>/dev/null | /usr/bin/tail -n 1)"
else printf '%s\n' 'default_md_handler=unavailable'; fi
if [ -n "$probe_file" ]; then
    if uti=$(/usr/bin/mdls -name kMDItemContentType -raw "$probe_file" 2>/dev/null) && [ "$uti" != "(null)" ]; then
        field probe_file_uti "$uti"
    else
        printf '%s\n' 'probe_file_uti=unavailable'
    fi
fi
printf '%s\n' 'selected_preview_provider=unknown' \
    'Note: registration/order/association do not prove which provider Finder actually selected.' \
    'Note: Gatekeeper rejection of an ad-hoc development build alone does not establish the cause.'
