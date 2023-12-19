# App Auto-Patch Activator

This script is meant to work in tandem with the App-Auto-Patch-via-Dialog.zsh script and is meant to trigger AAP under the right conditions. 

**Note** AAP Activator requires use of the modified App-Auto-Patch-via-Dialog.zsh script. Until those changes are merged into the main repo under @robjschroeder, you can use this version here: https://github.com/TechTrekkie/App-Auto-Patch/blob/f90e05d07aa3570807388cde258890024e4a8fc8/App-Auto-Patch-via-Dialog.zsh

## Configuration Variables
This script writes two variables to a configuration file:
* AAPWeeklyPatching (True | False) - Used to determine if the patching process has been completed for the week. A value of False means the Activator will trigger AAP to run, a value of True means it will be skipped
* AAPWeeklyPatchingStatusDate (datetime) - This gets popualted with the date/time the Activator script first executes and is used to calculate how many days have passed since that weekly patching period has started. Once 7 days have passed, the AAPWeeklyPatching status is reset back to False to restart the weekly patching cadence
# Process & Usage
## Configuration
The APP-Activator utilizes the existing AppAutoPatchDeferrals.plist configuration file created in the App-Auto-Patch script and works regardless if the deferral workflow is being utilized or not

**Note**: You will need to add some modified code to the App-Auto-Patch-via-Dialog.zsh script in order for AAP-Activator to work. I have a modified version in this repo that you can copy the changes from between lines 1469 and 1479
This modified code will set the AAPWeeklyPatching value to True either when patching has been completed successfully, or if no apps are available to patch

Two values are set in the config file:

AAPWeeklyPatching (True | False) - This is set to False by default which signals AAP-Activator to trigger the App-Auto-Patch script
AAPWeeklyPatchingStatusDate (datetime) - This gets set with the date/time that AAP-Activator first runs and is used to calculate how many days have passed for a weekly patching cadence

## Setup
1. Set your App-Auto-Patch Jamf Policy to a frequency of “ongoing” and set a custom trigger (ex: AppAutoPatch)
   * Note: You must be using the modified App-Auto-Patch-via-Dialog.zsh script mentioned above.  

2. Import the AAP-Activator Script to your Jamf Pro instance and modify the code on lines 89 and 98 to use the trigger from Step #1

3. Create a Jamf Pro policy that uses the AAP-Activator Script
   * Set the Trigger to Recurring Check-In
   * Set the execution frequency to Once Every Day
