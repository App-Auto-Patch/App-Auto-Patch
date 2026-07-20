#!/bin/zsh --no-rcs

# Support App Extension - App Auto-Patch Pending Updates Count
#
# Populates a Root3 Support App Extension with the number of applications
# currently queued for patching by App Auto-Patch (AAP), read from AAP's
# report PLIST (xyz.techitout.appAutoPatchReport.plist).
#
# REQUIREMENTS:
# - App Auto-Patch 3.6.0 or later (introduced the report PLIST)
# - Deployed as a Privileged Script referenced by a Support App Extension's
#   OnAppearAction, via a Support App Configuration Profile
#
# This script is intended to be run every time the Support App popover
# appears, so the count is always current. See the companion script,
# aap_install_now.zsh, for the button action that triggers a patch run and
# then re-runs this script to refresh the count.

# ------------------    edit the variables below this line    ------------------

# Extension ID - must match the ExtensionID configured for this Extension in
# the Support App Configuration Profile
extension_id="aap_pending_updates"

# App Auto-Patch install folder - only needs to change if you've customized
# AAP's default appAutoPatchFolder value
aapFolder="/Library/Management/AppAutoPatch"

# Text shown when there are zero pending updates
uptodate_text="Up to Date"

# ---------------------    do not edit below this line    ----------------------

# Support App preference plist
preference_file_location="/Library/Preferences/nl.root3.support.plist"

# AAP's report PLIST tracking currently-queued (pending) updates
aapReportPLIST="${aapFolder}/xyz.techitout.appAutoPatchReport.plist"

# Start spinning indicator
defaults write "${preference_file_location}" "${extension_id}_loading" -bool true

# Show placeholder while loading
defaults write "${preference_file_location}" "${extension_id}" -string "KeyPlaceholder"

# Count entries in AAP's ItemsToInstall array. If the report PLIST doesn't
# exist yet (e.g. AAP hasn't completed its first discovery run), treat that
# as zero pending updates rather than an error.
if [[ -f "${aapReportPLIST}" ]]; then
    pending_count=$(/usr/libexec/PlistBuddy -c "Print :ItemsToInstall" "${aapReportPLIST}" 2> /dev/null | grep -cE '^    Dict \{')
else
    pending_count=0
fi

# Build the display string
if [[ "${pending_count}" -eq 0 ]]; then
    display_text="${uptodate_text}"
elif [[ "${pending_count}" -eq 1 ]]; then
    display_text="1 Update Pending"
else
    display_text="${pending_count} Updates Pending"
fi

# Set output value
defaults write "${preference_file_location}" "${extension_id}" -string "${display_text}"

# Trigger the warning badge whenever there's at least one pending update
if [[ "${pending_count}" -gt 0 ]]; then
    defaults write "${preference_file_location}" "${extension_id}_alert" -bool true
else
    defaults write "${preference_file_location}" "${extension_id}_alert" -bool false
fi

# Stop spinning indicator
defaults write "${preference_file_location}" "${extension_id}_loading" -bool false
