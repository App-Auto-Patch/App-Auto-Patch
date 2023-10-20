#!/bin/bash

# This script returns the version of App Auto Patch that was last used 
# to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "String".
# https://techitout.xyz/app-auto-patch
# by Robert Schroeder (@robjschroeder)
# 10.20.2023

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
    aap_version=$(defaults read "${AAP_plist}" AAPVersion 2> /dev/null)
    [[ -n "${aap_version}" ]] && echo "<result>${aap_version}</result>"
    [[ -z "${aap_version}" ]] && echo "<result>No AAP version number found.</result>"
else
    echo "<result>No AAP preference file.</result>"
fi

exit 0
