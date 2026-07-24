# CHANGELOG

This is a user-facing summary of App Auto-Patch releases: what changed, what's new, and what you need to know before upgrading. For a detailed, line-by-line development history, see [CHANGELOG_DETAIL.md](CHANGELOG_DETAIL.md).

# Version 3

## Version 3.6.1
### 23-Jul-2026

**Fixes**

- Fixed: when using `InstallomatorVersionCustomRepoPath`/`InstallomatorVersionCustomBranchName` to pull Installomator from a custom fork and branch, AAP could silently download from the wrong branch if another branch's name contained the configured branch name as a substring (e.g. `apple-ls` vs. `dev-apple-ls`)
- Fixed: `SelfUpdateEnabled`/`SelfUpdateFrequency` weren't resolved (from managed preferences or local config) until after AAP had already checked for and installed a self-update, so a managed `SelfUpdateEnabled=false` had no effect on a Mac's first-ever run (before any local preference existed). These are now resolved before the self-update check runs
- Fixed: on fully-silent, unattended runs (`InteractiveMode 0`, or the `--workflow-install-now-silent` trigger) - intended for lab/kiosk Macs with no user ever logged in - AAP still waited for the Dock/loginwindow to become active (up to 10 minutes) and still checked for/installed/updated swiftDialog, even though neither is ever needed for a fully-silent run. Both are now skipped for those runs
- Fixed: the Jamf Application & Custom Settings schema defined `VersionComparisonMethod` with incorrect lowercase casing (`versionComparisonMethod`), so a value set through the Jamf schema UI was silently never read by AAP and always fell back to the default (`IS_AT_LEAST`) (#237)
- Fixed: `appsUpToDate()` called a non-existent `notice` function (instead of `log_notice`) after a patch run, producing a `command not found: notice` error in the log even on an otherwise-successful run (#237)
- Fixed: `appsUpToDate()`'s "all apps up to date" detection and the Installomator error-log position tracker both referenced an undefined `scriptLog` variable (should have been `appAutoPatchLog`), causing a `tail: : No such file or directory` error on every patch run
- Changed: leaving `SupportTeamPhone`/`SupportTeamEmail`/`SupportTeamWebsite` unconfigured now hides that line from the info dialog, the same as explicitly setting it to `hide` - previously an unconfigured field fell back to a hardcoded placeholder (e.g. "Add IT Phone Number") that displayed literally as if it were a real value (#241)

## Version 3.6.0
### 20-Jul-2026

**⚠️ Before you upgrade:** Background Patch Closed Apps (below) is **enabled by default** and applies under both `InteractiveMode 1` and `InteractiveMode 2`. If you are not ready for AAP to silently patch closed apps, set `WorkflowBackgroundPatchClosedApps` to `false` in your managed configuration before deploying this version. There are no other breaking changes in this release.

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

- **Root3 Support App Extension example** — A ready-to-deploy example integration (`Resources/SupportApp-Extension/`) for the [Root3 Support App](https://github.com/root3nl/SupportApp): shows the count of pending updates in a Support App tile, with a choice of two scripts for what happens when it's clicked — show a dialog listing the pending apps (with icons and current/new version) and "Install Now"/"Later" buttons before kicking off a `--workflow-install-now` patch run, or skip straight to the patch run with no dialog first. See the [Reporting](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Reporting) wiki page for setup instructions.

- **Version details in patch dialogs** — The deferral and hard-deadline dialogs now show each app's current and new version underneath its name, e.g. "Current Version: 128.0.6613.138 → New Version: 129.0.6668.59", so users know exactly what's changing before they install.

- **Startup & download reliability improvements**
	- AAP now waits for the Dock to become active (up to 2 minutes) before proceeding at startup, ensuring a full user session is established first.
	- The swiftDialog download and code-signing verification now automatically retry up to 3 times before failing, reducing false failures on flaky networks.

- **Verbose log retention** — The verbose log is now archived (instead of being deleted every run) once it grows past a size threshold, matching the existing rotation behavior of the main log, with a capped number of archives to prevent unbounded disk usage.

- **Banner image support** — The Patching, Deferral, and Hard Deadline dialogs can now display a custom banner (image, URL, solid colour, or gradient) across the top in place of the plain text title, using swiftDialog's `--bannerimage`/`--bannertitle`/`--bannerheight` options. If no banner image is configured, dialogs look exactly as before.
	- Managed Preference Key: `<key>BannerImage</key>` `<string>Filepath|URL|colour=#hex|gradient=colour,colour</string>` — leave unset to keep the standard text title
	- Managed Preference Key: `<key>BannerTitle</key>` `<string>Text</string>` — text shown inside the banner; leave unset for no title text at all (e.g. if your `BannerImage` already has title text baked into the image itself)
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
- Fixed: under `InteractiveMode 2`, the staging/silent-patch progress dialog could be left open indefinitely (even after AAP itself exited) if every queued app was successfully patched silently, with none left to show the user
- Fixed: the self-update interval always used the 24-hour ("daily") schedule regardless of the configured `SelfUpdateFrequency` value, due to a zsh arithmetic quirk
- Hardened several file paths used internally by AAP (staging folder, error-log temp files) against tampering by other local users on shared/multi-user Macs; no configuration changes are needed and there is no expected behavior change on typical single-user deployments
- Fixed: leaving `BannerTitle` unset always fell back to showing the app title inside the banner - there was no way to display a `BannerImage` with no title text overlaid at all. Leaving `BannerTitle` unset now shows the banner image with no title text, useful if your `BannerImage` already has title text baked into the image itself
- Fixed: certain Installomator labels that call the `printlog` logging helper directly from within their own label code (e.g. `googlechrome`, which uses it to display a deprecation warning) would fail to be evaluated during discovery, silently skipping that app every run instead of detecting available updates for it

## Version 3.5.0
### 22-Dec-2025
- New Version Comparison Method options
	- New `versionComparisonMethod` key with the options `IS_AT_LEAST` and `EQUAL_TO`
 	- `IS_AT_LEAST`: Checks if the currently installed version is the same or greater than the new version available. Utilizes the "Is-At-Least" function.
 	- `EQUAL_TO`: Checks if the currently installed version is equal to the new version available
- Optional Label logic updates
	- Optional Labels will now be checked for both Installed and Update Available
 	- **Breaking Change**: Optional labels will be checked during the discovery phase. If you use Optional labels and had previously disabled the discovery workflow, it must now be enabled for the labels to be checked
 	- You can use an asterisk `*` to ignore all labels, and any optional labels will be omitted from the ignore list to be checked if installed and update available
- Option to disable Installomator Debug Fallback for version comparison
	- Key: `VersionComparisonInstallomatorFallback` `<true/>` | `<false/>`
 	- TRUE (Default): If AAP is unable to do a version comparison due to a missing `appNewVersion` in Installomator, it falls back to using Installomator Debug mode, which will usually indicate if there is a new version or not for an app. Setting this key to TRUE will keep this functionality enabled
  	- FALSE: Disables the Installomator Debug Fallback. If the `appNewVersion` is unavailable, AAP will ignore the app and not add it to the queue
- Added Zoom Call Active Check option: When enabled, if a user starts the install process and then starts a Zoom call, App Auto-Patch will skip the Zoom update to prevent closing Zoom in the middle of the meeting
	- Default is set to Enabled
   	- Managed Preference Key: `<key>ZoomCallActiveCheck</key>` `<true/>` | `<false/>`
  	- CLI Options: `--zoom-call-active-check-enabled` `--zoom-call-active-check-disabled`
- Updated info dialog with more information and easier-to-read formatting
	- Bolded labels and SupportTeamName
 	- Added a new section called "Software Information."
	- Added line for Installomator version (both version and versiondate)
	- Added the option to hide Telephone, Email, and/or Help Website by setting their value to "hide."
	- Renamed default label from "Started" to "AAP Started" to clarify timestamp intent
	- Renamed default software-version labels for a unified look
- Updated webhooks for both Slack and Teams
	- Renamed "Microsoft Intune" to "Intune" to prevent the button text from being truncated.
	- Shortened the title and added emojis for quick identification of success and failure.
	- Added version information for OS, Installomator, and AAP.
	- Removed the computer record URL since the button serves the same purpose.
	- Removed the hostname because it often matches the S/N, and the S/N is easier to search.
	- Made the card more compact and information-dense.
- Fixed label matching to ensure all labels are correctly added to arrays without duplicates
- Fixed NextAutoLaunch logic to prevent AAP from launching after install when WorkflowDisableRelaunch is set to TRUE
- Added logic to pull and use the targetDir value from Installomator labels if present, and the app is not in the /Applications folder
- Added logic to pull folderName value from Installomator labels if present
- Added logic to pull versionKey value from Installomator labels if present
- Added logic to the Installomator Debug Fallback to check output for "No previous app found" and ignore the app if so
- Various spelling and case corrections throughout
- Fixed an issue preventing the monthly patching cadence flow from being triggered if no apps were found that need updates
- Added logic to skip pre-validation for Apple apps that are missing a TeamID
- Added build number to script
- Modified self update logic to use build number (This will allow beta versions to be updated to the final release)
- Fixed a date format issue when using the monthly patching cadence that was causing AAP to restart upon completion immediately
- Fixed a bug that allowed AAP to restart after install when `WorkflowDisableRelaunch` was set to TRUE
- Adjusted deferral and patching dialog sizes to be consistent
- Added logic to replace whitespace in version numbers with `-` to allow the `is-at-least` function to work correctly with version numbers containing spaces (ex, sublimemerge)
- Created a persistent one-time verbose log that will contain the verbose log output from the most recent run. This log is cleared at the beginning of each run

## Version 3.4.2
### 20-Oct-2025
- Fixed button order on deadline dialog (button one cannot be disabled when using a dialog timer)

## Version 3.4.1
### 19-Oct-2025
- Fixed order of `get_installomator` and `get_preferences`
- Complete re-write of logic to populate app names, icons, status, and statustext in the various dialogs: Fixes missing icons, inconsistent app names, status, and statustext updates
- Flipped buttons on the deferral dialog so that Defer is the primary button, preventing accidental installs. Renamed `Continue` to `Install Now`

## Version 3.4.0
### 18-Oct-2025
- Added App Auto-Patch Script Self Update functionality
- Standardized timestamp format and use actual timezones instead of hard-coded UTC
- Added check for appName in Installomator label to populate the correct app name to improve app detection
- Updated logic to populate app icons correctly for apps not located in the /Applications folder
- Added logic to check for appCustomVersion in Installomator label to pull the correct version of installed apps
- Added logic to ignore PWA apps from Chrome & Edge
- Added `--reset-labels` trigger functionality
- Fixed Jamf Self Service Icon Overlay & added support for Jamf Self Service+
- Added option to set the Dialog Icon to a custom filepath or URL via MDM or CLI
- Added the ability to set a Monthly Patching Cadence (e.g., Patch Tuesday)
	- `monthly_patching_cadence_enabled` (TRUE|FALSE)
	- `monthly_patching_cadence_ordinal_value`: Week of the month you want AAP to be scheduled (first|second|third|fourth|fifth|final)
	- `monthly_patching_cadence_weekday_index`: Day of the week you want AAP to be scheduled (sunday|monday|tuesday|wednesday|thursday|friday|saturday)
	- `monthly_patching_cadence_start_time`: Local time you want AAP to be scheduled
- Fixed a bug that would result in a "Print: Entry, ':userInterface:dialogElements', Does Not Exist" message if no language entries exist in the PLIST

## Version 3.3.0
### 21-Aug-2025
- Added functions to write patching receipts into the App Auto Patch management folder. Receipts are used to report success/failure on app patching

## Version 3.2.2
### 20-May-2025
- Fixed logic for resetting PatchStartDate to use the new date for deferrals instead of the date prior to the reset

## Version 3.2.1
### 01-May-2025
- Added logic to kill the Dialog process if a previous PID is found

## Version 3.2.0
### 29-Apr-2025
- Added multi-language support: Entries can be added to the managed configuration profile for multiple languages, based on the setting for the user in macOS
- Added `--workflow-install-now-silent` option which runs through the workflow without deferrals but does not display dialogs
- Added option to disable Installomator Updates using `<key>InstallomatorUpdateDisable</key>` `<string>TRUE,FALSE</string>`
- Added dialogTargetVersion and set to version 2.5.5 as the minimum required due to issues with the deferral menu on older versions

## Version 3.1.2
### 11-Apr-2025
- Fixed a bug that prevented the proper app name from populating for a small number of labels
- Fixed a bug when using wildcards for ignored and required labels that could cause the label to skip being added
- Fixed a bug that could prevent a label from being added if that label name matched part of a label in the ignoredLabelsArray
- Fixed a bug to pull the correct label name for cases where the label fragments file contains multiple label references (ex, Camtasia|Camtasia2025)
- Fixed a bug that prevented the proper app name and icon from populating for a small number of labels on the Patching Dialog
- Fixed a bug that prevented Installomator from sending the proper status updates to the swiftDialogCommandFile
- Added the dialog label to the ignored label list to prevent the dialog from updating during runtime

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
- Added the ability to pull from a custom Installomator fork. It must include all Installomator contents, including fragments
- Added logic to check for a successful App Auto Patch installation
- Fixed logic for InteractiveMode to use the default if no option is set via MDM or command line
- Fixed logic for DaysUntilReset to use the default if no option is set via MDM or command line
- Fixed logic where the script was improperly shifting CLI options when running from Jamf and not using built-in parameter options
- Updated Microsoft Teams Webhook per [Create incoming webhooks with Workflows for Microsoft Teams](https://support.microsoft.com/en-us/office/create-incoming-webhooks-with-workflows-for-microsoft-teams-8ae491c7-0394-4861-ba59-055e33f75498)
- Fixed issues with dialog logic for Install Now Workflow

## Version 3.0.4
### 14-Mar-2025
- Fixed logic so that InteractiveMode=0 will not run the deferral workflow or display a deferral dialog
- Updated workflow_disable_relaunch logic to not relaunch AAP if set to true and AAP is installing or Jamf is the parent process
- Fixed an issue that was causing Optional labels to be duplicated when added to the Required queue if the app is installed

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
- Added logic for Jumpcloud MDM and updated Webhook logic for the Jumpcloud MDM URL

## Version 3.0.0
### 08-Mar-2025
- Final Version
