#!/bin/zsh --no-rcs

# Support App Extension - App Auto-Patch Pending Apps Dialog
#
# Thin wrapper around App Auto-Patch's built-in pending-apps dialog:
#   appautopatch --pending-apps-dialog
#
# Shows a simplified swiftDialog list of currently pending updates (app icon,
# name, and a "Current Version / New Version" subtitle for each), with only
# "Install Now" and "Later" buttons - no deferral timer or menu, unlike App
# Auto-Patch's (AAP's) own deferral dialog. Clicking "Install Now" installs the
# pending updates in-process (via AAP's standard install-now workflow, patching
# exactly the queue shown); "Later" just closes the dialog.
#
# Logic lives in App-Auto-Patch-via-Dialog.zsh (workflow_pending_apps_dialog)
# so appearance, language strings, banner/icon prefs, and Install Now behavior
# stay in sync with AAP (including the queued-apps banner notification action).
#
# REQUIREMENTS:
# - App Auto-Patch 3.7.0 or later (build with --pending-apps-dialog), with swiftDialog
# - Deployed as a Privileged Script referenced by an Extension/Button item's
#   Action, via a Support App Configuration Profile (ActionType: PrivilegedScript)
# - Intended to replace aap_install_now.zsh as the pending-updates tile's
#   Action - clicking the tile now shows this dialog first, instead of
#   silently running --workflow-install-now immediately
#
# Optional customization: the "Later" button text is AAP language key
# display_string_pendingapps_button_later (managed dialogElements).

# ------------------    edit the variables below this line    ------------------

# Extension ID - must match the ExtensionID configured for the pending-updates
# Extension in the Support App Configuration Profile
extension_id="aap_pending_updates"

# Path to the App Auto-Patch binary/symlink
appautopatch_bin="/usr/local/bin/appautopatch"

# Path to the companion script that refreshes the pending-updates count.
# Update this if you deploy aap_pending_updates.zsh to a different location.
refresh_script_path="/Library/Management/AppAutoPatch/SupportApp/aap_pending_updates.zsh"

# ---------------------    do not edit below this line    ----------------------

preference_file_location="/Library/Preferences/nl.root3.support.plist"

if [[ ! -x "${appautopatch_bin}" ]]; then
    echo "ERROR: ${appautopatch_bin} not found or not executable." >&2
    defaults write "${preference_file_location}" "${extension_id}_loading" -bool false 2>/dev/null
    exit 1
fi

# Show a brief loading state on the Support App tile while AAP presents the dialog.
defaults write "${preference_file_location}" "${extension_id}_loading" -bool true
defaults write "${preference_file_location}" "${extension_id}" -string "Checking Updates…"

"${appautopatch_bin}" --pending-apps-dialog
dialog_exit=$?

# Refresh the pending-updates count so the tile reflects the current report PLIST
# (Install Now may still be running in the background after AAP exits).
if [[ -x "${refresh_script_path}" ]]; then
    "${refresh_script_path}"
else
    echo "ERROR: ${refresh_script_path} not found or not executable." >&2
    defaults write "${preference_file_location}" "${extension_id}_loading" -bool false
fi

exit "${dialog_exit}"
