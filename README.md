<!-- markdownlint-disable-next-line first-line-heading no-inline-html -->
[<img align="left" alt="App Auto Patch" src="Images/AAPLogo.png" width="128" />](https://techitout.xyz/app-auto-patch)

# App Auto-Patch 3.6.0

![GitHub release (latest by date)](https://img.shields.io/github/v/release/App-Auto-Patch/App-Auto-Patch?display_name=tag) ![GitHub issues](https://img.shields.io/github/issues-raw/App-Auto-Patch/App-Auto-Patch) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/App-Auto-Patch/App-Auto-Patch) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/App-Auto-Patch/App-Auto-Patch) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/App-Auto-Patch/App-Auto-Patch)

## Introduction
App Auto-Patch is a MDM-agnostic Third Party Patching tool that combines local application discovery, an Installomator integration, and user-friendly swiftDialog prompts to automate application patch management across Mac computers.

<img alt="Dialog Example" src="https://github.com/App-Auto-Patch/App-Auto-Patch/blob/176f0c284d7b2312375a3a11ae8a8e4f2159ecdf/Images/Combined%20Dialogs.png" />

## Why Build This

App Auto-Patch simplifies the process of inventorying installed applications and patching them, for any MDM. For those using Jamf Pro, this helps eliminate the need to create multiple Smart Groups, Policies, Patch Management Titles, etc., within Jamf Pro. It provides an easy way to keep end users' applications updated with minimal effort.

## New features/Specific Changes in 3.6.0
**⚠️ Before you upgrade:** Background Patch Closed Apps (below) is **enabled by default** and applies under both `InteractiveMode 1` and `InteractiveMode 2`. If you are not ready for AAP to silently patch closed apps, set `WorkflowBackgroundPatchClosedApps` to `false` in your managed configuration before deploying this version. There are no other breaking changes in this release, and no CLI triggers were added.

**New Features**

- **Background Patch Closed Apps** — Under `InteractiveMode 1` or `2`, AAP now silently installs updates for any app that isn't currently open, immediately after discovery and before any dialog is shown to the user. Apps that are open are left in the queue and presented to the user as before, so they can choose when to close them. If every pending update is resolved silently, no dialog appears at all. (`InteractiveMode 0` is unaffected — it already installs everything silently regardless of whether an app is open.)
	- Managed Preference Key: `<key>WorkflowBackgroundPatchClosedApps</key>` `<true/>` | `<false/>` — **default: `true`**

- **Update Staging** — Pending updates can now be pre-downloaded to a local staging folder before the user is ever prompted, making the actual install nearly instantaneous once approved. Staging always runs first (ahead of Background Patch Closed Apps and the user dialog), and later steps reuse the staged installer instead of downloading it a second time. Outdated or stale staged files are cleaned up automatically.
	- Managed Preference Key: `<key>WorkflowStageUpdates</key>` `<true/>` | `<false/>` — default: `false`

- **Discovery Frequency** — Skip the app-discovery (scanning) phase on subsequent runs within a configurable time window. Useful when a user defers multiple times in a day — AAP won't re-scan every app each time, saving runtime, bandwidth, and system resources.
	- Managed Preference Key: `<key>DiscoveryFrequency</key>` `<integer>hours</integer>` — default: `0` (always run discovery)

- **Force Discovery CLI trigger** — A new `--force-discovery` CLI trigger runs the app-discovery (scanning) phase immediately, even if `DiscoveryFrequency` hasn't elapsed yet. It's a one-shot trigger: it applies to the very next run only, then automatically clears itself — including when the run is relaunched via the LaunchDaemon (e.g. triggered remotely through Jamf), so it still takes effect even though the relaunched process doesn't see the original command-line flag.
	- CLI Trigger: `--force-discovery`
	- Note: an administrator-disabled discovery workflow (`WorkflowDisableAppDiscovery`) still takes priority — `--force-discovery` only bypasses the `DiscoveryFrequency` wait, not a hard disable.

- **Ignore DND Apps** — Exclude specific apps from Focus/Do-Not-Disturb display-sleep-assertion detection, so background utilities that permanently hold a display assertion (e.g. Logi Options+, Amphetamine) don't indefinitely block interactive patching from proceeding. (#149)
	- Managed Preference Key: `<key>IgnoreDNDApps</key>` `<string>App1,App2,App3</string>` — comma-separated app names, matched exactly as reported by macOS (including spaces)

- **Update queue reporting** — A new report file (`xyz.techitout.appAutoPatchReport.plist`) tracks every currently-queued app (name, installed version, available version) in a Munki-style `ItemsToInstall` array, making it easy for third-party reporting or inventory tools to surface pending updates for a Mac.

- **Version details in patch dialogs** — The deferral and hard-deadline dialogs now show each app's current and new version underneath its name, e.g. "Current Version: 128.0.6613.138 → New Version: 129.0.6668.59", so users know exactly what's changing before they install.

- **Startup & download reliability improvements**
	- AAP now waits for the Dock to become active (up to 2 minutes) before proceeding at startup, ensuring a full user session is established first.
	- The swiftDialog download and code-signing verification now automatically retry up to 3 times before failing, reducing false failures on flaky networks.

- **Verbose log retention** — The verbose log is now archived (instead of being deleted every run) once it grows past a size threshold, matching the existing rotation behavior of the main log, with a capped number of archives to prevent unbounded disk usage.

- **Banner image support** — The Patching, Deferral, and Hard Deadline dialogs can now display a custom banner (image, URL, solid colour, or gradient) across the top in place of the plain text title, using swiftDialog's `--bannerimage`/`--bannertitle`/`--bannerheight` options. If no banner image is configured, dialogs look exactly as before.
	- Managed Preference Key: `<key>BannerImage</key>` `<string>Filepath|URL|colour=#hex|gradient=colour,colour</string>` — leave unset to keep the standard text title
	- Managed Preference Key: `<key>BannerTitle</key>` `<string>Text</string>` — text shown inside the banner; falls back to the app title if left blank
	- Managed Preference Key: `<key>BannerHeight</key>` `<integer>points</integer>` — optional, overrides swiftDialog's default banner height
	- Note: activating a banner image hides the standard dialog icon, per swiftDialog's own behavior
	- Not available on the compact discovery-scan and "all apps up to date" mini dialogs — they're too small to display a banner and always show the standard text title

- Apps found in `.Trash`, `/Applications (Parallels)/`, and `/Applications (Virtual Machines)/` are now automatically ignored during discovery.

- **Staging / background-patch progress dialog for Full Interactive mode** — Under `InteractiveMode 2`, a small progress window now stays visible while updates are staged and closed apps are silently patched, instead of leaving users looking at an empty screen between the discovery dialog closing and the deferral/hard-deadline dialog appearing.

- **"Install Now" confirmation prompt** — Clicking `Install Now` on the deferral dialog now shows a small confirmation prompt before proceeding, so users don't accidentally close their apps and trigger installs with a single click. The confirmation shows a small countdown (default 15 seconds) so users know how long they have to respond — the buttons are clickable immediately (no brief delay before they respond), and if the countdown runs out without a response, AAP proceeds with the install by default (the user already asked to install, so no response is treated as confirmation rather than a change of mind). Choosing "No" returns to the deferral dialog, and that dialog's own countdown timer picks up right where it left off (it does not reset). This confirmation only applies to the deferral dialog — the hard-deadline dialog is unaffected, since it offers no choice to begin with.
	- Managed Preference Key: `<key>DialogTimeoutConfirmInstall</key>` `<integer>seconds</integer>` — default: `15`

**Fixes**

- Fixed: the `RemoveInstallomatorPath` managed preference could be forced to `FALSE` even when explicitly set to `TRUE`
- Fixed: the Support Team Website field wasn't hidden when its managed value was set to `hide`
- Fixed: the Workspace One MDM URL wasn't populating correctly for Slack webhook notifications
- Fixed: Support Team Name values containing umlaut characters populated incorrectly
- Fixed: Installomator version/date now displays correctly in logs when the Installomator self-updater is disabled

## New features/Specific Changes in 3.5.0
- [New Version Comparison Method options](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Version-Comparison-Methods)
	- New `versionComparisonMethod` key with the options `IS_AT_LEAST` and `EQUAL_TO`
 	- `IS_AT_LEAST`: Checks if the currently installed version is the same or greater than the new version available. Utilizes the "Is-At-Least" function.
 	- `EQUAL_TO`: Checks if the currently installed version is equal to the new version available
- Optional Label logic updates
	- Optional Labels will now be checked for both Installed and Update Available
 	- **Breaking Change**: Optional labels will be checked during the discovery phase. If you use Optional labels and had previously disabled the discovery workflow, it must now be enabled for the labels to be checked
 	- You can use an asterisk `*` to ignore all labels, and any optional labels will be omitted from the ignore list to be checked if installed and update available
- [Option to disable Installomator Debug Fallback for version comparison](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Version-Comparison-Methods#version-comparison-installomator-fallback)
	- Key: `VersionComparisonInstallomatorFallback` `<true/>` | `<false/>`
 	- TRUE (Default): If AAP is unable to do a version comparison due to a missing `appNewVersion` in Installomator, it falls back to using Installomator Debug mode, which will usually indicate if there is a new version or not for an app. Setting this key to TRUE will keep this functionality enabled
  	- FALSE: Disables the Installomator Debug Fallback. If the `appNewVersion` is unavailable, AAP will ignore the app and not add it to the queue
- [Added Zoom Call Active Check option:](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Zoom-Call-Active-Check) When enabled, if a user starts the install process and then starts a Zoom call, App Auto-Patch will skip the Zoom update to prevent closing Zoom in the middle of the meeting
	- Default is set to Enabled
   	- Managed Preference Key: `<key>ZoomCallActiveCheck</key>` `<true/>` | `<false/>`
  	- CLI Options: `--zoom-call-active-check-enabled` `--zoom-call-active-check-disabled`
- Updated info dialog with more information and easier-to-read formatting (PR #184)
	- Bolded labels and SupportTeamName
 	- Added a new section called "Software Information."
	- Added line for Installomator version (both version and versiondate)
	- Added the option to hide Telephone, Email, and/or Help Website by setting their value to "hide."
	- Renamed default label from "Started" to "AAP Started" to clarify timestamp intent
	- Renamed default software-version labels for a unified look
- Updated webhooks for both Slack and Teams (PR #185)
	- Renamed “Microsoft Intune” to “Intune” to prevent the button text from being truncated.
	- Shortened the title and added emojis for quick identification of success and failure.
	- Added version information for OS, Installomator, and AAP.
	- Removed the computer record URL since the button serves the same purpose.
	- Removed the hostname because it often matches the S/N, and the S/N is easier to search.
	- Made the card more compact and information-dense.
 - Fixed label matching to ensure all labels are correctly added to arrays without duplicates (#197)
 - Fixed NextAutoLaunch logic to prevent AAP from launching after install when WorkflowDisableRelaunch is set to TRUE
 - Added logic to pull and use the targetDir value from Installomator labels if present, and the app is not in the /Applications folder
 - Added logic to pull folderName value from Installomator labels if present
 - Added logic to pull versionKey value from Installomator labels if present
 - Added various verbose logging
 - Removed redundant Self Update Enabled logic
 - Added logic to the Installomator Debug Fallback to check output for "No previous app found" and ignore the app if so
 - Added missing `display_string_deferral_selecttitle` key
 - Various spelling and case corrections throughout
 - Fixed an issue preventing the monthly patching cadence flow from being triggered if no apps were found that need updates (Thanks @dan-snelson)
 - Added logic to skip pre-validation for Apple apps that are missing a TeamID (#198)
 - Added build number to script
 - Modified self update logic to use build number (This will allow beta versions to be updated to the final release)
 - Fixed a date format issue when using the monthly patching cadence that was causing AAP to restart upon completion immediately
 - Modified Installomator Debug Fallback to check for packageID if type = pkg or pkgInDmg or pkgInZip, and skip if packageID is blank and unable to complete version comparison
 - Moved get_installomator function to run before populating installomator app labels. This ensures the latest installomator data is retrieved before processing label variables, so they are correctly populated
 - Added a check to make sure the Installomator download is successful. If the labels are missing, AAP will retry getting Installomator twice. On the third failure, AAP will quit and not move forward
 - Added a warning in the log if the installomator label file count is less than the threshold (1000)
 - Adjusted version comparison logic to only allow the installomator version comparison fallback to run if `appNewVersion` is not populated. This will speed up the run time
 - Fixed a bug that allowed AAP to restart after install when `WorkflowDisableRelaunch` was set to TRUE (#199)
 - Adjusted deferral and patching dialog sizes to be consistent
 - Added logic to replace whitespace in version numbers with `-` to allow the `is-at-least` function to work correctly with version numbers containing spaces (ex, sublimemerge)
 - Created a helper function to identify the appPath and icon path for dialogs correctly. Overhauled all dialog logic to utilize the new helper function
 - Created a persistent one-time verbose log that will contain the verbose log output from the most recent run. This log is cleared at the beginning of each run

## New features/Specific Changes in 3.4.2
- Fixed order of `get_installomator` and `get_preferences`
- Complete re-write of logic to populate app names, icons, status, and statustext in the various dialogs: Fixes missing icons, inconsistent app names, statu,s and statustext updates
- Flipped buttons on the deferral dialog so that Defer is the primary button, preventing accidental installs. Renamed `Continue` to `Install Now`

## New features/Specific Changes in 3.4.0
- [Added App Auto-Patch Script Self Update functionality](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Self-Update-Function) (Feature Request #128)
	- Managed Config: Configure using the SelfUpdateEnabled | SelfUpdateFrequency keys
 - CLI: Configure using the --self-update-enabled | --self-update-disabled | --self-update-frequency triggers. Force update using --force-self-update-check trigger
- [Monthly Patching Cadence Functionality:](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Monthly-Patching-Cadence) Added the ability to set a Monthly Patching Cadence (e.g., Patch Tuesday).
	- MonthlyPatchingCadenceEnabled (TRUE|FALSE)
	- MonthlyPatchingCadenceOrdinalValue: Week of the month you want AAP to be scheduled (first|second|third|fourth|fifth|final)
	- MonthlyPatchingCadenceWeekdayIndex: Day of the week you want AAP to be scheduled (sunday|monday|tuesday|wednesday|thursday|friday|saturday)
	- MonthlyPatchingCadenceStartTime: Local time you want AAP to be scheduled (ex, `09:00:00`)
- Standardize timestamp format and use actual timezones instead of hard-coded UTC. Cleaned up and adjusted NextAutoLaunch format to use date datatype (#152)
- Added check for appName in Installomator label to populate the correct app name to improve app detection (Issue #155)
- Updated logic to populate app icons correctly for apps not located in the /Applications folder
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

## Getting Started with App Auto-Patch

App Auto-Patch automatically installs itself and the necessary components anytime it's run from outside the working folder `/Library/Management/AppAutoPatch/`
For more information on getting started and testing, please visit the [AAP Wiki](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki) page for more information

- After installation, you can run `sudo appautopatch` from the terminal with any parameters to configure as you'd like. Examples:

`sudo appautopatch --interactiveMode=2 --workflow-install-now --deadline-count-focus=2 --deadline-count-hard=4 --ignored-labels="microsoft* googlechrome* jamfconnect zoom* 1password* firefox* swiftdialog" --verbose-mode`

Or trigger the script directly to perform an install with the parameters you'd like. Example:

`./App-Auto-Patch-via-Dialog.zsh --interactiveMode=2 --workflow-install-now --deadline-count-focus=2 --deadline-count-hard=4 --ignored-labels="microsoft* googlechrome* jamfconnect zoom* 1password* firefox* swiftdialog" --verbose-mode`

 - You can find a mapping of 2.x variables to 3.5.0 configuration and command line options from the following TSV file: [Migration Options](https://github.com/App-Auto-Patch/App-Auto-Patch/blob/main/Resources/App-Auto-Patch%203.0.0-Migration-Options.tsv)
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
