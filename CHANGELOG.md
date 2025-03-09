# CHANGELOG

# Version 3

## Version 3.0.0
### 08-Mar-2025
- Final Version

## Version 3.0.0-beta10
### 06-Mar-2025
- Fixed logic for optional labels that may have been preventing them from being added to the queue
- Fixed various bugs with logging
- Fixed some references to the local PLIST when adding/modifying/deleting values
- Added static variable for workflow_install_now_patching_status_action for controlling completion status for workflow_install_now function
- Added command line trigger for `--days-until-reset=`
- Updated Usage output
- Various syntax fixes

## Version 3.0.0-beta9
### 10-Feb-2025
- Added `WorkflowDisableRelaunch`/`--workflow-disable-relaunch` functionality to prevent AAP from re-launching automatically
- Added `DeferralTimerWorkflowRelaunch`/`--deferral-timer-workflow-relaunch`
- Renamed `DeferralTimer` to `DialogTimeoutDeferral`, `DeferralTimerAction` to `DialogTimeoutDeferralAction`
- Added default menu selection on dialog as first option when using `DeferralTimerMenu`
- Added logic to ignore apps in '/Library/Application Support/JAMF/Composer'
- Various syntax fixes

## Version 3.0.0-beta8
### 09-Feb-2025
- Various Updates

## Version 3.0.0-beta7
### 08-Feb-2025
- Fixes for InteractiveMode

## Version 3.0.0-beta6
### 07-Feb-2025
- Changes to permissions for command file for SwiftDialog 2.5.5+

## Version 3.0.0-beta5
### 22-Dec-2024
- Fixed a bug with the Days Since Patching Start Date logic that was causing it to be a day behind
- Added preference key to set Dialog on top of other windows
- Added options to output version details
- Added logic for switching Installomator between Release and Main (beta) branches
- Set default branch to Main

## Version 3.0.0-beta4
### 14-Nov-2024
- Added logic for deferral-timer-menu to pull via MDM, local PLIST or CLI trigger

## Version 3.0.0-beta3
### 10-Nov-2024
 - Implemented Deferral Menu option to provide a drop-down list of deferral times. Deferral options can only be hard-coded at this time. Set variable on line 151 to deferral_timer_menu_minutes="60,120,480,1440" times are in minutes
 - Implemented PR #85 for additional MDM controls and specific additions for Intune (Thanks @gilburns ). Example Intune XML included

## Version 3.0.0-beta2
### 08-Nov-2024
- This is a minor update and does not include any new features. 
- This includes updates and bug fixes from 2.x made across 6 builds between versions 2.11.1 and 2.11.4

## Version 3.0.0-beta1
### 08-Nov-2024
- Introduction of App Auto Patch 3.0
