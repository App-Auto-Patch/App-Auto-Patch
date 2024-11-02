#!/bin/bash

# This script returns the Patching Complete Date of App Auto Patch to Intune inventory.
#
# Make sure to set the Custom Attribute Data Type to "String".
# https://techitout.xyz/app-auto-patch

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Application Support/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/AppAutoPatchStatus" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
	aap_patchingcomplete=$(defaults read "${AAP_plist}" AAPPatchingCompleteDate | sed 's/.\{6\}$//' 2> /dev/null)
	[[ -n "${aap_patchingcomplete}" ]] && echo "${aap_patchingcomplete}"
	[[ -z "${aap_patchingcomplete}" ]] && echo "No patching complete date"
else
	echo "No AAP preference file."
fi

exit 0
