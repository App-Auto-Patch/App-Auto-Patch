# App Auto-Patch Activator

## Huge thanks to @TechTrekkie for this workflow!!

This script is meant to work in tandem with the App-Auto-Patch-via-Dialog.zsh script and is meant to trigger AAP under the right conditions. 

**Note** AAP Activator requires use of the App Auto-Patch version 2.0.0 or later. 

## Configuration Variables
This script writes two variables to a configuration file:
* AAPWeeklyPatching (True | False) - Used to determine if the patching process has been completed for the week. A value of False means the Activator will trigger AAP to run, a value of True means it will be skipped
* AAPWeeklyPatchingStatusDate (datetime) - This gets popualted with the date/time the Activator script first executes and is used to calculate how many days have passed since that weekly patching period has started. Once 7 days have passed, the AAPWeeklyPatching status is reset back to False to restart the weekly patching cadence
# Process & Usage
## Configuration
The APP-Activator utilizes the existing AppAutoPatchDeferrals.plist configuration file created in the App-Auto-Patch script and works regardless if the deferral workflow is being utilized or not

Two values are set in the config file:

AAPWeeklyPatching (True | False) - This is set to False by default which signals AAP-Activator to trigger the App-Auto-Patch script
AAPWeeklyPatchingStatusDate (datetime) - This gets set with the date/time that AAP-Activator first runs and is used to calculate how many days have passed for a weekly patching cadence

## Setup
1. Set your App-Auto-Patch Jamf Policy to a frequency of “ongoing” and set a custom trigger (ex: AppAutoPatch)

2. Import the AAP-Activator Script to your Jamf Pro instance and modify the code on lines 89 and 98 to use the trigger from Step #1

3. Create a Jamf Pro policy that uses the AAP-Activator Script
   * Set the Trigger to Recurring Check-In
   * Set the execution frequency to Once Every Day
