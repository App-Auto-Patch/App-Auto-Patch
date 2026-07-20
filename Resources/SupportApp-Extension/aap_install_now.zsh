#!/bin/zsh --no-rcs

# Support App Extension - App Auto-Patch Install Now Button Action
#
# Triggers an immediate App Auto-Patch (AAP) patching run via
# `appautopatch --workflow-install-now`, then refreshes the pending-updates
# count Extension (aap_pending_updates.zsh) so the Support App reflects the
# result right away.
#
# REQUIREMENTS:
# - App Auto-Patch 3.6.0 or later, installed and available at
#   /usr/local/bin/appautopatch
# - Deployed as a Privileged Script referenced by a Button item's Action, via
#   a Support App Configuration Profile (ActionType: PrivilegedScript)
#
# --workflow-install-now bypasses any deferral workflow and displays all AAP
# dialogs to the user (ignoring InteractiveMode), regardless of who or what
# triggers it - see: https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Workflows

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

# Support App preference plist
preference_file_location="/Library/Preferences/nl.root3.support.plist"

# Start spinning indicator and show an in-progress placeholder
defaults write "${preference_file_location}" "${extension_id}_loading" -bool true
defaults write "${preference_file_location}" "${extension_id}" -string "Installing Updates…"

# Run the App Auto-Patch install-now workflow. This runs in the foreground and
# blocks until the workflow completes (all dialogs, downloads, and installs),
# so the refresh step below always reflects the finished result.
if [[ -x "${appautopatch_bin}" ]]; then
    "${appautopatch_bin}" --workflow-install-now
else
    echo "ERROR: ${appautopatch_bin} not found or not executable." >&2
fi

# Refresh the pending-updates count now that the run has finished. This also
# handles clearing the loading indicator and setting/clearing the alert badge,
# so no further cleanup is needed here.
if [[ -x "${refresh_script_path}" ]]; then
    "${refresh_script_path}"
else
    echo "ERROR: ${refresh_script_path} not found or not executable." >&2
    # Fall back to at least clearing the loading indicator so the tile
    # doesn't get stuck spinning if the refresh script is missing.
    defaults write "${preference_file_location}" "${extension_id}_loading" -bool false
fi
