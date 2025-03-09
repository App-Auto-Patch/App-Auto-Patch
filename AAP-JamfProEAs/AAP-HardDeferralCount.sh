#!/bin/bash

# This script returns the count of Hard deferrals for App Auto Patch 3.0.0 to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "Integer".
# by Andrew Spokes (@techtrekkie)
# 03.07.2025

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Management/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/xyz.techitout.appAutoPatch" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
    DeadlineCounterHard=$(defaults read "${AAP_plist}" "DeadlineCounterHard" 2> /dev/null)
    [[ -n "${DeadlineCounterHard}" ]] && echo "<result>${DeadlineCounterHard}</result>"
    [[ -z "${DeadlineCounterHard}" ]] && echo "<result>No Hard deferrals</result>"
else
    echo "<result>No AAP preference file.</result>"
fi

exit 0
