# CHANGELOG

# Version 3

## Version 3.8.0
### 08-Sep-2026 (1) - Build 3.8.0.2609081200
- Homebrew cask and formula support, ported from the `3.6.0_Homebrew` branch onto the 3.8.0 line and reworked for the machinery added since:
	- Outdated packages are queued as pseudo-labels (`brewcask__<name>` / `brewformula__<name>`) at the end of discovery, so deferral, hard deadlines, the unified dialog list, notifications, the Dock badge and `ExcludedBackgroundLabels` all apply to them without special-casing
	- Queue persisted in a dedicated `HomebrewDiscoveredPackages` array rather than `DiscoveredLabels`. `DiscoveredLabels` is read back through `tr -c -d "[:alnum:][:space:][\-_]"`, which strips `@`, `.` and `+` and would rewrite `brewformula__openssl@3` as `brewformula__openssl3` - a package name that does not exist. The new key is written and read with `PlistBuddy` only
	- `brew outdated --json=v2` is parsed with `plutil -convert xml1` piped into `PlistBuddy`. The source branch used an inline `/usr/bin/python3` heredoc, which on a managed Mac without the Xcode Command Line Tools is a stub that raises an install prompt from a root LaunchDaemon
	- Homebrew runs as the owner of the prefix (`stat -f %Su`), not as the console user the source branch assumed. Discovery is skipped when the prefix is root-owned, or owned by someone other than the console user, because running `brew` as a non-owner makes Homebrew rewrite permissions across the prefix
	- `brew update --quiet` runs before `brew outdated` (which does not auto-update), non-fatally; `brew upgrade` then runs with `HOMEBREW_NO_AUTO_UPDATE=1`
	- Membership tests use exact-element zsh subscripts throughout, so ignoring `node` no longer also ignores `node@22` - the same class of defect fix [#254](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/254) addressed elsewhere in the script
	- Fixed in the port: the source branch's `homebrew_discovery` had no closing brace, so `zsh -n` failed on the whole script; the local-preference fallbacks tested `-n` on the option instead of `-z`, so a saved local preference always beat the CLI flag; and the install log expanded `(cask)` for formulae as well
	- Fixed in the port: the superseded-label removal used `labelsArray=(${labelsArray:#${_sup}})`, but `labelsArray` is a scalar string at that point in `main()`, and `${scalar:#pattern}` is a whole-string anchored match rather than the per-element filter `${array:#pattern}` performs - so the block removed nothing while still logging that it had, and Installomator and Homebrew would both have patched the same application in the same run
	- New `resolve_label_display_name` replaces seven identical copies of the label-fragment `name=` lookup, and `resolve_app_icon_path` gained a Homebrew branch, so the display/icon call sites in `swiftDialogPatchingWindow`, `workflow_silent_patch_closed_apps`, `workflow_do_Installations` and `main()` needed no per-site changes
	- Staging is skipped for Homebrew packages; silent background patching upgrades them, except a cask whose application is currently running, which is left for the interactive dialog
	- The list of Installomator labels that Homebrew superseded is persisted in a second array key, `HomebrewSupersededLabels`, written and read with `PlistBuddy` alongside `HomebrewDiscoveredPackages`. Without it the list existed only in memory during discovery, so on a `DiscoveryFrequency`-skipped run it was empty while `main()` still re-added `RequiredLabels` / `ConvertedLabels` to the queue from the managed configuration - a restore path independent of `DiscoveredLabels`. The superseded application was then patched by Installomator and Homebrew in the same run. Both keys are cleared by `--reset-labels`
	- iMazing + Jamf manifests, All-Options examples and the Intune manifest updated

**Fixes**

- Fixed: `_resolve_label_staging_info` created its temporary wrapper script with `mktemp /private/tmp/aap_lbl_XXXXXX.sh`. BSD `mktemp` only substitutes `XXXXXX` when it is the final component of the template, so the trailing `.sh` left the placeholder literal and every invocation used the same fixed, world-guessable path in world-writable `/private/tmp`, written by a root LaunchDaemon. It also self-collided: any crash that skipped the `rm -f` left the file behind and made every later call fail with `mkstemp failed: File exists` until it was deleted by hand. The suffix has been removed so the path is randomised. Pre-existing since the staging workflow was introduced; not related to Homebrew support

## Version 3.7.1
### 02-Sep-2026 (1) - Build 3.7.1.2609021118
- [#267](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/267): Mosyle webhook device links no longer use `get_mdm()` enrollment `server_url` (e.g. `https://biz-1234.mosyle.com`). That host is the MDM check-in endpoint, not the admin console. `resolve_mosyle_console_base_url()` maps `biz-*` / `*business.mosyle*` to `https://mybusiness.mosyle.com` and other Mosyle enrollments to `https://my.mosyle.com`. Optional managed/CLI/local `MosyleConsoleURL` / `--mosyle-console-url=` overrides the host. Manifests, All-Options example, Intune XML, README, and wiki updated.

### 28-Aug-2026 (2) - Build 3.7.1.2608282112
- [#264](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/264): keep SystemConfiguration (`scutil State:/Users/ConsoleUser`) as the console-user source, but resolve the account from the ConsoleUser UID via `id -un` instead of trusting the `Name` field. That name can be a login alias (Jamf Connect / IDP) rather than the Directory Services RecordName, which then breaks `su`/`id` lookups. The `Name` parse uses the Scripting OS X pattern (`/^[[:space:]]*Name :/ && ! /loginwindow/ { print $3; exit }`) so loginwindow yields no GUI user. `id -un` failure falls back to the scutil `Name`. Shared helper `get_console_user_account_name()` covers `get_preferences`, `get_logged_in_user`, and the patching-dialog session checks. Verbose logging records a mismatch when Name and RecordName disagree.

### 28-Aug-2026 (1) - Build 3.7.1.2608282057
- [#264](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/264): first attempt used `/dev/console` ownership (`stat -f "%Su"`). Replaced in build `3.7.1.2608282112` so loginwindow vs root GUI sessions stay distinguishable.

## Version 3.7.0
### 19-Aug-2026 (3) - Build 3.7.0.2608191542
- Fixed: a live AAP run started as `sudo appautopatch …` was reported by `aap-starter` as `aap.pid points to live non-AAP PID`, which released the runtime markers and launched a second instance alongside the first (duplicate deferral dialogs). PID ownership is now matched on the program AAP was invoked as (`appautopatch` entrypoint or `App-Auto-Patch-via-Dialog.zsh`) after skipping `sudo`/interpreter arguments, in both `aap-starter` and the script's own startup, uninstall, and `--stop` checks
- Added: `aap-starter` and the script accept a heartbeat record naming the recorded live PID as proof of AAP ownership, so an unrecognized invocation path can no longer release an active run's markers. The record is only trusted when the process started at or before the record was written and the record has not expired past `StaleProcessTimeoutSeconds`, so a reused PID is never mistaken for the run that wrote it. A process with an expired heartbeat that the command-line check cannot confirm has its markers released without being signaled
- Added: startup now terminates any other live AAP instance that is running without runtime markers (skipping itself and its own ancestors), so a lost or released PID file cannot leave two instances patching and prompting at once
- Fixed: runtime cleanup of abandoned `dialog.appAutoPatch.*` command files no longer deletes the command file created by the current instance
- Fixed: a one-shot `--workflow-discovery-only` run on a scheduled-discovery Mac replaced the still-future discovery date it interrupted with a freshly computed one, resetting the cadence to the manual run. The saved date is now restored when it is still in the future; missing, disabled, and overdue values still get a newly computed date
- Fixed: a headless discovery run ended by `TERM`/`INT`/`HUP` (stale-process recovery, orphan cleanup, `--stop`) left `NextAutoLaunch` unset in scheduled-discovery mode, so the LaunchDaemon retried discovery on its next 60-second tick instead of honoring `DiscoveryFrequency`. Signal cleanup now finalizes the discovery schedule the same way a controlled error exit does. Other workflows keep the existing crash-recovery behavior of relaunching promptly

### 19-Aug-2026 (2) - Build 3.7.0.2608191343
- [#258](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/258): added a discovery-only scheduling mode for user-driven installation:
	- New managed/local boolean `WorkflowScheduledDiscovery` (default `false`). When paired with `WorkflowDisableRelaunch=true`, `aap-starter` continues scheduled headless runs based on `DiscoveryFrequency` instead of treating `NextAutoLaunch=FALSE` as a permanent stop
	- Discovery-only runs refresh `DiscoveredLabels` and the report PLIST, optionally stage installers via `WorkflowStageUpdates`, optionally send the queued-app notification, and schedule the next discovery
	- Discovery-only runs bypass patch-cycle completion status, Business Hours, silent closed-app patching, deferral/focus/hard-deadline evaluation, and all installation UI. Explicit pending-apps / Install Now workflows take priority and continue to install normally
	- New one-shot CLI `--workflow-discovery-only` forces an immediate headless discovery/report refresh, survives Jamf/out-of-folder restart via `.WorkflowDiscoveryOnly`, and preserves the schedule it interrupted in a root-only sidecar. Network-error deferrals retain the request without retrying every 60 seconds; crash recovery resumes it immediately
	- `WorkflowDisableAppDiscovery` remains authoritative. `DiscoveryFrequency=0` uses `DeferralTimerWorkflowRelaunch` (minimum two minutes) for scheduled discovery to avoid a 60-second LaunchDaemon loop
	- Normal install completion and `--stop` preserve scheduled-discovery mode instead of replacing its next date with the disabled `FALSE` sentinel. `--stop` also disarms a running one-shot and restores its interrupted schedule
	- Jamf/iMazing manifests, all-options examples, Intune/migration references, Support App documentation, README, and user-facing changelog updated

### 19-Aug-2026 (1) - Build 3.7.0.2608191153
- Changed: `--windowbuttons min` is now set on every interactive swiftDialog window (deferral, hard deadline, pending-apps, Install Now confirmation, up-to-date mini, and Dock Quit recovery prompts), matching discovery/staging/patching

### 19-Aug-2026 (1) - Build 3.7.0.2608191132
- Process supervision and discovery/staging Dock Quit policy:
	- New managed/local key `StaleProcessTimeoutSeconds` (integer, default `3600`). `0` disables timeout-based stale-process killing; any other value below `300` is raised to `300`. Dead/reused PID cleanup still runs when the timeout is disabled
	- Heartbeat file (`/var/run/aap.heartbeat`) plus PID-identity validation so `/var/run/aap.pid` cannot pin a recycled PID as a live AAP run. The record is a single tab-delimited `pid`/`epoch`/`phase` line; phase text is collapsed to one line and truncated so label-derived values cannot corrupt the format
	- Stale-process recovery is logged graceful `TERM` then `KILL` if the process does not exit
	- Staging `curl` downloads abort on a no-data timeout instead of hanging indefinitely
	- New CLI `--stop` ends a live run and preserves the existing `NextAutoLaunch` schedule
	- New managed/local key `DialogQuitHandlingDiscoveryStaging` (`PROMPT`|`CONTINUE`|`STOP`, default `PROMPT`). Discovery/staging Dock Quit / ⌘Q: **PROMPT** offers Keep Running vs Stop App Auto-Patch; **CONTINUE** keeps the workflow running with no prompt; **STOP** exits cleanly until the next scheduled run. Stop is ignored when `is_hard_deadline_due_lightweight` is true or Install Now / pending-apps Install Now is in progress — the workflow continues instead. `sudo appautopatch --stop` remains an admin escape hatch.
	- A stop or termination during discovery restores the last complete pending-app report instead of leaving a partially rebuilt queue
	- Localizable `dialogElements` keys: `display_string_preparationdismissed_message`, `display_string_preparationdismissed_button1` (default `Keep Running`), `display_string_preparationdismissed_button2` (default `Stop App Auto-Patch`)

### 16-Aug-2026 (15) - Build 3.7.0.2608161645
- Changed: `--preview-deferral-dialog` no longer rewrites `NextAutoLaunch`. Like `--pending-apps-dialog` Later, it is a cosmetic one-shot UI — both Install Now and Defer remain no-ops for patching, and the existing LaunchDaemon schedule is preserved (with the same overdue/missing fallback so the 60s StartInterval cannot spin). Startup and `manage_parameter_options` now skip clearing a real `NextAutoLaunch` for both one-shot UI paths; the shared exit helper was renamed to `_exit_one_shot_ui_preserving_schedule`

### 16-Aug-2026 (14) - Build 3.7.0.2608161632
- Fixed: `--pending-apps-dialog` **Later** still lost the existing `NextAutoLaunch` — build (13) only guarded the crash-recovery delete in `workflow_startup`, but `manage_parameter_options` deletes the key again in its `WorkflowDisableRelaunch == FALSE` branch (there to clear the `FALSE` sentinel when relaunch is re-enabled). That ran after the guard, so a deferral already in place (e.g. 30-minute defer → 17:05) was wiped and Later fell through to the fallback, writing a fresh `DeferralTimerDefault` / monthly-cadence date (Business-Hours clamped) instead of keeping 17:05
	- For pending-apps dialog runs that branch now only deletes `NextAutoLaunch` when it holds the `FALSE`/`0` disable sentinel; any real date is preserved (logged via `log_verbose`)

### 16-Aug-2026 (13) - Build 3.7.0.2608161535
- Fixed: `--pending-apps-dialog` no longer leaves `NextAutoLaunch` unset after **Later** / “all up to date”, which caused the LaunchDaemon (`StartInterval` 60s) to relaunch AAP almost immediately:
	- Startup’s crash-recovery `defaults delete NextAutoLaunch` is skipped when `pending_apps_dialog_option` is TRUE, so an existing future schedule (Business Hours clear time, monthly cadence, normal deferral) or `WorkflowDisableRelaunch` sentinel survives the dialog
	- Later / up-to-date dismissals now call `_exit_pending_apps_dialog_preserving_schedule`: keep a future (or disabled) `NextAutoLaunch`; if missing/overdue, reschedule via monthly cadence or `set_auto_launch_deferral`
	- Install Now still clears `NextAutoLaunch` before continuing in-process so a mid-install crash re-arms LaunchDaemon relaunch; completion paths write a fresh schedule as usual

### 14-Aug-2026 (12) - Build 3.7.0.2608141655
- Logging overhaul (logging plumbing from the runtime deep dive):
	- `aap_verbose.log` is now written only when `VerboseMode` is TRUE. When FALSE, nothing is appended to the verbose log (including `log_verbose` call sites that previously always wrote, the swiftDialog notification handoff, and the Installomator fragment `log_location`)
	- `aap.log` no longer receives `[VERBOSE]` lines at all. Previously, enabling `VerboseMode` routed VERBOSE output through `log_aap` and into the main log; verbose output now goes only to `aap_verbose.log` (and stdout), keeping `aap.log` to regular workflow output regardless of `VerboseMode`
	- When `VerboseMode` is TRUE, `aap_verbose.log` receives both the normal `log_aap` stream (INFO/NOTICE/STATUS/ERROR/…) and the `[VERBOSE]` lines, so it remains a complete troubleshooting transcript
	- Fixed: every `log_verbose` call wrote two identical lines to `aap_verbose.log` (once via `log_aap`, once via its own direct append), which is why verbose logs contained duplicate pairs tagged `log_aap[pid]` and `log_verbose[pid]`
	- `VerboseMode` is resolved at the start of `workflow_startup` (managed → CLI → local) so the gate applies for the whole run, including early preference dumps
	- Cached log identity (`hostname` / script name) and kept append FDs open for `aap.log` / `aap_verbose.log`; timestamps use zsh built-in `%D` instead of spawning `date`/`hostname`/`basename` per line. `archive_logs` reopens FDs after moving a live log path
	- Changed: the process tag in each log line is now the script name (e.g. `App-Auto-Patch-via-Dialog.zsh[pid]`) instead of the logging function name (`log_aap[pid]` / `log_verbose[pid]`). Inside a zsh function, `$0` expands to the function name, so the old prefix reported the logger rather than the script; the new tag matches the `aap-starter` LaunchDaemon line format
	- Removed per-tick `log_verbose` from `swiftDialogUpdate` (UI command-file writes are high-frequency, low diagnostic value)

### 13-Aug-2026 (11) - Build 3.7.0.2608132043
- Changed: pending-apps Install Now now goes straight to the patching dialog, skipping the pre-staging pass (`workflow_stage_updates`), the staging/background mini progress window, and the silent background closed-app patch (`workflow_silent_patch_closed_apps`). Both passes only exist to prepare for — or avoid — a later interactive prompt, which is pointless once the user has explicitly asked for the install. Installers staged when the apps were first queued are still reused by `workflow_do_Installations`; anything unstaged is downloaded during the install as usual

### 13-Aug-2026 (10) - Build 3.7.0.2608131944
- Fixed: pending-apps Install Now now clears any stale silent install-now intent (`workflow_install_now_silent_option` / `.WorkflowInstallNowSilent`) when the interactive locked-queue path is armed or restored — so ExcludedBackgroundLabels the user confirmed in the dialog are not dropped by `filter_excluded_background_labels_from_silent_install`

### 13-Aug-2026 (9) - Build 3.7.0.2608131938
- Fixed: a pending-apps dialog that can't be shown can no longer fall through to an unconfirmed install:
	- The one-shot `.PendingAppsDialog` flag is now consumed inside `workflow_pending_apps_dialog` only after swiftDialog is confirmed present (instead of in `main()` before the call), so a missing-swiftDialog `exit_error` leaves the request armed to retry on the next LaunchDaemon cycle
	- The dialog now supersedes any Install Now intent left armed by an earlier network-deferred Install Now (clears `.PendingAppsInstallNow` / `.WorkflowInstallNow` and the in-memory flags at entry), re-arming only if the user actually clicks Install Now — so re-presenting the dialog can't be bypassed and a failed dialog can't silently install a locked queue with no confirmation

### 13-Aug-2026 (8) - Build 3.7.0.2608131926
- Fixed: `--reset-defaults` no longer leaves pending-apps one-shot state armed — the early `.PendingAppsDialog` restore at the top of `workflow_startup` is skipped on a reset run, and the reset block now also clears the in-memory flags (`pending_apps_dialog_option`, `pending_apps_install_now_option`, `workflow_install_now_option`, `workflow_install_now_silent_option`, `force_discovery_option`), not just the flag files
- Fixed: pending-apps Install Now now writes `.PendingAppsInstallNow` before `.WorkflowInstallNow`, so a crash between the two touches re-arms the report-locked queue on the next run instead of a plain `--workflow-install-now` that would merge the full discovery queue

### 13-Aug-2026 (7) - Build 3.7.0.2608131914
- Fixed: report entries excluded by `IgnoredLabels` policy are now pruned from the report PLIST and `DiscoveredLabels` (via `remove_aap_report_item` / `remove_discovered_label`) instead of only being hidden from the pending-apps dialog. Previously the Support App tile count, banner `{count}` text, and the report itself kept advertising pending updates that policy would never install — so a user could see "3 pending" and then get the "all up to date" mini dialog. These are stale entries from a discovery run that predates the current IgnoredLabels configuration; pruning applies in both the dialog and the locked Install Now queue

### 13-Aug-2026 (6) - Build 3.7.0.2608131905
- Pending-apps dialog now honors the same `IgnoredLabels` policy as a normal run, so the list shown and the list patched always match:
	- New `_load_effective_label_policy` / `_label_allowed_by_policy` helpers merge the in-memory option arrays with the persisted local PLIST values (where wildcard `IgnoredLabels` patterns are expanded), and are used by both the dialog and the locked install queue
	- Fixed: with `IgnoredLabels` set to `*`, the dialog listed every report entry and Install Now could patch apps outside the required/optional allow-list — ignore-all mode is now applied in both places
	- Fixed: the locked report queue no longer runs a bare `${labelsArray:|ignoredLabelsArray}` subtraction, which could silently drop apps the user had just approved (leaving AAP to report "up to date" without patching them). Excluded apps are now filtered out before the dialog is drawn instead
- Fixed: `--pending-apps-dialog` restored from `.PendingAppsDialog` after a Jamf / out-of-folder relaunch now applies the dialog's fast paths — the flag file is read at the very start of `workflow_startup` (before `get_preferences` / `manage_parameter_options`), so the run no longer does a full `get_installomator` network pass before showing the dialog

### 13-Aug-2026 (5) - Build 3.7.0.2608131852
- Fixed: choosing **Later** (or dismissing) on the pending-apps dialog now clears leftover `.PendingAppsInstallNow` / `.WorkflowInstallNow` flags, so a prior Install Now that deferred for network cannot force an install-now run on the next LaunchDaemon launch

### 13-Aug-2026 (4) - Build 3.7.0.2608131847
- Fixed: `--pending-apps-dialog` invoked via Jamf (or any path that triggers `restart_aap`) no longer drops the dialog request — new one-shot flag file `.PendingAppsDialog` persists across the LaunchDaemon relaunch (same pattern as `--force-discovery` / `--workflow-install-now`) and is consumed when the dialog is shown

### 13-Aug-2026 (3) - Build 3.7.0.2608131837
- Pending-apps Install Now Bugbot fixes:
	- Install queue is now locked strictly to report PLIST `ItemsToInstall` (the list shown in the dialog). RequiredLabels / ConvertedLabels / DiscoveredLabels extras are no longer merged in, so Install Now cannot patch apps the user never saw
	- Intent survives restart/network defer via new flag file `.PendingAppsInstallNow` (restored in `workflow_startup` alongside `.WorkflowInstallNow`); cleared on install completion, all-up-to-date, and reset-defaults

### 13-Aug-2026 (2) - Build 3.7.0.2608131813
- Pending-apps dialog **Install Now** now runs the install in-process instead of spawning a second `appautopatch --workflow-install-now`:
	- On Install Now, `workflow_pending_apps_dialog` sets install-now flags (`workflow_install_now_option`, `InteractiveMode 2`) plus a new `pending_apps_install_now_option`, then returns to `main()` so the normal install-now workflow patches the queue in-process (staging → silent closed-app patch → `workflow_do_Installations` → shared completion / webhook / relaunch)
	- `pending_apps_install_now_option` forces `run_discovery=FALSE` in `main()`, so AAP patches exactly the queue the user saw (hydrated from the report PLIST / `DiscoveredLabels`) with no fresh discovery scan
	- The network wait and `get_installomator` check (both skipped while the dialog is shown for speed) now run in-process before installing; if the network never comes up, AAP defers cleanly instead of installing
	- Network detection factored into `workflow_wait_for_network` and shared with `workflow_startup` (identical behavior; no duplicated loop)
	- Single process now handles the whole flow — no second `appautopatch` launch, and no stale report count from a detached background run

### 13-Aug-2026 (1) - Build 3.7.0.2608131411
- Queued-apps notification **Install Now** now opens the pending-apps dialog instead of jumping straight to `--workflow-install-now`:
	- New CLI: `--pending-apps-dialog` — same dialog for manual / MDM / Support App triggers (reads report PLIST only; no discovery)
	- Dialog lists pending apps with icons + Current/New version subtitles; **Later** dismisses; **Install Now** kicks off the install (see the 13-Aug (2)/(3) entries above — this originally backgrounded `--workflow-install-now`, later changed to an in-process install with a locked report queue)
	- WatchPaths trigger migrated to `xyz.techitout.aap.pendingAppsDialogTrigger` / `Triggers/PendingAppsDialog` (legacy InstallNow daemon cleaned up on startup)
	- Language key `display_string_pendingapps_button_later` (default `Later`); Support App `aap_pending_apps_dialog.zsh` is now a thin wrapper around the CLI
	- Skips Business Hours gate, network wait, and Installomator update check (when fragments already present) so the dialog stays near-instant

### 12-Aug-2026 (8) - Build 3.7.0.2608122211
- Split banner notification prefs: renamed `ShowNotifications` → `ShowNotificationsAll` (default `true`, master switch) and added per-type opt-in keys used only when All is false:
	- `ShowNotificationsSilentUpdated` — silent closed-app “updated {count}…” banner
	- `ShowNotificationsAppsQueued` — pending updates with Install Now / Dismiss
	- `ShowNotificationsSilentAndQueued` — combined Silent During “{count} updated… {remaining} queued” banner
	- When All is true alongside any individual key, All wins and every type is shown
	- Legacy managed/local `ShowNotifications` is still read as All; local legacy key is deleted after migration
	- CLI: `--show-notifications-all` / `-off` (aliases `--show-notifications` / `-off`) plus per-type flags; iMazing + Jamf manifests and All-Options examples updated

### 12-Aug-2026 (7) - Build 3.7.0.2608121738
- InteractiveMode 2 staging / background closed-app patch mini dialog now shows determinate progress and per-app status (mirrors the main patching dialog):
	- Progress bar advances by queued app count instead of bouncing indefinitely
	- Progress text shows the current app (`Staging Google Chrome …` / `Installing Google Chrome …`) and swaps the dialog icon to that app
	- Skipped apps (already staged, excluded, open/blocked) still advance the bar so it never stalls
	- Default `display_string_silent_patch_progress` shortened to `Installing` so the app name fits cleanly; staging prefix remains `Staging`
	- iMazing + Jamf language-string descriptions updated

### 12-Aug-2026 (6) - Build 3.7.0.2608121710
- Fixed banner notifications never appearing when AAP runs from its LaunchDaemon. swiftDialog 3.1 delivers notifications through helper apps (`Dialog Banner.app` / `Dialog Alert.app`) that run in the **calling** context — unlike dialog windows, which `dialogcli` relaunches as the console user. Launched as root the helper cannot reach the user's notification service (`Getting notification settings failed … com.apple.usernotifications.listener was invalidated`) and silently displays nothing:
	- `send_aap_notification` now hands off to the console user's GUI session via `launchctl asuser "${currentUserID}" sudo -u "${currentUserAccountName}"` when running as root
	- swiftDialog output is appended to the verbose log instead of `/dev/null`, so errors like `Notifications are not available: Couldn't communicate with a helper application` are visible
	- Notification approval is per helper bundle ID on swiftDialog 3.1+: `au.csiro.dialog.notifier.banner` (banner) and `au.csiro.dialog.notifier.alert` (alert); `au.csiro.dialog` covers 2.3–3.0

### 12-Aug-2026 (5) - Build 3.7.0.2608121636
- Separated Business Hours discovery from notifications: new `BusinessHoursAllowDiscovery` (default `false`) controls whether discovery runs during Business Hours when `BusinessHoursSilentDuring` is off. `ShowNotifications` only controls banners.
	- Default `false` restores historical immediate defer (no discovery) during Business Hours
	- When `true`: run discovery then defer; banner pending apps only if `ShowNotifications` is also on
	- Managed key `BusinessHoursAllowDiscovery`; CLI `--business-hours-allow-discovery` / `--business-hours-allow-discovery-off`
	- iMazing + Jamf manifests and All-Options examples updated

### 12-Aug-2026 (4) - Build 3.7.0.2608121628
- Banner-style swiftDialog notifications (`--notification --style banner`), enabled by default via `ShowNotifications`:
	- After successful silent closed-app patching: notify that `{count}` apps were updated in the background
	- During Business Hours without `BusinessHoursSilentDuring`: when `BusinessHoursAllowDiscovery` and `ShowNotifications` are both on, notify that `{count}` apps require updates with **Install Now** / **Dismiss**
	- During Business Hours with SilentDuring after silent patch: notify `{count}` updated and `{remaining}` still queued (Install Now when remaining &gt; 0)
	- Install Now uses a user-writable Triggers WatchPaths LaunchDaemon (`xyz.techitout.aap.installNowTrigger`) to start `--workflow-install-now` as root
	- Managed key `ShowNotifications`; CLI `--show-notifications` / `--show-notifications-off`
	- Localizable `dialogElements` keys added to iMazing + Jamf manifests: `display_string_notification_silent_updated`, `display_string_notification_apps_queued`, `display_string_notification_silent_and_queued`, `display_string_notification_button_install`, `display_string_notification_button_dismiss`

### 12-Aug-2026 (3) - Build 3.7.0.2608121613
- Handle the user quitting a dialog window so dismissing it no longer has unexpected side effects. swiftDialog documents exit code `10` for cmd+quitkey, but Dock ▸ Quit and the menu bar Quit terminate `Dialog.app` itself, so `dialogcli` returns the raw signal instead — `15` for Quit and `9` for Force Quit. AAP now treats `9`, `10`, `15`, `137`, and `143` as a user dismissal:
	- Deferral and hard-deadline dialogs reopen instead of treating Quit as Install Now
	- Install Now confirmation treats Quit as “Go Back”
	- If the backgrounded patching progress dialog is Quit’d, prompt with **Show Progress** (relaunches the list, preserving completed item status) or **Continue in Background**
	- Discovery/staging dialogs that were already Quit’d are logged and skipped cleanly on completion
	- New localizable strings (config profile / dialogElements): `display_string_dialogdismissed_message`, `display_string_dialogdismissed_button1`, `display_string_dialogdismissed_button2` — added to iMazing + Jamf manifests

### 12-Aug-2026 (2) - Build 3.7.0.2608121500
- Show the App Auto-Patch logo as a macOS Dock icon for workflow swiftDialog windows (`--dockicon`), when swiftDialog 3.0+ is installed ([docs](https://swiftdialog.app/advanced/command-line-options/)):
	- Managed key `ShowDockIcon` (`true`/`false`, default `true`); CLI `--show-dock-icon` / `--show-dock-icon-off`
	- Deferral / hard-deadline dialogs badge the Dock icon with the number of pending updates (`--dockiconbadge`)
	- Installation (patching) dialog starts with that count and counts the badge down as each update finishes
	- Discovery, staging, Install Now confirmation, and “all apps up to date” dialogs also show the AAP Dock icon (no badge)
	- Left gated on swiftDialog major ≥ 3 so macOS 12–14 fleets on 2.5.x keep working without unknown-flag failures
	- iMazing + Jamf manifests and All-Options examples updated

### 12-Aug-2026 (1) - Build 3.7.0.2608120015
- [#256](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/256): optional `SkipPreUpdateVerification` to bypass the local Gatekeeper (`spctl -a`) / Team ID check in `verifyApp()` during discovery:
	- Some already-installed apps fail `spctl` assessment intermittently, which previously logged `Error verifying` and returned early — excluding the app from discovery/updates entirely even though Installomator would still validate post-download
	- Managed key `SkipPreUpdateVerification` (`true`/`false`, default `false`); CLI `--skip-pre-update-verification` / `--skip-pre-update-verification-off`
	- When enabled, discovery logs a warning and continues to version comparison / queueing; Installomator validation after download is unchanged
	- iMazing + Jamf manifests and All-Options examples updated

### 11-Aug-2026 (2) - Build 3.7.0.2608112305
- [#166](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/166): replaced the allow-list `ScheduleWorkflowActive` model with **BusinessHours** blocked windows (do-not-disturb hours):
	- Managed key `BusinessHours` = `DAY:hh:mm-hh:mm,...` (`MON`–`SUN`, 24-hour, comma-separated). Empty/unset = always allowed. Local Mac timezone; same-day ranges only (overnight = two windows)
	- Multiple windows per day are first-class — e.g. `MON:09:00-11:59,MON:13:00-17:00` blocks morning and afternoon but leaves lunch clear for patching
	- Early gate after prefs/validation + install-now flags, before Jamf restart / network / discovery: **during** BusinessHours → set `NextAutoLaunch` to the next clear time (with a small bump if &lt; ~5 minutes away) and `exit_clean` — no interactive discovery/dialogs/Installomator/webhooks — unless Silent During is enabled
	- **Intentionally bypassed** by `--workflow-install-now`, `--workflow-install-now-silent`, and `--preview-deferral-dialog` so admins can force a run on demand
	- Default: overdue hard deadline (days or count) bypasses BusinessHours via a lightweight read-only check. Optional `BusinessHoursRespectHardDeadline` (`true` = even hard deadlines wait until clear). Soft/focus deadlines still respect BusinessHours
	- `BusinessHoursSilentDuring` (default `false`): when `true` and during BusinessHours, continue with discovery and `workflow_silent_patch_closed_apps` only — no dialogs even if InteractiveMode is 1/2. Open/blocked apps remaining after that pass are deferred until BusinessHours clear
	- All `NextAutoLaunch` writers (`set_auto_launch_deferral`, `set_auto_launch_monthly_cadence`) clamp outside BusinessHours when configured
	- Invalid schedule string fails startup validation (`option_error`)
	- CLI: `--business-hours=` / `--business-hours-respect-hard-deadline` / `-off` / `--business-hours-silent-during` / `-off`
	- Legacy local keys `ScheduleWorkflowActive*` are deleted on startup when prefs are managed
	- iMazing + Jamf manifests and All-Options examples updated

### 11-Aug-2026 (1) - Build 3.7.0.2608091723
- Hardened the `AAP-JamfProEAs/AAP-LatestPatches.sh` Jamf Pro extension attribute for `jamf recon`: replaced NUL-delimited `read -d ''` / process substitution with a newline `find` listing written to a temp file (avoids EA stalls when Jamf keeps stdin open), always emits `<result>` (no `set -e`), and keeps the existing Success/Failure output format

### 09-Aug-2026 (2) - Build 3.7.0.2608091723
- Changed: when no custom dialog icon is set, the SF Symbol fallback is logged at info (`Using SF symbol for App Icon`) instead of a warning that claimed the icon was "not found" — an empty icon is expected in that path, so the warning was a false alarm

### 09-Aug-2026 (1) - Build 3.7.0.2608091230
- [#166](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/166): earlier allow-list `ScheduleWorkflowActive` / SilentOutside implementation (superseded by BusinessHours in build `3.7.0.2608112305`):
	- Managed key `ScheduleWorkflowActive` = `DAY:hh:mm-hh:mm,...` (`MON`–`SUN`, 24-hour, comma-separated). Empty/unset = always active (unchanged behavior). Local Mac timezone; same-day ranges only (overnight = two windows)
	- Early gate after prefs/validation + install-now flags, before Jamf restart / network / discovery: outside a window → set `NextAutoLaunch` to next window start (with a small bump if &lt; ~5 minutes away) and `exit_clean` — no discovery, dialogs, Installomator, or webhooks — unless Silent Outside is enabled
	- Bypass: `--workflow-install-now`, `--workflow-install-now-silent`, `--preview-deferral-dialog`
	- Default: overdue hard deadline (days or count) bypasses the window via a lightweight read-only check (does not mutate deadline counters / does not sleep). Optional `ScheduleWorkflowActiveRespectHardDeadline` (`true` = even hard deadlines wait for the next window). Soft/focus deadlines still respect the window
	- `ScheduleWorkflowActiveSilentOutside` (default `false`): when `true` and outside a window, continue with discovery and `workflow_silent_patch_closed_apps` only — no dialogs even if InteractiveMode is 1/2. Open/blocked apps remaining after that pass are deferred to the next window start. Independent of `WorkflowBackgroundPatchClosedApps` for this outside-window path
	- All `NextAutoLaunch` writers (`set_auto_launch_deferral`, `set_auto_launch_monthly_cadence`) clamp into the next allowed window when a schedule is configured
	- Invalid schedule string fails startup validation (`option_error`)
	- CLI for testing: `--schedule-workflow-active=` / `--schedule-workflow-active-respect-hard-deadline` / `-off` / `--schedule-workflow-active-silent-outside` / `-off`
	- iMazing + Jamf manifests and All-Options examples updated

### 08-Aug-2026 (3) - Build 3.7.0.2608081505
- [#254](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/254): fixed ignored labels being disregarded, and the local preference plist intermittently reading back blank. Both were reproducible from a single verbose log in which discovery issued 1,159 `PlistBuddy` writes, logged zero ignore matches, and then queued an explicitly ignored app:
	- **`IFS` leak out of discovery.** The label-fragment parser sets `IFS=$'\n'` and never restored it. Everything downstream in `main()` then ran with a newline `IFS`: the `" ${ignoredLabelsArray[*]} "` substring test could only ever match the first and last elements, the `$(... | tr '\n' ' ')` dedupe steps collapsed each label list into one whitespace-padded element, and `${labelsArray:|ignoredLabelsArray}` therefore compared `"firefox "` against `"firefox"` and removed nothing. Runs that skipped discovery (`DiscoveryFrequency`) never set `IFS` and behaved correctly, which is why the failure appeared to alternate between runs. `IFS` is now saved before the parser and restored the moment the fragment loops finish
	- **Ignore membership tests.** The two `" ${array[*]} "`/`" ${array[@]} "` substring checks (discovery loop and `queueLabel`'s caller) are replaced with zsh exact-element subscripts, `(( ${array[(Ie)$item]} ))`. These are independent of `IFS` and can't partial-match a label name
	- **`IgnoredLabels="*"` no longer expands.** Previously `*` was globbed against `${fragmentsPath}/labels` and every resulting label was written to the local plist individually - ~1,200 `PlistBuddy add` calls per run against a file that the rest of the script reads with `defaults`. That volume left `cfprefsd`'s cache out of sync with the on-disk file, so `defaults read` returned an empty string for keys that were demonstrably present (`AAPPatchingStartDate`, `AAPPatchingCompletionStatus`), which fed an empty string to `strftime -r` and produced `Days Since Patching Start Date: 20668` - past `DaysUntilReset`, so the patching cadence reset on every affected run. A bare `*` is now recognised in `get_preferences()`, recorded as the single in-memory flag `ignore_all_labels`, and persisted as one `*` entry. **No configuration change is required** - `IgnoredLabels="*"` keeps its meaning of "ignore everything except `RequiredLabels` and `OptionalLabels`"; only the implementation changed. Partial wildcards (`microsoft*`) still expand as before
	- **Ignore-all enforcement moved in-memory.** Discovery skips any label that isn't required or optional when `ignore_all_labels` is set, and the queue is filtered the same way after the `:|` subtraction (which can't do the work itself now that the plist holds `*` rather than an entry per label)
	- **Required labels are protected from wildcards.** The wildcard expansion skipped labels listed as Optional but not those listed as Required, so `IgnoredLabels="*"` (or any wildcard covering them) put required apps into the ignored list and `${labelsArray:|ignoredLabelsArray}` then dropped them from the queue - required apps were never patched. `RequiredLabels` is now checked alongside `OptionalLabels`, against the in-memory array since `RequiredLabels` hasn't been written to the plist yet at that point
	- **Hardened local preference reads.** New `read_local_preference()` reads a key with `defaults` and falls back to `PlistBuddy` when the value comes back empty, normalising `true`/`false` to `1`/`0` so existing comparisons are unaffected. `check_completion_status()` uses it for `AAPPatchingCompletionStatus` / `AAPPatchingStartDate`, validates the start date against `^\d{4}-\d{2}-\d{2}` (trimming a full timestamp to the date), and falls back to the computed patch week start date - logging an error and rewriting the key - rather than handing an empty string to `strftime`
	- **Label list parsing.** New `parse_labels_option()` normalises a labels preference into an array, stripping the parentheses, quotes, and trailing commas that `defaults read` emits for array-typed preferences. Previously those became label names in their own right, visible in the log as `Required labels: ( )`

### 08-Aug-2026 (2) - Build 3.7.0.2608081108
- [#156](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/156): optional pre/post patch script hooks for workflows like `jamf recon` or fixing `.app` ownership after Installomator installs. Security-hardened by design:
	- Managed preferences only (`PrePatchScript` / `PostPatchScript`) - never CLI, never written to / read from the local preference plist, never `eval`'d or run via `bash -c`
	- Script path must be absolute, under `/Library/Management/AppAutoPatch/Hooks/` (created root:wheel `755` on install), must not contain `..`, must not be a symlink, must be a regular executable file owned by root, and must not be group/world-writable (parent directory checked the same way)
	- Direct exec of the validated path with a timeout (`PatchScriptTimeoutSeconds`, default 300); env context exported as `AAP_HOOK`, `AAP_QUEUED_LABELS`, `AAP_SERIAL`, `AAP_ERROR_COUNT`, etc.
	- `PrePatchScriptFailAction` default `ABORT` (skip installs / exit); `PostPatchScriptFailAction` default `CONTINUE`
	- Pre runs once per patch run (shared across Background Patch Closed Apps + `workflow_do_Installations`); post runs once after the last install pass for that run
	- iMazing + Jamf manifests and All-Options examples updated

### 08-Aug-2026 (1) - Build 3.7.0.2608081041
- [#240](https://github.com/App-Auto-Patch/App-Auto-Patch/pull/240): Mosyle MDM support (based on @salzstreuer89's PR, with maintainer adjustments):
	- `get_mdm()` recognizes `*mosyle*` enrollment ServerURLs and sets `mdmName="Mosyle"`
	- Slack and Teams webhooks include a "View in Mosyle" device deep-link using Hardware UUID (`IOPlatformUUID`) as `#device_<uuid>`
	- Console host prefers the enrolled MDM `server_url` from `get_mdm()`, falling back to `https://business.mosyle.com` instead of the PR's org-specific `https://mybusiness.mosyle.com`
	- Mosyle URL is resolved once at the start of `webHookMessage()` and reused for both Slack and Teams
	- Overlay icon chain also checks `/Applications/Mosyle Self Service.app` (Self-Service.app / Manager.app were already covered for some Mosyle installs)
	- Also fixed pre-existing Teams webhook gap: Workspace One device links now resolve on Teams the same as Slack

### 04-Aug-2026 (2) - Build 3.7.0.2608040927
- Changed: the Dock-active wait in `workflow_startup()` no longer exits the script when no user session appears (ported from 3.6.3). It still waits briefly (now 20 seconds, down from 120) for the Dock to become active, but if it never does, AAP logs that it's continuing without an active user session and proceeds - some admins intentionally run AAP before anyone is logged in, and the previous `exit 1` after 120 seconds blocked that entirely. When the Dock is not active after that wait, `get_dialog()` is also skipped (the same as fully-silent runs), since swiftDialog can't safely present UI without an active user session. Fully-silent runs (`InteractiveMode 0`, or `--workflow-install-now-silent`) still skip the Dock wait entirely as before

### 04-Aug-2026 (1) - Build 3.7.0.2608040659
- [#249](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/249): optional GitHub REST API authentication so large fleets (and custom Installomator forks) don't hit the unauthenticated 60 requests/hour rate limit when AAP looks up Installomator / swiftDialog on `api.github.com`. Managed preferences only:
	- `GitHubAPIAuthEnabled` (`TRUE`/`FALSE`, default `FALSE`) - master switch
	- `GitHubAPIToken` - GitHub personal access token (classic or fine-grained); sent as `Authorization: Bearer` per [GitHub's REST auth docs](https://docs.github.com/en/rest/authentication/authenticating-to-the-rest-api)
	- When auth is enabled, `GitHubAPIToken` is required - blank/missing fails startup validation immediately (before any `api.github.com` call)
	- Token is never written to the local preference plist, never accepted via CLI, and is redacted from verbose managed-preference dumps (only length is logged when auth is on)
	- Applied to every existing `api.github.com` curl in `install_dialog()` / `get_installomator()`; download URLs on `codeload.github.com` / `raw.githubusercontent.com` / `github.com` are unchanged (those aren't the rate-limited REST API)

### 03-Aug-2026 (2) - Build 3.7.0.2608032255
- Added: `--preview-deferral-dialog` CLI trigger - shows the real deferral dialog populated with sample apps/icons/version subtitles so admins can iterate on `BannerImage`/`BannerTitle`/`BannerHeight` (and other dialog cosmetics) without running discovery or installing anything. Both Install Now and Defer are no-ops for patching; the only side effect is rescheduling the next LaunchDaemon run using the configured default deferral timer. Works even when `InteractiveMode` is 0 (the preview forces a non-silent path so swiftDialog is still checked/installed)

### 03-Aug-2026 (1) - Build 3.7.0.2608031015
- [#238](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/238): added `ExcludedBackgroundLabels` (CLI: `--excluded-background-labels`) - a space-separated Installomator label list (wildcards supported, same expansion model as `IgnoredLabels`) for apps that should stay in discovery/reporting/inventory but must not be auto-updated during unattended runs. Classic use case: developer runtimes like Amazon Corretto / Node / Python, where a project is pinned to a specific major version and silently bumping it breaks builds. Unlike `IgnoredLabels`, which removes the app from AAP entirely (and therefore from discovery/version reporting), excluded-background labels remain fully visible - AAP just withholds them from fully-silent installs (`InteractiveMode 0` / `--workflow-install-now-silent`) and from Background Patch Closed Apps. Interactive Install Now (deferral dialog or `--workflow-install-now`) and hard-deadline installs still update them, so there's a deliberate manual escape hatch. Cleared by `--reset-labels` alongside the other label lists. Managed preference manifests (iMazing + Jamf JSON) and the All-Options example profile updated accordingly

## Version 3.6.3
### 11-Aug-2026 (1)
- Hardened the `AAP-JamfProEAs/AAP-LatestPatches.sh` Jamf Pro extension attribute for `jamf recon`: replaced NUL-delimited `read -d ''` / process substitution with a newline `find` listing written to a temp file (avoids EA stalls when Jamf keeps stdin open), always emits `<result>` (no `set -e`), and keeps the existing Success/Failure output format

### 04-Aug-2026 (1) - Build 3.6.3.2608040922
- Changed: the Dock-active wait in `workflow_startup()` no longer exits the script when no user session appears. It still waits briefly (now 20 seconds, down from 120) for the Dock to become active, but if it never does, AAP logs that it's continuing without an active user session and proceeds - some admins intentionally run AAP before anyone is logged in, and the previous `exit 1` after 120 seconds blocked that entirely. When the Dock is not active after that wait, `get_dialog()` is also skipped (the same as fully-silent runs), since swiftDialog can't safely present UI without an active user session. Fully-silent runs (`InteractiveMode 0`, or `--workflow-install-now-silent`) still skip the Dock wait entirely as before

## Version 3.6.2
### 03-Aug-2026 (3) - Build 3.6.2.2608030900
- [#248](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/248): the installer `.pkg` attached to each release reported its version as `0`, so every release looked identical to an MDM. Intune reads the package version off the pkg's component metadata and surfaces it on the auto-generated detection rule (bundle ID `xyz.techitout.appAutoPatch.installer`, version `0`), and refused to let an admin replace an already-uploaded pkg with a newer one: *"Update this app by selecting a newer line-of-business app-package. The version of your existing package is [0], and the selected package equals version [0]."* Two places were responsible: `pkgbuild` was invoked without a version argument, so the component pkg's `PackageInfo` was written with `version="0"`, and `distribution.xml` separately hardcoded `version="0"` on its `<pkg-ref>`. The `<product version>` productbuild wrote was already correct, confirming Intune reads the component/`pkg-ref` version rather than the product version
	- Fixed by versioning the component pkg with the full build string (`3.6.2.2608030900`), which productbuild then copies onto the `<pkg-ref>` automatically once the hardcoded attribute is removed - so the component and the distribution can't disagree. `distribution.xml` is now a template with an `__AAP_VERSION__` placeholder that `build-pkg.sh` substitutes with the short version (`3.6.2`) for a new `<product id="xyz.techitout.appAutoPatch" version="...">` element, per Apple's guidance that the product version should be the short version string. The build aborts if any placeholder is left unsubstituted
	- The full build string rather than the short version is used for the component version deliberately: rebuilding an already released version (as happened twice for 3.6.1) still produces a strictly higher version than the pkg it replaces, so the MDM upload is never blocked
	- The package identifier is unchanged (`xyz.techitout.appAutoPatch.installer`), so existing Intune detection rules continue to match

### 01-Aug-2026 (2) - Build 3.6.2.2608011640
- Fixed: the overlay icon could still render blank on a Jamf-managed Mac. The Self Service and Self Service+ branches accepted a configured path purely for being a non-empty string, without checking that anything was actually installed there. A Jamf plist commonly retains a `self_service_app_path` pointing at `/Applications/Self Service.app` after an organization moves to Self Service+, so that stale path won the first branch, shadowed the correctly-configured (and installed) `self_service_plus_path`, and handed swiftDialog `/Applications/Self Service.app/Contents/Resources/AppIcon.icns` - a file that doesn't exist, which swiftDialog draws as a blank overlay
	- Fixed by evaluating Self Service and then Self Service+ as ordered candidates, where a candidate is only accepted once it actually yields a readable icon file: a configured path with no app bundle at it is now skipped so the next candidate gets a chance, and an app whose `Contents/Resources/AppIcon.icns` is missing/empty is skipped as well
- Fixed: the custom-icon extraction validated its output only with `-s` (non-empty). The `xxd -p -s 260` offset that skips the resource fork header to reach the icns data isn't a guaranteed layout, and when it doesn't line up the extraction still writes a large non-empty file of raw resource bytes - which passed the check and was handed to swiftDialog as an "icon", again drawing blank. Now also confirms the extracted file starts with the `icns` magic bytes before trusting it, falling back to the app's default icon otherwise
- Added: a final guard so no branch (including the non-Jamf management tool and App Store fallbacks, none of which verified their icon file exists either) can hand swiftDialog an unreadable path. An icon path that is missing or empty is dropped, so dialogs render normally with no overlay instead of showing an empty overlay badge
- Added: verbose logging throughout the overlay icon resolution - the `self_service_app_path`/`self_service_plus_path` values read from the Jamf plist, whether each candidate's app bundle exists, whether a custom icon is assigned and its resource fork size, the extraction result and size, which candidate/fallback was selected, and the final overlay icon path with its size. Makes a blank overlay diagnosable from a verbose log alone

### 01-Aug-2026 (1) - Build 3.6.2.2608011030
- Fixed: `resolve_early_silent_mode()` (added in 3.6.1 to skip the Dock-active wait and swiftDialog install/update check for fully-silent runs) was itself called too late in `workflow_startup()` - after the Dock-wait loop that immediately follows the root-privilege check. So a fully-silent run (`InteractiveMode 0`, or `--workflow-install-now-silent`) still blocked on the *first* Dock-wait loop (up to 120 seconds, and previously able to `exit 1` entirely if no user ever logs in) before `runningSilentlyOption` was even set; only the second, later loginwindow-wait loop was actually being skipped
	- Fixed by moving the one-shot self-update override, `resolve_self_update_preferences()`, and `resolve_early_silent_mode()` calls to immediately after the root-privilege check, and guarding the Dock-wait loop with `runningSilentlyOption` the same way the loginwindow-wait loop already was. Both waits are now consistently skipped for fully-silent, unattended runs

## Version 3.6.1
### 23-Jul-2026 (8) - Build 3.6.1.2607232330
- Fixed: the installer `.pkg` attached to GitHub releases prompted "Rosetta 2 is required" on Apple Silicon Macs before allowing installation to proceed, even though the package has no compiled payload at all (`pkgbuild --nopayload`) and its postinstall script only ever runs a zsh script. Per Apple's own `productbuild` documentation: "the macOS Installer will evaluate the product's distribution under Rosetta 2 unless the arch key includes the arm64 architecture specifier" - with `hostArchitectures` unset, `distribution.xml`'s `<options>` element defaulted to Intel-only, so the installer assumed Rosetta 2 was required and displayed the prompt (and, per the same note, would have actually run the postinstall script itself under Rosetta 2 translation on Apple Silicon Macs without Rosetta pre-installed, had the user proceeded)
	- Fixed by adding `hostArchitectures="arm64,x86_64"` to the `<options>` element in `Resources/Packaging/distribution.xml`, declaring the product (a plain zsh script with no compiled binaries) as natively supporting both architectures

### 23-Jul-2026 (7) - Build 3.6.1.2607232300
- Fixed: the Jamf Self Service/Self Service+ overlay-icon logic checked only whether `self_service_app_path`/`self_service_plus_path` were configured, then unconditionally tried to extract a custom icon from that app's invisible `Icon\r` marker file's resource fork. Since that marker file's *existence* doesn't necessarily mean a custom icon (set via Finder's Get Info) was actually assigned, an admin who left Self Service/Self Service+ with its default icon still hit this path, producing a zero-byte, unusable `/var/tmp/overlayicon.icns`. Falling back to `.../Contents/Resources/AppIcon.icns` wasn't viable either, since that's always the app's default and would incorrectly override a real custom icon when one *is* set
	- Fixed by checking the resource fork's size (`-s ".../Icon"$'\r'/..namedfork/rsrc`) before attempting extraction - only present/non-empty when a custom icon is actually assigned - and by verifying the extracted `overlayicon.icns` itself is non-empty afterward. When no custom icon is present (or extraction still somehow produces an empty file), falls back to Self Service's own default `AppIcon.icns` instead of a blank overlay

### 23-Jul-2026 (6) - Build 3.6.1.2607232200
- [#236](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/236): with `MonthlyPatchingCadenceEnabled`, `check_completion_status()`'s `PatchingComplete == 1` branch unconditionally called `set_auto_launch_deferral()`, which always overwrites `NextAutoLaunch` with `now + deferral_timer_minutes` (default 1440 minutes/24 hours) - regardless of whether Monthly Patching Cadence had already calculated and stored a correct, much further-out `NextAutoLaunch` (via `set_auto_launch_monthly_cadence()`) the first time patching completed that cycle. Any out-of-band re-trigger of the script after that point (a manual run, a Jamf policy re-run, or a reinstall/upgrade re-executing the script directly - all of which bypass the LaunchDaemon helper's own `NextAutoLaunch`-vs-now check) would see `PatchingComplete == 1` and silently collapse the correct monthly schedule down to a 24-hour one, causing AAP to relaunch and re-run its full startup workflow far more often than the admin configured - most impactful with a short `DaysUntilReset`
	- Fixed by checking `monthly_patching_cadence_enabled` in that branch: if enabled, read the existing `NextAutoLaunch` first - if it's the explicit-disable sentinel (`FALSE`/`0`, i.e. `WorkflowDisableRelaunch`), leave it alone; if it parses as a valid date still in the future, leave it alone (this is the fix requested in the issue); otherwise (unset, unparsable, or already in the past) calculate a new one via `next_nth_weekday_datetime`/`set_auto_launch_monthly_cadence()`, the same way the normal end-of-workflow completion path already does. Behavior is unchanged when Monthly Patching Cadence is disabled - `set_auto_launch_deferral()` still runs as before

### 23-Jul-2026 (5) - Build 3.6.1.2607232100
- [#241](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/241): `SupportTeamPhone`/`SupportTeamEmail`/`SupportTeamWebsite` previously defaulted to a hardcoded placeholder string (`"Add IT Phone Number"`, `"Add email"`, `"Add IT Help site"`) when left unconfigured, which then displayed literally in the info dialog's help message as if it were a real, admin-provided value - the existing `!= "hide"` checks only caught the explicit opt-out string, not simply leaving the field blank
	- Changed the three defaults in `set_defaults()` to `""`, and added an `-n` (non-empty) guard alongside the existing `!= "hide"` check everywhere the info dialog's `helpMessage` is built, so a blank/unconfigured value now hides that line exactly like `hide` does
	- The managed/local preference merge in `get_preferences()` for these three previously gated the local-preference fallback on the current value already being non-empty (relying on the old placeholder defaults always being truthy) - with defaults now blank, that gate would never pass and local prefs would never be picked up, so it was removed for these three specifically (managed still overrides local, matching every other merge in the script)
	- Guarded `supportTeamHyperlink`'s construction (`[${supportTeamWebsite}](https://${supportTeamWebsite})`) so it's only built when `supportTeamWebsite` is actually set and not `hide`, avoiding a broken/blank markdown link if referenced before that guard is hit

### 23-Jul-2026 (4) - Build 3.6.1.2607232000
- Fixed three issues reported in [#237](https://github.com/App-Auto-Patch/App-Auto-Patch/issues/237):
	- The Jamf Application & Custom Settings custom schema (`Resources/Manifests/xyz.techitout.appAutoPatch-manifest-jamf.json`) defined the property as lowercase `versionComparisonMethod`, while the script always reads it as `VersionComparisonMethod` (`defaults read` is case-sensitive) - so a value configured through the Jamf schema UI was deployed under the wrong key and silently never read, always falling back to the built-in `IS_AT_LEAST` default. Renamed the schema property to `VersionComparisonMethod` to match the script. Also corrected the same casing in two spots in the iMazing/ProfileCreator manifest plist (`Resources/Manifests/xyz.techitout.appAutoPatch-manifest.plist`) - the `pfm_name` itself, and its entry in the parent group's `pfm_range_list` (used for iMazing's UI ordering) - which had the identical lowercase typo
	- `appsUpToDate()` called a nonexistent `notice` function (should have been `log_notice`, the script's actual logging helper) after every patch run, producing `command not found: notice` in the log even on a fully successful run with no errors. Fixed both call sites to use `log_notice`
	- While investigating, found `appsUpToDate()` and `verifyLastPosition()` (used by the Installomator error-log position tracker) both referenced an undefined `scriptLog` variable - which doesn't exist anywhere in the script - instead of `appAutoPatchLog` (the actual log file variable), so `tail -n 200/400 "$scriptLog"` always ran against an empty path, producing `tail: : No such file or directory` on every run. This is visible in the reporter's own pasted log output immediately before the `notice` error. Fixed both to reference `appAutoPatchLog`

### 23-Jul-2026 (3) - Build 3.6.1.2607231900
- Fixed: on fully-silent, unattended runs (`InteractiveMode 0`, or the `--workflow-install-now-silent` trigger, both intended for lab/kiosk Macs where no user is ever logged in) `workflow_startup()` still ran the loginwindow-wait loop (up to 10 minutes, waiting for a user session that will never come) and still called `get_dialog()` (checking for/installing/updating swiftDialog), even though every dialog call in the script is already gated behind `InteractiveModeOption -ge 1` and is therefore unreachable under `InteractiveMode 0`
	- Added `resolve_early_silent_mode()`, called right after `resolve_self_update_preferences()` (before the loginwindow-wait loop and `get_dialog()`, both of which run ahead of `get_preferences()`/`manage_parameter_options()`'s normal `InteractiveModeOption` resolution). It previews (read-only, does not mutate `InteractiveModeOption` itself) whether this run will end up fully silent, using the same managed-overrides-local-overrides-CLI/default precedence as `InteractiveMode`'s normal resolution, plus the `--workflow-install-now-silent`/`--workflow-install-now` triggers (CLI flag or flag file) - `--workflow-install-now` always wins and is never treated as silent, since it forces `InteractiveModeOption` to `2` later regardless of `InteractiveMode`'s configured value
	- Sets a new `runningSilentlyOption` flag; the loginwindow-wait loop and `get_dialog()` are now skipped (with a log line noting why) whenever it's `TRUE`

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
