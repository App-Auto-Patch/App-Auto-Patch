# CHANGELOG

# Version 2

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
