#!/bin/bash

# This script returns the version of App Auto Patch that was last used for version 2.x and 3.x
# Make sure to set the Extension Attribute Data Type to "String".
# https://techitout.xyz/app-auto-patch
# by Andrew Spokes (@TechTrekkie)
# 03.07.2025

# Path to the App Auto Patch working folder:
AAP2_folder="/Library/Application Support/AppAutoPatch"
AAP3_folder="/Library/Management/AppAutoPatch"


# Path to the local property list file:
AAP2_plist="${AAP2_folder}/AppAutoPatchStatus" # No trailing ".plist"
AAP3_plist="${AAP3_folder}/xyz.techitout.appAutoPatch" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP3_plist}.plist" ]]; then
    aap_version=$(defaults read "${AAP3_plist}" AAPVersion 2> /dev/null)
    [[ -n "${aap_version}" ]] && echo "<result>${aap_version}</result>"
    [[ -z "${aap_version}" ]] && echo "<result>No AAP version number found.</result>"
elif [[ -f "${AAP2_plist}.plist" ]]; then
    aap_version=$(defaults read "${AAP2_plist}" AAPVersion 2> /dev/null)
    [[ -n "${aap_version}" ]] && echo "<result>${aap_version}</result>"
    [[ -z "${aap_version}" ]] && echo "<result>No AAP version number found.</result>"
else
    echo "<result>No AAP preference file.</result>"
fi

exit 0
