#!/bin/bash

# This script returns the count of display assertion deferrals for App Auto Patch to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "Integer".
# 03.20.24 @techtrekkie - updated to read from AppAutoPatchStatus.plist

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus.plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}" ]]; then
    displayAssertionCount=$(defaults read "${AAP_plist}" "AAPDisplayAssertionCount" 2> /dev/null)
    [[ -n "${displayAssertionCount}" ]] && echo "<result>${displayAssertionCount}</result>"
    [[ -z "${displayAssertionCount}" ]] && echo "<result>No display assertion deferrals</result>"
else
    echo "<result>No AAP Deferral preference file.</result>"
fi

exit 0
