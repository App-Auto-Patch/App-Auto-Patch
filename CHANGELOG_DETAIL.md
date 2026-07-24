# CHANGELOG

# Version 3

## Version 3.6.1
### 23-Jul-2026 (2) - Build 3.6.1.2607231800
- Fixed: `self_update()` read `SelfUpdateEnabled`/`SelfUpdateFrequency` directly from `appAutoPatchLocalPLIST` on its own, completely bypassing the managed-preference/local-preference merge and `set_defaults()`/CLI-resolved option variables that every other preference goes through - because `self_update()` is called early in `workflow_startup()` (right after `install_app_auto_patch`), well before `get_preferences()`/`manage_parameter_options()` run and populate/normalize those option variables from managed and local prefs. On a Mac's first-ever run (no local plist yet), `self_update()`'s own fallback (`|| echo "1"`) meant it always checked for and could install an update, even with a managed `SelfUpdateEnabled=false` in place, since that managed value hadn't been read yet
	- Fixed by extracting a new `resolve_self_update_preferences()` function that performs the same managed-overrides-local-overrides-default merge and normalization used elsewhere in the script for `SelfUpdateEnabled`/`SelfUpdateFrequency` specifically, called immediately before `self_update()` in `workflow_startup()`. `self_update()` itself now just reads the already-resolved `${self_update_enabled_option}`/`${self_update_frequency_option}` instead of doing its own independent `defaults read`
	- Removed the now-redundant/duplicate `SelfUpdateEnabled`/`SelfUpdateFrequency` managed+local reads and merge in `get_preferences()`, and the redundant normalization/save-back block (including previously-dead, unused `_sue_norm` normalization) in `manage_parameter_options()`, since both are now handled solely by `resolve_self_update_preferences()`

### 23-Jul-2026 (1) - Build 3.6.1.2607231457
- Fixed: `installomatorVersionCustomBranchName`/main-branch lookups resolved the wrong commit SHA when another branch's name contained the target branch name as a substring (e.g. requesting `apple-ls` could return `dev-apple-ls`'s commit instead), because `grep -A2 "$installomatorVersionCustomBranchName"` matched any line containing that text, and `tail -1` then picked whichever matching branch happened to sort last in the GitHub API response
	- Fixed by tightening the `grep` pattern to match the exact `"name": "branch"` JSON key/value line (`grep -A2 "\"name\": \"${installomatorVersionCustomBranchName}\""`), applied to both the custom-repo/branch and standard `main`-branch lookups (4 call sites total)

## Version 3.6.0
### 17-Jul-2026 (2) - Build 3.6.0.2607171635
- Fixed: label fragments that call Installomator's own `printlog` helper directly (e.g. `googlechrome`'s deprecation warning, `printlog "..." REQ`) crashed evaluation of that label's case block with `printlog:40: bad math expression: empty string`, so the label silently failed to be evaluated (no version/name/etc. extracted) every time it was encountered during discovery
	- Root cause: `printlog` (defined in Installomator's `functions.sh`, which AAP sources to pick up label-fragment helper functions) references a `${levels}` associative array and `${LOGGING}` variable that Installomator normally defines in `arguments.sh` - a file AAP intentionally never sources, since it also handles Installomator's full CLI argument parsing/label routing, which would conflict with AAP's own flow. Without them, `${levels[$log_priority]} -ge ${levels[$LOGGING]}` resolves to comparing two empty strings, which zsh's `(( ))` arithmetic can't evaluate
	- Fixed by defining a minimal `levels`/`LOGGING` (plus `label`/`log_location`/`previous_log_message`/`logrepeat`) shim immediately before AAP sources `functions.sh`, letting `printlog` run standalone and folding any label-emitted messages into AAP's own verbose log rather than losing them (or crashing the label)
	- Verified against the live `googlechrome` fragment and Installomator's real `functions.sh`/`getJSONValue`: the label's case block now evaluates cleanly end-to-end (including the live network lookup for `appNewVersion`) with no error, where it previously failed every time

### 17-Jul-2026 (1) - Build 3.6.0.2607171559
- Fixed: `dialogTitleOptions`'s banner logic always passed `--bannertitle`, falling back to `${appTitle}` whenever `BannerTitle` was unset - so admins using a `BannerImage` that already has title text baked into the image itself had no way to avoid AAP layering a redundant/conflicting `--bannertitle` on top of it. `--bannertitle` is now only added when `BannerTitle` is explicitly set; leaving it unset now displays the banner image with no title text overlaid

### 14-Jul-2026
- Added `aap_pending_apps_dialog.zsh` to the Root3 Support App Extension example (`Resources/SupportApp-Extension/`), as a second option for the Extension tile's `Action` alongside the existing `aap_install_now.zsh` - admins can choose whichever fits their environment
	- Reads pending apps from the `xyz.techitout.appAutoPatchReport.plist` report file (no fresh discovery scan) and shows a swiftDialog list - app icon, name, and a "Current Version → New Version" subtitle for each - with only "Install Now"/"Later" buttons; no deferral timer or menu
	- "Install Now" kicks off `appautopatch --workflow-install-now` in the background; either button then re-runs `aap_pending_updates.zsh` to refresh the tile's count. If there are zero pending apps when clicked, shows a brief "You're all up to date!" message instead of the list
	- Reads the same managed/local preferences AAP itself uses to build this dialog - `DialogIcon`, `UseOverlayIcon`, `BannerImage`/`BannerTitle`/`BannerHeight`, `AppTitle`, `DialogOnTop`, and the existing `display_string_version_current`/`display_string_version_new`/`display_string_there_are`/`display_string_deferral_button2` language overrides (Managed Preferences only, matching AAP's own behavior) - so its appearance and wording stay consistent with AAP's own dialogs
	- Added a new, optional managed preference key, `display_string_pendingapps_button_later` (under the same `dialogElements` array used for AAP's other language overrides), to customize the "Later" button's text; defaults to "Later". Added to both Profile Manifests (`xyz.techitout.appAutoPatch-manifest.plist` and `xyz.techitout.appAutoPatch-manifest-jamf.json`)
	- `aap_install_now.zsh` (immediate patch run, no pending-apps list or confirmation dialog first) remains available as the alternative `Action` for admins who prefer a single-click "patch now" tile

### 13-Jul-2026 (2) - Build 3.6.0.2607132238
- Hardened several local-privilege-escalation-adjacent paths flagged by a third-party review of the 3.6.0.2607131550 build
	- Fixed: `self_update`'s retry-interval calculation (`local interval=$(( freq=="daily" ? ... ))`) always resolved to the 24-hour ("daily") interval regardless of the configured `SelfUpdateFrequency`, because zsh's `$(( ))` arithmetic coerces non-numeric string operands to `0` before comparing, so `freq=="daily"` evaluated true no matter what `freq` actually held. The interval is now precomputed once via a `case`/`esac` into a plain `freqSeconds` variable and referenced numerically in all six call sites
	- Hardened `workflow_stage_updates`'s staging folder (`/private/tmp/AAPStage`, under world-writable `/private/tmp`): it is now refused and recreated if found to be a symlink or not root-owned, then explicitly `chown root:wheel`/`chmod 700`'d before use, with staging skipped entirely if it can't be secured. Previously a local user could pre-create/own this directory and plant a malicious installer that would later be trusted and installed as root via `downloadURL=file://...`
	- Hardened two fixed, predictable root-written paths under world-writable `/var/tmp` (`Installomator_marker.txt`, `overlayicon.icns`) against symlink redirection by removing any pre-existing symlink immediately before each write
	- Changed the duplicate Installomator error-log directory (used for webhook reporting) from `chmod 655` to `chmod 700` - `655` left copied error-log excerpts readable by any local user
- Fixed: `install_app_auto_patch`'s permission-hardening pass (`chown -R root:wheel`/`chmod -R 755`/etc.) only ever applied to `appAutoPatchFolder` itself, not its parent - if `/Library/Management` didn't already exist, `mkdir -p` created it with whatever ownership/umask happened to be in effect at the time, and it was never subsequently corrected. Now, if `appAutoPatchFolder`'s parent directory is the default `/Library/Management`, that container is also explicitly set to `root:wheel`/`755` (non-recursively, since other tools may store unrelated items there)

### 11-Jul-2026 (2) - Build 3.6.0.2607111525
- Fixed: the staging/silent-patch progress dialog (`InteractiveMode 2`) could be left open indefinitely if every queued app was successfully patched silently
	- `swiftDialogStagingWindow` (opened when `countOfElementsArray` is non-empty, before staging/`workflow_silent_patch_closed_apps` run) and `swiftDialogCompleteDialogStaging` (which closes it) were both gated on the same `[[ ${#countOfElementsArray[@]} -gt 0 ]]` check
	- `workflow_silent_patch_closed_apps` rebuilds `countOfElementsArray` to reflect only the labels still remaining after silent patching - if every queued app was successfully patched silently, the array is empty by the time the close-check runs, even though the window was definitely opened earlier (against the original, non-empty count)
	- As a result, the close-check's condition evaluated to false and `swiftDialogCompleteDialogStaging` was never called, leaving the progress window open on screen indefinitely, even after the script itself exited
	- Introduced a dedicated `stagingWindowOpened` flag, set to `TRUE` at the moment the window is actually opened; the close-check now tests this flag instead of re-evaluating `countOfElementsArray`

### 11-Jul-2026 (1)
- Added a Root3 Support App Extension example (`Resources/SupportApp-Extension/`)
	- New `aap_pending_updates.zsh` populates a Support App Extension with the count of apps currently queued for patching, read from the `xyz.techitout.appAutoPatchReport.plist` report file added earlier in 3.6.0. Intended to run via the Extension's `OnAppearAction` so the count stays current every time the Support App popover appears
	- New `aap_install_now.zsh` runs `appautopatch --workflow-install-now` when the Extension tile is clicked (`Action`/`ActionType: PrivilegedScript`), then re-runs `aap_pending_updates.zsh` to refresh the count once the run completes
	- Both scripts default to reading/writing against AAP's default install folder and a configurable deployment path (`/Library/Management/AppAutoPatch/SupportApp/`), overridable via variables at the top of each script
	- Includes a README with deployment steps and an example Configuration Profile snippet - see the [Reporting](https://github.com/App-Auto-Patch/App-Auto-Patch/wiki/Reporting) wiki page for full details

### 10-Jul-2026
- Updated Profile Manifests with new keys for version 3.6.0

### 09-Jul-2026 (11) - Build 3.6.0.2607091824
- Added a progress dialog covering the staging and background-patch-closed-apps phases for `InteractiveMode 2` (#209)
	- Previously, `InteractiveMode 2` users would see the discovery dialog close (`swiftDialogCompleteDialogDiscover`) and then see nothing at all until the deferral or hard-deadline dialog appeared — a potentially long, unexplained gap while `workflow_stage_updates` and `workflow_silent_patch_closed_apps` ran
	- New `swiftDialogStagingWindow`/`swiftDialogCompleteDialogStaging` functions and `dialogStagingConfigurationOptions` array mirror the existing discovery dialog's bouncing/indeterminate `--mini --progress` window, built in `workflow_startup` alongside `dialogDiscoverConfigurationOptions`
	- Shown only when `InteractiveModeOption == 2` and there is at least one queued label (`countOfElementsArray` non-empty) — `InteractiveMode 1` (Silent Discovery, Interactive Patching) intentionally keeps this phase dialog-free, matching its existing behavior for the discovery phase itself
	- The window's `progresstext` is updated live (via the existing `swiftDialogUpdate` command-file mechanism) as the workflow moves from staging to silently patching closed apps, so the message reflects whichever step is actually in progress, then the window is closed just before the install-now/silent bypass or the deferral/hard-deadline dialog is shown
	- New display strings (overridable via the existing `dialogElements` managed-preference mechanism): `display_string_staging_message` (default `"Preparing updates"`), `display_string_staging_progress` (default `"Staging"`), `display_string_silent_patch_progress` (default `"Installing updates for closed apps"`)

### 09-Jul-2026 (10) - Build 3.6.0.2607091752
- Fixed: the countdown line in the "Install Now" confirmation dialog disappeared after the first per-second update (#209)
	- swiftDialog's runtime command-file `message:` update does not honor literal `\n` line breaks the way the initial `--message` CLI argument does — text after the break simply failed to render once `_dialog_confirm_install_now`'s per-second loop sent its first `swiftDialogUpdate "message: ..."` command
	- Switched to `<br>` for the line break between the confirmation question and the countdown text, in both the initial dialog launch and every per-second update, matching the same convention already used elsewhere in this script for live `infobox:` updates (e.g. `workflow_do_Installations`'s `swiftDialogUpdate "infobox: + <br><br>"`)

### 09-Jul-2026 (9) - Build 3.6.0.2607091725
- Fixed: the "Install Now" confirmation dialog's countdown made both buttons unresponsive for the first ~4 seconds
	- This is swiftDialog's own built-in behavior whenever `--timer` is used — buttons are disabled briefly to prevent accidental dismissal — which was undesirable here since a user who already clicked `Install Now` once shouldn't have to wait to click through a second time
	- `_dialog_confirm_install_now` no longer passes `--timer` to swiftDialog. Instead, it launches the confirmation dialog in the background, tracks its own countdown in the script (one tick per second), and live-updates a small line of text in the dialog's message (via the existing `swiftDialogUpdate`/command-file mechanism) showing how many seconds remain — the buttons themselves are fully clickable from the moment the dialog appears
	- The countdown text uses `--messagefont size=12` to keep it visually secondary/small relative to the main confirmation question, without changing the mini dialog's overall size
	- Once per second the function checks (via `kill -0`) whether the user has already dismissed the dialog, so clicking a button is picked up promptly rather than waiting for the full countdown to finish
	- If the countdown reaches zero with no response, the function sends the dialog a `quit:` command and defaults to continuing the install (unchanged from the previous behavior) — it no longer relies on swiftDialog's own exit-code-4 timeout signal, since there's no built-in `--timer` running anymore
	- `${DialogTimeoutConfirmInstall}` (added in the previous build) continues to control the countdown duration, now purely as a script-managed value rather than a swiftDialog `--timer` argument
	- New display strings (overridable via the existing `dialogElements` managed-preference mechanism): `display_string_confirminstall_countdown` (default `"Continuing automatically in"`), `display_string_confirminstall_countdown_suffix` (default `"seconds…"`)

### 09-Jul-2026 (8) - Build 3.6.0.2607091700
- Added a countdown timer and default-to-install timeout behavior to the "Install Now" confirmation dialog
	- `_dialog_confirm_install_now` now passes `--timer "${DialogTimeoutConfirmInstall}"` to the mini confirmation dialog, so the user can see a countdown bar indicating how long they have to respond, while keeping the dialog itself unchanged in size (`--style mini`, no additional UI elements added)
	- New managed preference `DialogTimeoutConfirmInstall` (integer seconds, default `15`), following the same managed > local > default resolution pipeline as `DialogTimeoutDeferral` (`dialog_timeout_confirm_install_managed`/`_local` in `get_preferences`, resolved and logged in `set_defaults`/`get_preferences`)
	- Unlike the deferral dialog's timeout (swiftDialog exit code 4, which defaults to *deferring*), letting the confirmation dialog's timer expire defaults to *continuing with the install* — the user already clicked `Install Now` once, so a silent, un-acknowledged timeout is treated as tacit confirmation rather than a change of mind
	- `_dialog_confirm_install_now`'s exit-code handling was expanded from a binary `0`-vs-everything-else check to an explicit `case`: exit code `2` (button2, `No, Go Back`) sets `dialog_user_choice_install="FALSE"`; exit code `4` (timer expired) and everything else (button1, quit key) set `dialog_user_choice_install="TRUE"`
	- Managed Preference Key: `<key>DialogTimeoutConfirmInstall</key>` `<integer>seconds</integer>`

### 09-Jul-2026 (7) - Build 3.6.0.2607091622
- Added an "Install Now" confirmation prompt to `dialog_install_or_defer`
	- Clicking the `Install Now` button (button2, swiftDialog exit code 2, previously caught by the `*` catch-all case) no longer immediately proceeds to installation — it now displays a small `--style mini` confirmation dialog (new `_dialog_confirm_install_now` helper) asking the user to confirm
	- Confirming (`Yes, Install Now`, button1) sets `dialog_user_choice_install="TRUE"` and proceeds exactly as before; declining (`No, Go Back`, button2, or dismissing/timing out the mini dialog) returns to the deferral dialog rather than deferring or installing
	- `dialog_install_hard_deadline` is intentionally unchanged — that dialog offers no real choice (button2 is disabled), so a confirmation step would add no value there
	- The deferral dialog's on-screen swiftDialog `--timer` countdown now stays consistent across the confirmation detour: `dialog_install_or_defer` records a wall-clock start time once (`deferral_dialog_start_epoch`) and, each time it (re)displays the deferral dialog inside its new loop, passes the remaining seconds (`${DialogTimeoutDeferral}` minus elapsed real time, floored at 1 second) rather than the full original duration — so time spent on the confirmation prompt counts against the same overall countdown instead of resetting it
	- If the countdown fully elapses while the confirmation dialog is showing, the very next redisplay of the deferral dialog receives a 1-second timer and immediately times out via the existing swiftDialog exit-code-4 "display timeout" path, rather than requiring special-case handling
	- New display strings (overridable via the existing `dialogElements` managed-preference mechanism): `display_string_confirminstall_message`, `display_string_confirminstall_button1` (default `"Yes, Install Now"`), `display_string_confirminstall_button2` (default `"No, Go Back"`)

### 08-Jul-2026 (6) - Build 3.6.0.2607081400
- Added `--force-discovery` CLI trigger to force the App Discovery workflow to run once, bypassing the `DiscoveryFrequency` window
	- New `force_discovery_option` variable, set by the `--force-discovery` CLI flag, and a new one-shot flag file (`FORCE_DISCOVERY_FILE`, `${appAutoPatchFolder}/.ForceDiscovery`) following the same pattern already used for `--workflow-install-now`
	- `workflow_startup` checks for either the CLI flag or the flag file and (re-)touches the flag file, so the request survives a `restart_aap` relaunch — this matters because Jamf-triggered runs are relaunched via `launchctl bootstrap` on the LaunchDaemon, which re-executes the script without the original CLI arguments
	- In `main()`'s discovery-decision logic, `force_discovery_option` is evaluated ahead of the normal `DiscoveryFrequency` window check and forces `run_discovery="TRUE"` for that run only
	- The flag file is deleted the moment `force_discovery_option` is evaluated in `main()` (regardless of whether `workflow_disable_app_discovery_option` ultimately still blocks discovery), guaranteeing the trigger fires at most once and never loops indefinitely
	- Explicit administrative disabling of discovery (`WorkflowDisableAppDiscovery` / `workflow_disable_app_discovery_option`) still takes precedence over a forced-discovery request — `--force-discovery` only bypasses the frequency window, not a hard admin disable
	- `reset_defaults` clears the `FORCE_DISCOVERY_FILE` flag file alongside the existing `WORKFLOW_INSTALL_NOW_FILE`/`WORKFLOW_INSTALL_NOW_SILENT_FILE` cleanup

### 08-Jul-2026 (5) - Build 3.6.0.2607081309
- Fixed: Background Patch Closed Apps was gated to `InteractiveMode 1` only, excluding `InteractiveMode 2`
	- Per AAP's documented mode definitions, `InteractiveMode 0` is Completely Silent, `1` is Silent Discovery/Interactive Patching, and `2` is Full Interactive — both `1` and `2` display the same interactive patching dialog (deferral or hard-deadline) for any remaining open apps, so both benefit equally from silently pre-patching closed apps first
	- `InteractiveMode 0` is correctly excluded: it never shows a dialog and already installs every queued app directly via `workflow_do_Installations` regardless of whether the app is open, so a pre-patch pass would add no value there
	- Changed the gating condition in `main()` from `[[ ${InteractiveModeOption} == 1 ]]` to `[[ ${InteractiveModeOption} -ge 1 ]]`, matching the same `-ge 1` pattern already used elsewhere in the script for other "any interactive mode" checks
	- Updated related log messages and comments in `workflow_silent_patch_closed_apps` accordingly

### 08-Jul-2026 (4) - Build 3.6.0.2607081219
- Added swiftDialog banner image support (`--bannerimage`/`--bannertitle`/`--bannerheight`) as an alternative to the standard `--title` text banner (#205)
	- New `bannerImageOption`, `bannerTitleOption`, and `bannerHeightOption` variables, populated via the standard managed > local > default preference pipeline
	- New `dialogTitleOptions` array is built once in `workflow_startup`, immediately after the existing icon-resolution logic (`icon`/`dialog_icon_option`), and replaces every hardcoded `--title "$appTitle"` array element across the codebase: `dialogPatchingConfigurationOptions`, both branches of `dialog_install_or_defer`'s `deferralDialogContent`, `dialog_install_hard_deadline`'s `deferralDialogContent`
	- When `bannerImageOption` is set (non-empty), `dialogTitleOptions` resolves to `(--bannerimage "$bannerImageOption" --bannertitle "..." [--bannerheight "$bannerHeightOption"])`; when unset, it resolves to the original `(--title "$appTitle")`, so existing deployments see no change in behavior
	- `--bannertitle` falls back to `${appTitle}` when `bannerTitleOption` is blank, so the banner is never left without title text
	- `--bannerheight` is only appended when `bannerHeightOption` is a non-empty integer string; invalid values are dropped (and cleared from the local plist) rather than passed through to swiftDialog
	- Per swiftDialog's behavior, activating a banner image hides the standard `--icon` area — this is expected and matches swiftDialog's own `--hideicon`-equivalent behavior for banners
	- `BannerImage` accepts everything swiftDialog's `--bannerimage` supports: a filepath, a URL, `colour=#hex`, or `gradient=colour,colour`
	- Managed Preference Keys: `<key>BannerImage</key>` `<string>Filepath|URL|colour=#hex|gradient=colour,colour</string>`, `<key>BannerTitle</key>` `<string>Text</string>`, `<key>BannerHeight</key>` `<integer>points</integer>`

### 08-Jul-2026 (3) - Build 3.6.0.2607080957
- Added current/new version subtitles to app listitems in the deferral and hard-deadline dialogs (#146)
	- `dialog_install_or_defer` and `dialog_install_hard_deadline` now display a subtitle under each app name, e.g. `Current Version: 128.0.6613.138  →  New Version: 129.0.6668.59`, using swiftDialog's `--listitem` `subtitle` option
	- New `AAPInstalledVersionByLabel` associative array tracks each queued label's currently-installed version, populated alongside the existing `AAPVersionByLabel` (new/available version) both during discovery and when restoring queue state from the report PLIST on DiscoveryFrequency-skipped runs
	- New `_compute_version_subtitle` helper builds the subtitle text and gracefully degrades: shows both versions when known, falls back to just "New Version" or just "Current Version" if only one is known, and omits the subtitle entirely if neither is available (e.g. very first discovery of an app via the Installomator debug fallback path)
	- Commas are stripped from version strings before use, since swiftDialog's non-JSON `--listitem` syntax treats commas as property separators and would otherwise truncate or corrupt the subtitle
	- Applied consistently everywhere the dialog's app list is built or rebuilt: the initial discovery-time `appNamesArray` population, and all three code paths in `workflow_silent_patch_closed_apps` that re-add a label to the trimmed post-silent-patch `appNamesArray` (Zoom-call-in-progress skip, blocking-process detected, and unexpected-error fallback)

### 08-Jul-2026 (2)
- Cleaned up redundant/incorrect `set_display_strings_language` calls
	- Removed the call in `workflow_startup` that ran *before* `get_preferences`: `langUser` is only populated inside `get_preferences`, so that earlier call always evaluated the managed-language match against an empty `langUser`, meaning it could never apply a managed-profile language override — it only produced the hardcoded English defaults, which were then fully recomputed and overwritten by the correct call later in the same function (after `get_preferences`/`manage_parameter_options` run)
	- Removed the duplicate calls inside `dialog_install_or_defer` and `dialog_install_hard_deadline`: `workflow_startup` runs exactly once, at the very start of `main()`, before either dialog function can be invoked in the same execution, and neither `langUser` nor the managed configuration profile change mid-run, so re-running the string resolution (and its per-string `PlistBuddy` subprocess calls) inside these dialog functions was pure repeated overhead with no behavioral effect
	- `set_display_strings_language` is now called exactly once per run, in `workflow_startup`, immediately after `get_preferences` populates `langUser`

### 08-Jul-2026 (1)
- Fixed: deferral dialog auto-triggering "Install Now" on DiscoveryFrequency-skipped runs
	- `mktemp` creates the swiftDialog command file with mode **600** (root read/write only); `swiftDialogDiscoverWindow` normally runs `chmod 644` as a side-effect before any dialog is shown
	- When discovery is skipped (`DiscoveryFrequency` threshold not yet elapsed), `swiftDialogDiscoverWindow` is never called, so the command file remains mode 600
	- SwiftDialog is launched as root from the LaunchDaemon but switches to the console user's GUI context for display; the console user cannot read a root-owned 600 file, causing swiftDialog to exit immediately with code 1
	- Exit code 1 hits the `*` catch-all in `dialog_install_or_defer`'s `case` statement, setting `dialog_user_choice_install="TRUE"` and triggering `workflow_do_Installations` without the dialog ever appearing
	- Introduced `_prepare_dialog_command_file` helper that unconditionally runs `touch` + `chmod 644` on the command file; called at the entry point of `dialog_install_or_defer`, `dialog_install_hard_deadline`, and `swiftDialogPatchingWindow` so every swiftDialog invocation that uses `--commandfile` is guaranteed a world-readable command file regardless of whether the discovery window ran

### 07-Jul-2026 (4)
- Fixed: successfully-patched apps could re-appear in the update queue on DiscoveryFrequency-skipped runs
	- When `workflow_silent_patch_closed_apps` or `workflow_do_Installations` completed a successful install (Installomator exit 0), the label was correctly removed from the in-memory `queuedLabelsArray` and from the report PLIST — but was never removed from the `DiscoveredLabels` array in the local PLIST
	- On any subsequent run where discovery was skipped (within the `DiscoveryFrequency` window), `labelsArray` is rebuilt entirely from `DiscoveredLabels`, which caused already-patched apps to re-enter the queue and prompt the user unnecessarily
	- New `remove_discovered_label` helper function removes a label from the `DiscoveredLabels` PLIST array by locating its 0-based index via `PlistBuddy` and deleting it; handles first, last, middle, and absent entries safely
	- `remove_discovered_label` is now called alongside `remove_aap_report_item` at every successful-install exit point: the silent background patch pass (`workflow_silent_patch_closed_apps`) and both branches of the user-approved install path (`workflow_do_Installations`)

### 07-Jul-2026 (3)
- Added `IgnoreDNDApps` managed preference — exclude specific apps from display-sleep assertion detection (#149)
	- When `check_user_focus` evaluates display sleep assertions (via `pmset -g assertions`), any process that appears in the `IgnoreDNDApps` list is now skipped rather than triggering a `user_focus_active=TRUE` deferral
	- Useful for background utilities that permanently hold display assertions (e.g. `Logi Options+`, `Amphetamine`, `Lungo`) that should not block interactive patching
	- Process names are matched exactly as `pmset` reports them — including any spaces in the name (e.g. `"Logi Options+"`) — so the ignore list must use the same spelling
	- Accepts a comma-separated string; leading and trailing whitespace around each entry is trimmed automatically
	- An empty or absent `IgnoreDNDApps` value preserves the original behavior: any non-`coreaudiod` display sleep assertion triggers a deferral
	- Managed Preference Key: `<key>IgnoreDNDApps</key>` `<string>App1,App2,App3</string>`

### 07-Jul-2026 (2)
- Fixed: DiscoveryFrequency-skipped runs incorrectly found zero apps to patch
	- `set_defaults` was unconditionally clearing the `DiscoveredLabels` PLIST array on every run, including runs where discovery was intentionally skipped because `DiscoveryFrequency` had not yet elapsed
	- Since the update queue (`labelsArray`/`queuedLabelsArray`) is rebuilt from `DiscoveredLabels` on every run (not just runs where discovery executes), this caused AAP to believe there were no pending updates and skip patching entirely until the next full discovery
	- `DiscoveredLabels` is now only cleared immediately before discovery actually re-runs; it is left untouched on skipped runs so the previously-discovered queue persists correctly
- Added a dedicated report PLIST for persisting the pending-update queue and external reporting (#194)
	- New `xyz.techitout.appAutoPatchReport.plist` file tracks every currently queued app under an `ItemsToInstall` array, formatted to be compatible with third-party reporting/inventory tooling that already knows how to ingest Munki's `ManagedInstallReport.plist` (e.g. `display_name` and `version_to_install` keys), such as the pattern used by [SupportCompanion's `MunkiApps.swift`](https://github.com/macadmins/SupportCompanion/blob/main/SupportCompanion/Helpers/MunkiApps.swift)
	- Each entry records: `name` (label), `display_name`, `installed_version`, `version_to_install`, and `date_discovered`
	- New `queueLabel` behavior: every time a label is queued during discovery, its entry is written (or updated, replacing any prior entry for the same label) via the new `write_aap_report_item` function
	- New `remove_aap_report_item` function removes a label's entry as soon as it is successfully patched — called from both `workflow_silent_patch_closed_apps` (silent background patch success) and `workflow_do_Installations` (user-approved install success) — so the report never shows an already-updated app as still pending
	- New `clear_aap_report` function resets the `ItemsToInstall` array immediately before discovery actually re-runs, keeping the report in sync with the latest scan
	- New `get_aap_report_entries` function restores the in-memory `AAPVersionByLabel` map from the persisted report on DiscoveryFrequency-skipped runs, since that associative array is only otherwise populated while parsing labels during an active discovery pass
- Fixed: apps could be downloaded twice when both Background Patch Closed Apps and Update Staging were enabled together
	- `workflow_stage_updates` previously ran *after* `workflow_silent_patch_closed_apps`, so every closed app was fully downloaded once during the silent-patch attempt and then downloaded again during staging
	- `workflow_stage_updates` now runs first, before any other Installomator activity for the run. Both `workflow_silent_patch_closed_apps` and `workflow_do_Installations` now detect and reuse a staged installer (via a `downloadURL=file://…` override) instead of re-downloading, so every queued app is downloaded at most once per run regardless of which combination of these features is enabled
	- Staged files are only deleted after a successful install; if a closed app turns out to have a blocking process (Installomator exit 12), its staged installer is preserved and reused later once the user approves the update

### 07-Jul-2026
- Added Update Staging — pre-download installers before the user dialog is displayed
	- New `workflow_stage_updates` function runs after discovery (and after the silent background-patch pass if enabled) but before the deferral or deadline dialog is shown to the user
	- For each label in the update queue, AAP resolves the `downloadURL` from the Installomator label fragment (including dynamically-computed URLs such as GitHub release lookups and Sparkle feed checks) and downloads the installer to a local staging folder (`/private/tmp/AAPStage` by default)
	- Supports all Installomator installer types: `dmg`, `pkg`, `zip`, `tbz`, `pkgInDmg`, `pkgInZip`, `appInDmgInZip`; `updateronly` labels (in-app updaters with no installer to download) are automatically skipped
	- When `workflow_do_Installations` later runs, it detects the staged file and overrides `downloadURL` to a `file://` path so Installomator uses the pre-downloaded installer, making the install phase nearly instantaneous for staged updates
	- A `.version` sidecar file records the `appNewVersion` at staging time; on the next discovery cycle, if a newer version is detected the stale staged file is automatically removed and the updated installer is re-downloaded
	- Stale staged files for labels that are no longer in the active update queue are cleaned up at the start of each staging run to prevent unbounded disk usage in `/private/tmp/AAPStage`
	- Staged files are removed after a successful installation (Installomator exit 0); files are retained on non-zero exits so they can be reused on the next install attempt
	- New `_resolve_label_staging_info` helper function executes each label fragment in an isolated `zsh` subprocess (with Installomator helper functions such as `downloadURLFromGit` and `downloadURLFromSparkle` available), capturing `type`, `downloadURL`, `appNewVersion`, `expectedTeamID`, `archiveName`, and `curlOptions` without exposing the parent script environment
	- Labels that declare custom `curlOptions` (e.g. extra HTTP headers required by the download server) are honoured during staging
	- Configurable via new `WorkflowStageUpdates` managed preference key (default: `false`)
		- `true`: Update staging is enabled; installers are pre-downloaded before the user dialog
		- `false` (default): Staging is disabled; AAP downloads and installs on demand as before
	- Managed Preference Key: `<key>WorkflowStageUpdates</key>` `<true/>` | `<false/>`

### 06-Jul-2026
- Added Background Patch Closed Apps for InteractiveMode 1
	- When `InteractiveMode` is set to `1` (Silent Discovery, Interactive Patching), AAP now performs a silent pre-patch pass immediately after discovery and before any user dialog is displayed
	- Apps that are **not currently open** are updated silently in the background using Installomator with `BLOCKING_PROCESS_ACTION=silent_fail`. A successful install (exit 0) removes the app from the update queue entirely
	- Apps that **are currently open** (Installomator exit code 12 — blocking process found) remain in the queue and are presented to the user via the normal deferral or deadline dialog, so the user can choose when to close and update them
	- If all pending updates are resolved silently, no user dialog is shown and AAP proceeds directly to the completion workflow
	- Respects the existing Zoom Call Active Check: if a Zoom meeting is in progress, Zoom labels are skipped during the silent pre-patch and kept in the user dialog queue
	- Patching receipts are written for all apps successfully updated during the silent pre-patch phase
	- Configurable via new `WorkflowBackgroundPatchClosedApps` managed preference key (default: `true`)
		- `true` (default): Silent pre-patch of closed apps is enabled for InteractiveMode 1
		- `false`: Disables the silent pre-patch; all discovered updates are presented to the user in the dialog as before
	- Managed Preference Key: `<key>WorkflowBackgroundPatchClosedApps</key>` `<true/>` | `<false/>`
- Added Discovery Frequency control
	- New `DiscoveryFrequency` managed preference key (integer, hours)
	- When the workflow resets and re-runs (e.g. after a deferral), AAP will skip the discovery phase if the last successful discovery completed within the configured number of hours, saving script runtime, bandwidth, and system resources
	- For example, setting `DiscoveryFrequency` to `24` means discovery only runs once per day regardless of how many times the user defers
	- A value of `0` forces discovery to run on every workflow execution
	- Managed Preference Key: `<key>DiscoveryFrequency</key>` `<integer>hours</integer>`
- Updated verbose log lifecycle management (#222)
	- Removed the unconditional deletion of `appAutoPatchVerboseLog` at the start of every run; the verbose log is now preserved across runs and accumulates entries like the main log
	- Added dedicated `appAutoPatchVerboseLogArchiveSize` variable (default: 10000 KB) as a separate size threshold for the verbose log, independent of the main log archive size
	- Added dedicated `appAutoPatchVerboseLogArchiveFolder` variable pointing to `${appAutoPatchFolder}/logs-verbose-archive`; this folder is created automatically on first install alongside the existing log archive folder
	- The `archive_logs` function now archives the verbose log into `logs-verbose-archive` when it exceeds `appAutoPatchVerboseLogArchiveSize` KB, using the same timestamped zip approach as the main log
	- Added a file-count cap for the verbose log archive: if `logs-verbose-archive` grows beyond 10 files, the oldest archive is automatically deleted to prevent unbounded disk usage
- Added Dock active check to startup workflow (#223)
	- After confirming AAP is running as root, the startup workflow now waits for the Dock process to be active before proceeding, ensuring a user session is fully established
	- Polls every 5 seconds for up to 120 seconds; if the Dock is not active within that window, AAP logs an exit message and exits with code 1 so the LaunchDaemon can retry on the next scheduled run
- Added retry logic to swiftDialog download and verification (#223)
	- The `install_dialog` function now retries the curl download and `spctl` Team ID verification up to 3 times before giving up
	- If the download fails (non-zero curl exit), the partial file is removed and the attempt is retried after a 10-second delay
	- If the Team ID does not match after 3 attempts, AAP displays the existing error dialog and exits, same as before
- Added helper function to safely parse and resolve variable assignments from Installomator label fragments
	- New `_safe_parse_label_var` function replaces `eval`-based label parsing with explicit, safe string substitution
	- Extracts variable name and raw value from label fragment lines, strips surrounding quotes, and resolves `${variable}` references (e.g. `${folderName}`, `${appName}`) without executing arbitrary code
	- Handles the full set of label variables used during discovery: `name`, `appName`, `packageID`, `expectedTeamID`, `targetDir`, `folderName`, `versionKey`, and `type`
	- Improves security and predictability of label fragment parsing across all app discovery logic
- Added logic to ignore apps found in .Trash folders, `/Applications (Parallels)/` and `/Applications (Virtual Machines)/` (#221 #216)
- Fixed an issue that was setting `RemoveInstallomatorPath` to FALSE even if the value in the managed config was set to TRUE (#214)
- Fixed an issue that was preventing the Support Team Website field from being hidden when the managed config was set to `hide` (#213)
- Added Installomator verison output for cases where the installomator updater is diabled (#206)
- Fixed issue preventing Workspace One MDM URL from populating and being used for Slack Webhooks (#208)
- Fixed a typo from the json file being saved properly in the `write_aap_receipt` function (#211)
- Fixed an issue where umlaut values were populating incorrectly for Support Team Name (#204)
	- Switched to plistbuddy for pulling this particular value, will consider switching all config profile pulls to plistbuddy in a future build


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
- Updated info dialog with more information and easier-to-read formatting (PR #184)
	- Bolded labels and SupportTeamName
 	- Added a new section called "Software Information."
	- Added line for Installomator version (both version and versiondate)
	- Added the option to hide Telephone, Email, and/or Help Website by setting their value to "hide."
	- Renamed default label from "Started" to "AAP Started" to clarify timestamp intent
	- Renamed default software-version labels for a unified look
- Updated webhooks for both Slack and Teams (PR #185)
	- Renamed "Microsoft Intune" to "Intune" to prevent the button text from being truncated.
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
- Added App Auto-Patch Script Self Update functionality (Feature Request #128)
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
- Added the ability to set a Monthly Patching Cadence (e.g., Patch Tuesday).
	- monthly_patching_cadence_enabled (TRUE|FALSE)
	- monthly_patching_cadence_ordinal_value: Week of the month you want AAP to be scheduled (first|second|third|fourth|fifth|final)
	- monthly_patching_cadence_weekday_index: Day of the week you want AAP to be scheduled (sunday|monday|tuesday|wednesday|thursday|friday|saturday)
	- monthly_patching_cadence_start_time: Local time you want AAP to be scheduled
 - New `restart_aap` function to handle all LaunchDaemon restart logic
 - Fixed a bug that would result in a "Print: Entry, ":userInterface:dialogElements", Does Not Exist" message if no language entries exist in the PLIST
 - Logging improvements

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
- Added --workflow-install-now-silent option which runs through the workflow without deferrals but does not display dialogs
- Added option to disable Installomator Updates using `<key>InstallomatorUpdateDisable</key>` `<string>TRUE,FALSE</string>`
- Added dialogTargetVersion and set to version 2.5.5 as the minimum required due to issues with the deferral menu on older versions

## Version 3.1.2
### 11-Apr-2025
- Fixed a bug that prevented the proper app name from populating for a small number of labels (Issue #140)
- Fixed a bug when using wildcards for ignored and required labels that could cause the label to skip being added (Issue #141)
- Fixed a bug that could prevent a label from being added if that label name matched part of a label in the ignoredLabelsArray (Issue #142)
- Fixed a bug to pull the correct label name for cases where the label fragments file contains multiple label references (ex, Camtasia|Camtasia2025) (Issue #143)
- Fixed a bug that prevented the proper app name and icon from populating for a small number of labels on the Patching Dialog (Issue #144)
- Fixed a bug that prevented Installomator from sending the proper status updates to the swiftDialogCommandFile (Issue #144)
- Updated syntax for some verbose logging
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
- Added exit_error function to handle startup validation errors
- Added the ability to pull from a custom Installomator fork. It must include all Installomator contents, including fragments
- Added logic to check for a successful App Auto Patch installation.
- Fixed logic for InteractiveMode to use the default if no option is set via MDM or command line
- Fixed logic for DaysUntilReset to use the default if no option is set via MDM or command line
- Fixed logic where the script was improperly shifting CLI options when running from Jamf and not using built-in parameter options (Issue #45)
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
- Changes to permissions for the command file for SwiftDialog 2.5.5+

## Version 3.0.0-beta5
### 22-Dec-2024
- Fixed a bug with the Days Since Patching Start Date logic that was causing it to be a day behind
- Added preference key to set the Dialog on top of other windows
- Added options to output version details
- Added logic for switching Installomator between Release and Main (beta) branches
- Set default branch to Main

## Version 3.0.0-beta4
### 14-Nov-2024
- Added logic for deferral-timer-menu to pull via MDM, local PLIST, or CLI trigger

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
