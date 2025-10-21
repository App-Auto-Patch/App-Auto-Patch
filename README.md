<!-- markdownlint-disable-next-line first-line-heading no-inline-html -->
[<img align="left" alt="App Auto Patch" src="Images/AAPLogo.png" width="128" />](https://techitout.xyz/app-auto-patch)

# App Auto-Patch 3.4.2

![GitHub release (latest by date)](https://img.shields.io/github/v/release/App-Auto-Patch/App-Auto-Patch?display_name=tag) ![GitHub issues](https://img.shields.io/github/issues-raw/App-Auto-Patch/App-Auto-Patch) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/App-Auto-Patch/App-Auto-Patch) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/App-Auto-Patch/App-Auto-Patch) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/App-Auto-Patch/App-Auto-Patch)

## Introduction
App Auto-Patch combines local application discovery, an Installomator integration, and user-friendly swiftDialog prompts to automate application patch management across Mac computers.

[<img alt="App Auto Patch" src="https://github.com/App-Auto-Patch/App-Auto-Patch/blob/6a7ace89d2f4fc6641b1829f04950bbf3401b6f1/Images/AAP-Demo.gif" />](https://techitout.xyz/app-auto-patch)


## Why Build This

App Auto-Patch simplifies the process of taking an inventory of installed applications and patching them, eliminating the need for creating multiple Smart Groups, Policies, Patch Management Titles, etc., within Jamf Pro. It provides an easy solution for keeping end-users' applications updated with minimal effort.

This project has since been applied to MDMs outside of Jamf Pro, showcasing its versatility and adaptability. 

## New features/Specific Changes in 3.4.2
- Fixed order of `get_installomator` and `get_preferences`
- Complete re-write of logic to populate app names, icons, status and statustext in the various dialogs: Fixes missing icons, inconsistent app names, status and statustext updates
- Flipped buttons on deferral dialog so that Defer is the primary button, preventing accidental installs. Renamed `Continue` to `Install Now`

## New features/Specific Changes in 3.4.0
- Added App Auto-Patch Script Self Update functionality (Feature Request #128)
	- Managed Config: Configure using the SelfUpdateEnabled | SelfUpdateFrequency keys
 - CLI: Configure using the --self-update-enabled | --self-update-disabled | --self-update-frequency triggers. Force update using --force-self-update-check trigger
- Monthly Patching Cadence Functionality: Added the ability to set a Monthly Patching Cadence (e.g., Patch Tuesday).
	- MonthlyPatchingCadenceEnabled (TRUE|FALSE)
	- MonthlyPatchingCadenceOrdinalValue: Week of the month you want AAP to be scheduled (first|second|third|fourth|fifth|final)
	- MonthlyPatchingCadenceWeekdayIndex: Day of the week you want AAP to be scheduled (sunday|monday|tuesday|wednesday|thursday|friday|saturday)
	- MonthlyPatchingCadenceStartTime: Local time you want AAP to be scheduled (ex: `09:00:00`)
- Standardize timestamp format and use actual timezones instead of hard-coded UTC. Cleaned up and adjusted NextAutoLaunch format to use date datatype (#152)
- Added check for appName in Installomator label to populate the correct app name to improve app detection (Issue #155)
- Updated logic to populate app icons correctly for apps not located in /Applications folder
- Added logic to check for appCustomVersion in Installomator label to pull the correct version of installed apps
- Fixed logic to clear the targetDir variable when scrubbing Installomator label fragments
- Fixed case on variables (Issue #178)
- Added logic to ignore PWA apps from Chrome & Edge (Issue #178)
- Added --reset-labels trigger functionality (Issue #171)
- Fixed error extraction from Installomator logs. Used in webhooks. The previous implementation returned null. (PR #174)
- Fixed Jamf Self Service Icon Overlay & added support for Jamf Self Service+ (PR #173)
- Added option to set the Dialog Icon to a custom filepath or URL via MDM or CLI (#179)
- New `restart_aap` function to handle all LaunchDaemon restart logic
- Fixed a bug that would result in a `Print: Entry, ":userInterface:dialogElements", Does Not Exist` message if no language entries exist in the PLIST
- Logging improvements

## New features/Specific Changes in 3.3
- Added receipt support for patching events. Each app patched by App Auto Patch now writes a JSON receipt into the AAP management folder `/Library/Management/AppAutoPatch/receipts`. Successful and failed patch attempts are recorded. 
- New `AAP-LatestPatches` Jamf Pro EA makes reporting on app patching easy. The script will report the successful and failed patch attempts along with a timestamp, version, Installomator exit code, and status.

## New features/Specific Changes in 3.2
 - Added [multi-language support](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/User-Interface-%7C-Multi%E2%80%90Language-Support): Entries can be added to the managed configuration profile for multiple languages, based on the setting for the user in macOS
 - Added [--workflow-install-now-silent](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Workflows#workflow-install-now-silent-version-32) option which runs through the workflow without deferrals but does not display dialogs
 - Added option to [disable Installomator Updates](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Installomator-Integration#installomator-update-disable) using <key>InstallomatorUpdateDisable</key> <string>TRUE,FALSE</string>
 - Added dialogTargetVersion and set to version 2.5.5 as minimum required due to issues with the deferral menu on older versions

## Getting Started with 3.3

App Auto-Patch 3.3 automatically installs itself and necessary components anytime it's ran from outside the working folder `/Library/Management/AppAutoPatch/`
For more information on getting started and testing, please visit the [AAP 3.3.0 Wiki](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki) page for more information

- After installed, you can simply run `sudo appautopatch` from terminal with any parameters to configure as you'd like. Examples:

`sudo appautopatch --interactiveMode=2 --workflow-install-now --deadline-count-focus=2 --deadline-count-hard=4 --ignored-labels="microsoft* googlechrome* jamfconnect zoom* 1password* firefox* swiftdialog" --verbose-mode`

Or trigger from the script directly to perform an install with parameters as you'd like. Example:

`./App-Auto-Patch-via-Dialog.zsh --interactiveMode=2 --workflow-install-now --deadline-count-focus=2 --deadline-count-hard=4 --ignored-labels="microsoft* googlechrome* jamfconnect zoom* 1password* firefox* swiftdialog" --verbose-mode`

 - You can find a mapping of 2.x variables to 3.3.0 configuration and command line options from the following TSV file: [Migration Options](https://github.com/App-Auto-Patch/App-Auto-Patch/blob/3.0/Resources/App-Auto-Patch%203.0.0-Migration-Options.tsv)
 - Profile Manifests to assist with building a configuration profile can be found in the Resources folder: [Profile Manifests](https://github.com/App-Auto-Patch/App-Auto-Patch/tree/main/Resources/Manifests)
 - An example configuration profile and a profile & plist containing all available options can be found in the resources: [Example Configurations](https://github.com/App-Auto-Patch/App-Auto-Patch/tree/main/Resources)

- To reset AAP to defaults:
  `./App-Auto-Patch-via-Dialog.zsh --reset-defaults`

- Clear Ignored, Required, and Optional Labels:
  `./App-Auto-Patch-via-Dialog.zsh --reset-labels`

- Uninstall App Auto Patch:
  `./App-Auto-Patch-via-Dialog.zsh --uninstall`

## Learn More 

Please review the wiki: [App Auto-Patch Wiki](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki)

- [Getting Started](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Getting-Started)

- [Deferral Behavior](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Deferral-Behavior)

- [Configuration Settings](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Configure-Settings)


***

You can also join the conversation at the [Mac Admins Foundation Slack](https://www.macadmins.org) in channel [#app-auto-patch](https://macadmins.slack.com/archives/C05D69E7SBH).

## Thank you
To everyone who has helped contribute to App Auto-Patch, including but not limited to:

- Robert Schroeder ([@robjschroeder](https://github.com/robjschroeder))
- Andrew Spokes ([@TechTrekkie](https://github.com/TechTrekkie))
- Dan Snelson ([@dan-snelson](https://github.com/dan-snelson))
- Andrew Clark ([@drtaru](https://github.com/drtaru))
- Andrew Barnett ([@andrewmbarnett](https://github.com/AndrewMBarnett))
- Trevor Sysock ([@bigmacadmin](https://github.com/bigmacadmin))
- Bart Reardon ([@bartreardon](https://github.com/bartreardon))
- Charles Mangin ([@option8](https://github.com/option8))
- Gil Burns ([@gilburns](https://github.com/gilburns))
### And special thanks to the Installomator Team
- Armin Briegel ([@scriptingosx](https://github.com/scriptingosx))
- Isaac Ordonez ([@issacatmann](https://github.com/issacatmann))
- Søren Theilgaard ([@Theile](https://github.com/Theile))
- Adam Codega ([@acodega](https://github.com/acodega))
