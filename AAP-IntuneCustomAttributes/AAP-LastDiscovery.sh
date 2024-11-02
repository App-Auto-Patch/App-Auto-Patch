#!/bin/bash

# This script returns the last discovery run time of App Auto Patch to Intune inventory.
#
# Make sure to set the Custom Attribute Data Type to "String".
# https://techitout.xyz/app-auto-patch

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
    aap_discovery=$(defaults read "${AAP_plist}" AAPDiscovery | sed 's/.\{6\}$//' 2> /dev/null)
    [[ -n "${aap_discovery}" ]] && echo "${aap_discovery}"
    [[ -z "${aap_discovery}" ]] && echo "No last discovery"
else
    echo "No AAP preference file."
fi

exit 0
