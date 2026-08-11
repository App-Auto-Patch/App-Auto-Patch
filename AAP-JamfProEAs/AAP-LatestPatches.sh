#!/bin/zsh --no-rcs

# This script returns the latest patch results per app label. Example output:
#
# Success:
# <label> | <version> | <timestamp> | <exitCode> | <status>
#
# Failure:
# <label> | <version> | <timestamp> | <exitCode> | <status>
#
# Hardened for jamf recon: avoids NUL-delimited reads / process substitution
# (which can stall inventory when Jamf keeps stdin open), always emits
# <result>, and uses a temp file for the find listing.
#
# https://techitout.xyz/app-auto-patch
# 08.11.2026

# Do not use `set -e` here: an EA must always emit <result> or jamf recon
# waits out the EA timeout and appears hung.
set -u

appAutoPatchReceiptsFolder="/Library/Management/AppAutoPatch/receipts"
max_items=300

emit() {
    printf '<result>%s</result>\n' "$1"
    exit 0
}

trap 'emit "AAP LatestPatches EA error"' ERR

[[ -d "$appAutoPatchReceiptsFolder" ]] || emit "No AAP receipts found"

# Extract a JSON key (raw) via plutil; empty on failure
jx() {
    /usr/bin/plutil -extract "$2" raw -o - "$1" 2>/dev/null || true
}

success_lines=()
failure_lines=()
count=0

tmp_list="$(/usr/bin/mktemp /tmp/aap-latestpatches.XXXXXX)" || emit "AAP LatestPatches EA error (mktemp)"

# Newline-delimited listing into a file — no -print0 / sort -z / process
# substitution, and never read from the script's stdin.
/usr/bin/find "$appAutoPatchReceiptsFolder" -maxdepth 2 -type f -name latest.json 2>/dev/null \
    | /usr/bin/sort > "$tmp_list"

while IFS= read -r f || [[ -n "${f:-}" ]]; do
    [[ -z "${f:-}" ]] && continue
    [[ -f "$f" ]] || continue

    label="$(/usr/bin/basename "$(/usr/bin/dirname "$f")")"
    version="$(jx "$f" version)"
    timestamp="$(jx "$f" timestamp)"
    exitCode="$(jx "$f" exitCode)"
    patch_status="$(jx "$f" status)"

    [[ -n "$version" ]] || version="unknown"
    [[ -n "$timestamp" ]] || timestamp="unknown"
    [[ "$exitCode" =~ ^[0-9]+$ ]] || exitCode=0
    if [[ -z "$patch_status" ]]; then
        if [[ "$exitCode" -eq 0 ]]; then
            patch_status="success"
        else
            patch_status="failed"
        fi
    fi

    line="$label | $version | $timestamp | $exitCode | $patch_status"
    if [[ "$patch_status" == "failed" ]]; then
        failure_lines+=("$line")
    else
        success_lines+=("$line")
    fi

    count=$((count + 1))
    (( count >= max_items )) && break
done < "$tmp_list"

/bin/rm -f "$tmp_list" 2>/dev/null || true

success_sorted=()
failure_sorted=()
if (( ${#success_lines[@]} )); then
    success_sorted=("${(@f)$(printf '%s\n' "${success_lines[@]}" | /usr/bin/sort -f)}")
fi
if (( ${#failure_lines[@]} )); then
    failure_sorted=("${(@f)$(printf '%s\n' "${failure_lines[@]}" | /usr/bin/sort -f)}")
fi

result="Success:"
if (( ${#success_sorted[@]} )); then
    result+=$'\n'"${(F)success_sorted}"
fi
result+=$'\n\nFailure:'
if (( ${#failure_sorted[@]} )); then
    result+=$'\n'"${(F)failure_sorted}"
fi

emit "$result"
