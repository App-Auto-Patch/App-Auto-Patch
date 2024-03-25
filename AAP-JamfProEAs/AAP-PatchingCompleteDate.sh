#!/bin/bash

# This script returns the Patching Complete Date of App Auto Patch to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "Date".
# https://techitout.xyz/app-auto-patch
# by Andrew Spokes (@techtrekkie)
# 03.25.2024

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
	aap_patchingcomplete=$(defaults read "${AAP_plist}" AAPPatchingCompleteDate | sed 's/.\{6\}$//' 2> /dev/null)
	[[ -n "${aap_patchingcomplete}" ]] && echo "<result>${aap_patchingcomplete}</result>"
	[[ -z "${aap_patchingcomplete}" ]] && echo "<result>No patching complete date</result>"
else
	echo "<result>No AAP preference file.</result>"
fi

exit 0
