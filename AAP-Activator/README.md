# App Auto-Patch Activator

## Huge thanks to @TechTrekkie for this workflow!!

This script is meant to work in tandem with the App-Auto-Patch-via-Dialog.zsh script and is meant to trigger AAP under the right conditions. 

**Note** AAP Activator requires use of the App Auto-Patch version 2.0.0 or later. 

## Configuration Variables
This script writes two variables to a configuration file:
* AAPWeeklyPatching (True | False) - Used to determine if the patching process has been completed for the week. A value of False means the Activator will trigger AAP to run, a value of True means it will be skipped
* AAPWeeklyPatchingStatusDate (datetime) - This gets popualted with the date/time the Activator script first executes and is used to calculate how many days have passed since that weekly patching period has started. Once 7 days have passed, the AAPWeeklyPatching status is reset back to False to restart the weekly patching cadence
* AAPActivatorFlag - This will get picked up by the App Auto-Patch script to automatically determine if being trigger by AAP-Activator or not
# Process & Usage
## Configuration
The APP-Activator utilizes the existing AppAutoPatchDeferrals.plist configuration file created in the App-Auto-Patch script and works regardless if the deferral workflow is being utilized or not

Two values are set in the config file:

AAPWeeklyPatching (True | False) - This is set to False by default which signals AAP-Activator to trigger the App-Auto-Patch script
AAPWeeklyPatchingStatusDate (datetime) - This gets set with the date/time that AAP-Activator first runs and is used to calculate how many days have passed for a weekly patching cadence
AAPActivatorFlag )True | False) 

## Setup
1. Set your App Auto-Patch Jamf Policy to a frequency of “ongoing” and set a custom trigger (ex: AppAutoPatch)

2. Import the AAP-Activator Script to your Jamf Pro instance and set the Jamf Pro Script parameter names to match Parameter #4 and #5 from the script (#4: Log Location, #5 AAP Jamf Policy Trigger)

3. Create a Jamf Pro policy that uses the AAP-Activator Script
   * Set the Trigger to Recurring Check-In
   * Set the execution frequency to Once Every Day
   * Populate Parameter #4 with your log location
   * Populate Parameter #5 with the App Auto-Patch policy trigger from step #1
   * Populate Parameter #6 with The number of days until the activator resets the patching status to False (for a weekly reset, set to 7)
