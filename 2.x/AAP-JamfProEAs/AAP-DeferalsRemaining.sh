#!/bin/bash

# This script returns the deferrals remaining of App Auto Patch to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "String".
# 03.20.24 @techtrekkie - updated to read from AppAutoPatchStatus.plist

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus.plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}" ]]; then
    remainingDeferrals=$(defaults read "${AAP_plist}" "remainingDeferrals" 2> /dev/null)
    [[ -n "${remainingDeferrals}" ]] && echo "<result>${remainingDeferrals}</result>"
    [[ -z "${remainingDeferrals}" ]] && echo "<result>No last deferrals</result>"
else
    echo "<result>No AAP preference file.</result>"
fi

exit 0
