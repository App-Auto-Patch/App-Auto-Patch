#!/bin/bash

# This script returns the version of App Auto Patch that was last used
# to Intune inventory.
#
# Make sure to set the Custom Attribute Data Type to "String".
# https://techitout.xyz/app-auto-patch

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
    aap_version=$(defaults read "${AAP_plist}" AAPVersion 2> /dev/null)
    [[ -n "${aap_version}" ]] && echo "${aap_version}"
    [[ -z "${aap_version}" ]] && echo "No AAP version number found."
else
    echo "No AAP preference file."
fi

exit 0
