#!/bin/bash

# This script returns the Patching Completion Status of App Auto Patch 3.0.0 to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "String".
# by Andrew Spokes (@techtrekkie)
# 03.07.2025

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Management/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/xyz.techitout.appAutoPatch" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
    AAPPatchingCompletionStatus=$(defaults read "${AAP_plist}" AAPPatchingCompletionStatus 2> /dev/null)
    if [[ "${AAPPatchingCompletionStatus}" == 1 ]]; then
        echo "<result>TRUE</result>"
    else 
        echo "<result>FALSE</result>"
    fi
else
    echo "<result>No AAP preference file.</result>"
fi

exit 0
