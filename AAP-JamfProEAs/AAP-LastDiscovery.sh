#!/bin/bash

# This script returns the last discovery run time of App Auto Patch to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "Date".
# https://techitout.xyz/app-auto-patch
# by Robert Schroeder (@robjschroeder)
# 10.20.2023

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
    aap_discovery=$(defaults read "${AAP_plist}" AAPDiscovery | sed 's/.\{6\}$//' 2> /dev/null)
    [[ -n "${aap_discovery}" ]] && echo "<result>${aap_discovery}</result>"
    [[ -z "${aap_discovery}" ]] && echo "<result>No last discovery</result>"
else
    echo "<result>No AAP preference file.</result>"
fi

exit 0
