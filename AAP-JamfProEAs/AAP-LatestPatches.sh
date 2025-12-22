#!/bin/zsh --no-rcs

# This script returns the latest patch results per app label. Example output: 

# Success:
# <label> | <version> | <timestamp> | <exitCode> | <status>
#
# Failure:
# <label> | <version> | <timestamp> | <exitCode> | <status>

# https://techitout.xyz/app-auto-patch
# 12.22.2025

set -euo pipefail

# Patch to the App Auto Patch receipts folder:
appAutoPatchReceiptsFolder="/Library/Management/AppAutoPatch/receipts"

# If no receipts folder exists, exit
[[ -d "$appAutoPatchReceiptsFolder" ]] || { echo "<result>No AAP receipts found</result>"; exit 0; }

# Extract a JSON key (raw) via plutil; empty on failure
jx() { /usr/bin/plutil -extract "$2" raw -o - "$1" 2>/dev/null || true; }

# Initialize arrays to hold success and failure lines
success_lines=()
failure_lines=()

# Cap to keep EA size reasonable (tune as needed)
max_items=300
count=0

# Find each label's latest.json (depth: receipts/<label>/latest.json)
while IFS= read -r -d '' f; do
  label="$(basename "$(dirname "$f")")"
  version="$(jx "$f" version)";     [[ -z "$version" ]] && version="unknown"
  timestamp="$(jx "$f" timestamp)";    [[ -z "$timestamp"  ]] && timestamp="unknown"
  exitCode="$(jx "$f" exitCode)";     [[ "$exitCode" =~ ^[0-9]+$ ]] || exitCode=0
  patch_status="$(jx "$f" status)"; [[ -z "$patch_status" ]] && patch_status=$([[ "$exitCode" -eq 0 ]] && echo success || echo failed)

  line="$label | $version | $timestamp | $exitCode | $patch_status"

  if [[ "$patch_status" == "failed" ]]; then
    failure_lines+=("$line")
  else
    success_lines+=("$line")
  fi

  count=$((count+1))
  [[ $count -ge $max_items ]] && break
done < <(/usr/bin/find "$appAutoPatchReceiptsFolder" -type f -name latest.json -maxdepth 2 -print0 2>/dev/null | /usr/bin/sort -z)

# Sort for stable output
IFS=$'\n' success_sorted=($(printf "%s\n" "${success_lines[@]}" | /usr/bin/sort -f 2>/dev/null || true))
IFS=$'\n' failure_sorted=($(printf "%s\n" "${failure_lines[@]}" | /usr/bin/sort -f 2>/dev/null || true))

# Build output
result="Success:"
if [[ ${#success_sorted[@]} -gt 0 ]]; then
  result+=$'\n'"$(printf "%s\n" "${success_sorted[@]}")"
fi

result+=$'\n\n'"Failure:"
if [[ ${#failure_sorted[@]} -gt 0 ]]; then
  result+=$'\n'"$(printf "%s\n" "${failure_sorted[@]}")"
fi

# Trim any trailing newline
result="$(echo -n "$result")"

echo "<result>$result</result>"
exit 0
