#!/bin/bash

# This script returns the count of display assertion deferrals for App Auto Patch to Intune inventory.
#
# Make sure to set the Custom Attribute Data Type to "String".
# https://techitout.xyz/app-auto-patch

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus.plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}" ]]; then
    displayAssertionCount=$(defaults read "${AAP_plist}" "AAPDisplayAssertionCount" 2> /dev/null)
    [[ -n "${displayAssertionCount}" ]] && echo "${displayAssertionCount}"
    [[ -z "${displayAssertionCount}" ]] && echo "No display assertion deferrals"
else
    echo "No AAP Deferral preference file."
fi

exit 0
