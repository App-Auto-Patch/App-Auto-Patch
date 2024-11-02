#!/bin/bash

# This script returns the deferrals remaining of App Auto Patch to Intune inventory.
#
# Make sure to set the Custom Attribute Data Type to "String".
# https://techitout.xyz/app-auto-patch

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus.plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}" ]]; then
    remainingDeferrals=$(defaults read "${AAP_plist}" "remainingDeferrals" 2> /dev/null)
    [[ -n "${remainingDeferrals}" ]] && echo "${remainingDeferrals}"
    [[ -z "${remainingDeferrals}" ]] && echo "No last deferrals"
else
    echo "No AAP preference file."
fi

exit 0
