#!/bin/zsh --no-rcs

# This script returns the Next Scheduled Run of App Auto Patch 3.2.0 to Jamf inventory. 
# If PatchingCompletionStatus is True, date is calculated based on PatchingStartDate + daysUntilReset.
# If PatchingCompletionStatus if False, NextAutoLaunch date is used
# Make sure to set the Extension Attribute Data Type to "Date".
# 05.01.2025

zmodload zsh/datetime
AAP_folder="/Library/Management/AppAutoPatch"
AAP_plist="${AAP_folder}/xyz.techitout.appAutoPatch" # No trailing ".plist"

if [[ -f "${AAP_plist}.plist" ]]; then
  # Read and clean values
  #patchingCompleteDate=$(defaults read "${AAP_plist}" AAPPatchingCompleteDate 2>/dev/null | sed 's/.{6}$//')
  patchingStartDate=$(defaults read "${AAP_plist}" AAPPatchingStartDate 2>/dev/null)
  NextAutoLaunch=$(defaults read "${AAP_plist}" NextAutoLaunch 2>/dev/null)
  daysUntilReset=$(defaults read "${AAP_plist}" DaysUntilReset 2>/dev/null | tr -d '[:space:]')
  PatchingCompletionStatus=$(defaults read "${AAP_plist}" AAPPatchingCompletionStatus 2>/dev/null)


if [[ $PatchingCompletionStatus == 1 ]]; then
  # Validate both values
  if [[ -n "$patchingStartDate" && "$daysUntilReset" =~ ^[0-9]+$ ]]; then
    # Convert input date to epoch
    #patch_epoch=$(date -j -f "%Y-%m-%d" "$patchingStartDate" "+%s")
    patch_epoch=$(strftime -r "%Y-%m-%d" $patchingStartDate)
    
    # Add days in seconds
    next_epoch=$((patch_epoch + (daysUntilReset * 86400)))
    
    # Convert back to desired format
    #nextRunDate=$(date -j -r "$next_epoch" "+%Y-%m-%d %H:%M:%S")
    nextRunDate=$(date -j -r "$next_epoch" "+%Y-%m-%d")
    echo "<result>${nextRunDate}</result>"
  else
    echo "<result>Invalid data in plist</result>"
  fi

else
  echo "<result>${NextAutoLaunch}</result>"
  fi
else
  echo "<result>No AAP preference file.</result>"
fi

exit 0
