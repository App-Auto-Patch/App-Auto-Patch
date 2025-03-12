#!/bin/bash

# This script returns the Last Silent Run Date Date of App Auto Patch 3.0.0 to Jamf inventory. 
# Make sure to set the Extension Attribute Data Type to "Date".
# by Andrew Spokes (@techtrekkie)
# 03.11.2025

# Path to the App Auto Patch working folder:
AAP_folder="/Library/Management/AppAutoPatch"

# Path to the local property list file:
AAP_plist="${AAP_folder}/xyz.techitout.appAutoPatch" # No trailing ".plist"

# Report if the App Auto Patch preference file exists.
if [[ -f "${AAP_plist}.plist" ]]; then
	AAPLastSilentRunDate=$(defaults read "${AAP_plist}" AAPLastSilentRunDate | sed 's/.\{6\}$//' 2> /dev/null)
	[[ -n "${AAPLastSilentRunDate}" ]] && echo "<result>${AAPLastSilentRunDate}</result>"
	[[ -z "${AAPLastSilentRunDate}" ]] && echo "<result>No last silent run date</result>"
else
	echo "<result>No AAP preference file.</result>"
fi

exit 0
