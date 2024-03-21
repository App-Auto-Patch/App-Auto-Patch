# CHANGELOG

# Version 2

## Version 2.10.0
### 20-Mar-2024
- Merged AAP Activator functionality into main AAP Script. Activator (Deferral Workflow) will execute if `maxDeferrals` is set to an integer. Setting to `Disabled` will execute "On-Demand" workflow
- Added Activator/Deferral Workflow variables:
    - `daysUntilReset` = The number of days until the Activator/Deferral Workflow resets the patching status to false (ex: 7 days resets weekly)
    - `patchWeekStartDay` = Day of the week to set the start date for weekly patching/daysUntilReset count (1=Mon 2=Tue...7=Sun), leave blank to disable
    - `maxDisplayAssertionCount` = The maximum number of deferred attempts from Display Assertions (integer, leave blank to disable)
- New Variable = `selfServicePatchingStatusModeReset` - Determines if the weekly patching status should be set to True when running in "On-Demand/Self Service" mode (when deferrals are disabled) [1=Never, 2=Always, 3=On Success (no errors)]
- New Variable = `ignoreDNDApps` - Comma-separated list of app names to ignore when evaluating DND/Display Assertions (ex: ignoreDNDApps="firefox,Google Chrome,caffeinate")
- Consolidated AppAutoPatchDeferrals config file into AppAutoPatchStatus config file - The logic for any Extension Attributes pulling from AppAutoPatchDeferrals.plist have been updated
- Moved Caffeinate function to run after Activator/Deferral Workflow so as not to be included as a false positive display assertion

## Version 2.9.7
### 19-Mar-2024
- Added a new options flag, `useLatestAvailableInstallomatorScriptVersion`. If set to true, AAP will validate the VERSIONDATE from the latest Installomator script and will replace if they don't match. If `false` only Release version of Installomator will be used for comparision.

## Version 2.9.6
### 15-Mar-2024
- Added `--no-rcs` to shebang of script. This addresses CVE-2024-27301. https://nvd.nist.gov/vuln/detail/CVE-2024-27301/change-record?changeRecordedOn=03/14/2024T15:15:50.680-0400

## Version 2.9.5
### 07-Mar-2024
- Added logic to display AAP Logo for the App Icon if the app does not exist (thanks @TechTrekkie)

## Version 2.9.4
### 07-Mar-20204
- Added functionality for icons to show up in the deferral window and installing/updating window before they are processing (thanks @AndrewMBarnett)

## Version 2.9.3
### 17-Feb-2024
- Added case for on-prem, multi-node, or clustered environments (thanks @dan-snelson)
- Webhook logic now uses case statement for evaluation (thanks @dan-snelson)
- Improved webhook messaging (thanks @dan-snelson)
- Improved infobox informaiton for patching dialog (thanks @dan-snelson)

## Version 2.9.2
### 15-Feb-2024
- Fixed an issue that would cause a blank list to appear in the patching dialog if `runDiscovery` was set to `false`, a placeholder will be used for now
- ** This issue was introduced in version 2.9.1 ** Issue #59

## Version 2.9.1
### 14-Feb-2024
- Fixed issue where compact list style was being used during update progress and increased font size
- Analyzing Apps window now shows app logos during discovery (thanks @dan-snelson)
- Removed all notes from script history previous to version 2.0.0, see changelog to reference any prior changes. 
- Updated jamfProComputerURL variable to a search by serial vs. running a recon to get JSS ID, an extra click but saves a recon (thanks @dan-snelson)
- Removed minimize windowbutton from the deferral dialog to avoid confusion from users mistakenly hiding the dialog (Thanks @TechTrekkie)
- Updated webhook JSON to utilize appTitle variable vs. direct App Auto-Patch name (thanks @Tech-Trekkie)

## Version 2.9.0
### 08-Feb-2024
- Updated minimum swiftDialog minimum to 2.4.0 (thanks @AndrewMBarnett)
- Added Teams and Slack webhook messaging functionality (thanks @AndrewMBarnett and @TechTrekkie)
- Function for finding Jamf Pro URL for computer running AAP (thanks @AndrewMBarnett and @TechTrekkie)
- Added minimize windowbutton to let windows run and minimize to applicable dialogs
- Added script version number to help message (thanks @dan-snelson)

## 2.8.1
### 25-Jan-2024
- Fixed the --moveable flags spelling so the dialog will be set to moveable properly

## 2.0.8
### 24-Jan-2024
- Fixed the case for the `helpMessage` variable for the deferral window so the `helpmessage` displays properly
- Added application list to deferral window when 0 deferrals remain to mirror the behavior when deferrals are greater than 0
- Updated infobox text to indicate "Updates will automatically install after the timer expires" when 0 deferrals remain

## 2.0.7
### 23-Jan-2024
- Added function to list application names needing to update to show users before updates are installed during the deferral window (thanks @AndrewMBarnett)
- Added text to explain the deferral timer during the deferall window
- Text displayed during the deferral period and no deferrals remaining changes depending on how many deferrals are left.
- Deferral window infobox text is now dynamic based on `deferralTimerAction`
- Adjusted size of deferral window based on deferrals remaining (thanks @TechTrekkie)

## 2.0.6
### 22-Jan-2024
- New feature, `convertAppsInHomeFolder`. If this variable is set to `true` and an app is found within the /Users/* directory, the app will be queued for installation into the default path and removed into from the /Users/* directory
- New feature, `ignoreAppsInHomeFolder`. If this variable is set to `true` apps found within the /Users/* directory will be ignored. If `false` an app discovered with an update will be queued and installed into the default directory. This may may lead to two version of the same app installed. (thanks @gilburns!) 

## 2.0.5
### 5-Jan-2024
If `interactiveMode` is greater than 1 (set for Full Interactive), and AAP does not detect any app updates a dialog will be presented to the user letting them know.

## 2.0.4
### 3-Jan-2024
- Adjusted references of 'There is no newer version available' to 'same as installed' to fix debug check behavior for DMG/ZIP Installomator labels (thanks @TechTrekkie) 

## 2.0.3
### 2-Jan-2024
- App Auto-Patch will do an additional check with a debug version of Installomator to determine if an application that is installed needs an update

## 2.0.2
### 2-Jan-2024
- **Breaking Change** for users of App Auto-Patch before `2.0.2`
       - Check Jamf Pro Script Parameters before deploying version 2.0.1, we have re-organized them
- Replaced logic of checking app version for discovered apps
- Reduced output to logs outside of debug modes (thanks @dan-snelson)

## 2.0.1
### 20-Dec-2023
- **Breaking Change** for users of App Auto-Patch before `2.0.1`
  - Removed the scriptLog variable out of Jamf Pro Script parameters, this is now under the ### Script Log and General Behavior Options ###
  - Removed the debugMode variable out of Jamf Pro Script parameters, this is now under the ### Script Log and General Behavior Options ###
  - Removed the outdatedOSAction variable out of the Jamf Pro Script parameters, this is now under the ### Script Log and General Behavior Options ###
  - Removed the useOverlayIcon variable out of the Jamf Pro Script parameters, this is now under ### Overlay Icon ### in the Custom Branding, Overlay Icon, etc section
- Fixed issue with labels (#13), improving how regex handles app labels from Installomator
- Updated AAP Activator Flag to pull from config plist and automatically determine if being executed by AAP-Activator (thanks @TechTrekkie)
- Updated deferral reset logic to only update if maxDeferrals is not Disabled. Reset deferrals if remaining is higher than max (thanks @TechTrekkie)
- Updated deferral workflow to run removeInstallomator and quitScript triggers to mirror non-deferral workflow (thanks @TechTrekkie)
- Created installomatorOptions Parameter, which can be used to overwrite default installomator options
- Fixed Installomator appNewVersion curl URL
- Changed `removeInstallomator` default to false, this will keep AAP's Installomator folder present until Installomator has an update

## 2.0.0
### 19-Dec-2023
- **Breaking Change** for users of App Auto-Patch prior to `2.0.0`
  - Removed the unattendExit variable out of Jamf Pro Script parameters, this is now under the ### Unattended Exit Options ###
- Moved the outdatedOsAction variable from Parameter 9 to Parameter 10 in Jamf Pro Script parameters
- Script cleanup and organization
- dialogInstall function called only if interactiveMode is greater than 0
- Added logic for AAP-Activator (thanks @TechTrekkie)
- Variable added for AAP-Activator logic under ### Deferral Options ###, please see documentation for more information
- Added optionalLabels array. Installomator labels listed in this array will first check to see if the app is installed. If the app is installed, it will write the label to the required array. If the app is not installed, it will get skipped.

## 2.0.0rc2
### 13-Dec-2023
- Adjusting script version, preparing for version 2.0 release

## 2.0.0rc1-B
### 29-Nov-2023
- Changed deferral plist to use the aapPath folder to facilitate creating an EA to populate remaining deferrals in Jamf (thanks, @techtrekkie!)
- Added deferralTimerAction to indicate whether the default action when the timer expires is to Defer or continue with installs (thanks, @techtrekkie!)
- Moved deferral reset to after installation step to confirm the user completed the process without skipping it (force shutdown/reboot) (thanks, @techtrekkie!)

## 2.0.0rc1-A
### 27-Nov-2023
- Added the ability to allow user to defer installing updates using the 'maxDeferrals' variable. A value of 'disabled' will not display the deferral prompt (thanks, @techtrekkie!)

## 2.0.0rc1
### 07-Nov-2023
- Adjusting all references of `MacAdmins Slack)` to `MacAdmins Slack )` in an effor to fix the Slack label coming up as `Asana` (thanks @TechTrekkie)

## 2.0.0b12
### 30-Oct-2023
- Cleaned up some additional GUI items (thanks @dan-snelson)
- Team website shown in help message is now a hyperlink (thanks @dan-snelson)
- Changing progress bar to continous bouncing bar until we can accurately control the progress incrementation (if you'd like to re-enable, uncomment lines 1299 & 1308 ( swiftDialogUpdate "progress: increment ... )
- Number of updates should now show in the infobox

## 2.0.0b11
### 28-Oct-2023
- Progress bar sets to 0 when updates begin
- Added option to set title shown to end-user customizable (thanks @wakco)
- Added option to keep Installomator if desired (thanks @wakco)
- By default, swiftDialog is now ignored since the PreFlight will install as a pre-requisite (thanks @wakco)
- Added Verbose Mode (Adds additional logging)
- Added Deubg mode (Turns Installomator to DEBUG 2, does not install or remove applications)

## 2.0.0b10
### 25-Oct-2023
- Fixed osBuild variable
- Added countOfElementsArray variable, this should accurately notify of the number of updates that AAP will attempt regardless of `runDiscovery` being true or false (Issue #4, thanks @beatlemike)

## 2.0.0b9
### 24-Oct-2023
- Worked on issue with number of updates not being correct
- Fixed #15, Progress Bar Early Incrementation (thanks @dan-snelson)
- Added warnings into logs that labels will not get replaced if there are multiple labels for the same app (i.e. zoom, zoomclient, zoomgov), please make sure you are targeting the appropriate labels for your org
- Removed duplicate variables

## 2.0.0b8
### 24-Oct-2023
- Removed the extra checks for versioning, this became more of a hinderance and caused issues. Better to queue the label and not need it than to not queue an app that needs an update. Addresses issue #20 (thanks @Apfelpom)
- If a wildcard is used for `IgnoredLabels` you can override an individual label by placing it in the required labels. 
- Addressed issue where wildcards wrote additional plist entry 'Application'
- Merged PR #21, Added a help message with variables for the update window. (thanks, @AndrewMBarnett)
- Issue #13, `Discovering firefoxpkg_intl but installing firefoxpkgintl`, fixed.

## 2.0.0b7
### 23-Oct-2023
- Fixed some logic during discovery that prevented some apps from being queued. (Issue #14, thanks @Apfelpom)
- Added more checks when determining available version vs installed version. Some Installomator app labels do not report an accurate appNewVersion variable, those will be found in the logs as "[WARNING] --- Latest version could not be determined from Installomator app label". These apps will be queued regardless of having a properly updated app. [Line No. ~851-870]
- With the added checks for versioning, if an app with a higher version is installed vs available version from Installomator, the app will not be queued. (thanks, @dan-snelson)

## 2.0.0b6
### 23-Oct-2023
- Added a function to create the App Auto-Patch directory, if it doesn't already exist. ( /Library/Application Support/AppAutoPatch )

## 2.0.0b5
### 20-Oct-2023
- AAP now uses it own directory in `/Library/Application Support` to store Installomator. This directory gets removed after processing (thanks for the suggestion @dan-snelson!)
- Had to update some of the hardcoded Installomator paths. 

## 2.0.0b4
### 20-Oct-2023
- Changed versioning schema from `0.0-beta0` to `0.0.0b0` (thanks, @dan-snelson)
- Modified --infotext box, removed $scriptFunctionalName and `Version:` (thanks, @dan-snelson)
- Removed app version number from discovery dialog (to be added later as a verboseMode)
- Various typo fixes

## 2.0-beta3
### 19-Oct-2023
- Added plist created in /Library/Application Support/AppAutoPatch, this additional plist can be used to pull data from or build extension attributes for Jamf Pro

## 2.0-beta2
### 18-Oct-2023
- Reworked workflow
- Added an unattended exit of Dialog parameter. If set to `true` and `unattendedExitSeconds` is defined, the Dialog process will be killed after the duration. 
- Added ability to add wildcards to ignoredLabels and requiredLabels (thanks, @jako)
- Added a swiftDialogMinimumRequiredVersion variable
- Updated minimum required OS for swiftDialog installation
- Updated logging functions

# Version 1

## 1.0.14
### 16-Oct-2023
- Made file path changes
- App Auto Patch version checking is now more accurate than before, if an app has an update available, it will be written to the plist at /Library/Application Support/AppAutoPatch/
- Some `Latest Versions` of apps cannot be identified during discovery. These apps will be added to the plist and will be caught when Installomator goes to install the update. These will show that the latest version is already installed. 

## 1.0.13
### 16-Sept-2023
- Fixed repo URL for swiftdialog

## 1.0.12
### 29-June-2023
- Added variables for computer name and macOS version (Issue #6, thanks @AndrewMBarnett)
- Added computer variables to infobox of dialog

## 1.0.11
### 21-June-2023
- Added more options for running silently (Issue #3, thanks @beatlemike)
- Commented out the update count in List dialog infobox until accurate count can be used

## 1.0.10
### 23-May-2023
- Moved the creation of the overlay icon in the IF statement if `userOverlayIcon` is set to true

## 1.0.9
### 18-May-2023
- Removed debugMode (was not being utilized throughout script)
- Changed `useswiftdialog` variable to `interactiveMode`
- Added variable `useOverlayIcon`
- Moved scriptVersion to infotext on swiftDialog windows
- Changed icon used for desktop computers to match platform (would like to grab model name and match accordingly: MacBook, Mac, Mac Mini, etc.)
- Changed `discovery` variable to `runDiscovery`
- Changed repository to App-Auto-Patch and script name to App-Auto-Patch-via-Dialog.zsh

## 1.0.8
### 17-May-2023
- Changed extension to `.zsh` (to quiet Shellcheck) (thanks, @dan-snelson!)
- More dialog tweaks (thanks, @dan-snelson!)

## Initial Commit
### 16-May-2023
- Initial Commit/Repo creation

## 1.0.7
### 16-May-2023
- Additional cleanup

## 1.0.6
### 16-May-2023
- Reduced size of main dialog (thanks, @dan-snelson!)

## 1.0.5
### 15-May-2023
- Trying to rewrite script for better readability
- Adding direct support to deploy within Jamf Pro
