# CHANGELOG

# Version 3

## Version 3.2.2
### 20-May-2025
- Fixed logic for resetting PatchStartDate to use new date for deferrals instead of date prior to the reset

## Version 3.2.1
### 01-May-2025
- Added logic to kill Dialog process if a previous PID is found

## Version 3.2.0
### 29-Apr-2025
- Added multi-language support: Entries can be added to the managed configuration profile for multiple languages, based on the setting for the user in macOS
- Added --workflow-install-now-silent option which runs through the workflow without deferrals but does not display dialogs
- Added option to disable Installomator Updates using <key>InstallomatorUpdateDisable</key> <string>TRUE,FALSE</string>
- Added dialogTargetVersion and set to version 2.5.5 as minimum required due to issues with the deferral menu on older versions

## Version 3.1.2
### 11-Apr-2025
- Fixed a bug that prevented the proper app name from populating for a small number of labels (Issue #140)
- Fixed a bug when using wildcards for ignored and required labels that could cause the label to skip being added (Issue #141)
- Fixed a bug that could prevent a label from being added if that label name matched part of a label in the ignoredLabelsArray (Issue #142)
- Fixed a bug to pull the correct label name for cases where the label fragments file contains multiple label references (ex: Camtasia|Camtasia2025) (Issue #143)
- Fixed a bug that prevented the proper app name and icon from populating for a small number of labels on the Patching Dialog (Issue #144)
- Fixed a bug that prevented Installomator from sending the proper status updates to the swiftDialogCommandFile (Issue #144)
- Updated syntax for some verbose logging
- Added dialog to the ignored label list to prevent dialog from updating during runtime

## Version 3.1.1
### 09-Apr-2025
- Updated logic to decrease time for re-launch when parent_process_is_jamf=TRUE. LaunchDaemon will now relaunch in 5 seconds

## Version 3.1.0
### 02-Apr-2025
- Added functionality for Days Deadlines, configurable by DeadlineDaysFocus and DeadlineDaysHard
- Added MDM keys and triggers for WorkflowInstallNowPatchingStatusAction
- Moved the Defer button next to the Continue button to position it underneath the deferral menu drop-down
- Adjusted logic to use deferral_timer_workflow_relaunch_minutes after AAP completes the installation workflow
- Fixed logic for workflow_disable_relaunch_option to disable relaunch after successful patching completion if set to TRUE
- Added exit_error function to handle startup validation errors
- Added the ability to pull from a custom Installomator fork. It must include all Installomator contents, including fragments
- Added logic to check for a successful App Auto Patch installation.
- Fixed logic for InteractiveMode to use default if no option is set via MDM or command line
- Fixed logic for DaysUntilReset to use default if no option is set via mdm or command line
- Fixed logic where script was improperly shifting CLI options when running from Jamf and not using built-in parameter options (Issues #45)
- Updated Microsoft Teams Webhook per [Create incoming webhooks with Workflows for Microsoft Teams](https://support.microsoft.com/en-us/office/create-incoming-webhooks-with-workflows-for-microsoft-teams-8ae491c7-0394-4861-ba59-055e33f75498)
- Fixed issues with dialog logic for Install Now Workflow

## Version 3.0.4
### 14-Mar-2025
- Fixed logic so that InteractiveMode=0 will not run the deferral workflow or display a deferral dialog
- Updated workflow_disable_relaunch logic to not relaunch AAP if set to true and AAP is installing or Jamf is the parent process
- Fixed an issue that was causing Optional labels to be duplicated when added to the Required queue if the app is installed
- Fixed various formatting throughout the script

## Version 3.0.3
### 13-Mar-2025
- Fixed progress bar incrementation to increment in steps vs. bouncing

## Version 3.0.2
### 11-Mar-2025
- Added AAPLastRunDate and AAPLastSilentRunDate
- Fixed logic for UnattendedExit

## Version 3.0.1
### 10-Mar-2025
- Fixed a bug where --workflow-install-now would be ignored if AAPPatchingCompletionStatus=TRUE
- Fixed a bug where --workflow-install-now would not complete cleanly and trigger an immediate re-run of AAP
- Added logic for Jumpcloud MDM and updated Webhook logic for the Jumpcloud MDM URL (Thanks @mattbilson)

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
