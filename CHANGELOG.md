# CHANGELOG

This is a user-facing summary of App Auto-Patch releases: what changed, what's new, and what you need to know before upgrading. For a detailed, line-by-line development history, see [CHANGELOG_DETAIL.md](CHANGELOG_DETAIL.md).

# Version 3

## Version 3.9.0
### 07-Sep-2026

**New Features**

- **Homebrew Support** - Discover and upgrade outdated Homebrew casks and formulae alongside Installomator labels, in the same discovery run, the same user dialog, and the same deferral/deadline/reporting flow. Opt-in; disabled by default. Homebrew runs de-privileged as the owner of the Homebrew prefix, and is skipped entirely when that prefix is root-owned or belongs to someone other than the console user.
	- Managed Preference Key: `<key>HomebrewEnabled</key>` `<true/>` | `<false/>` - default: `false`
	- Managed Preference Key: `<key>HomebrewCaskEnabled</key>` `<true/>` | `<false/>` - default: `true`
	- Managed Preference Key: `<key>HomebrewFormulaEnabled</key>` `<true/>` | `<false/>` - default: `true`
	- Managed Preference Key: `<key>HomebrewPriority</key>` `<string>INSTALLOMATOR | HOMEBREW</string>` - default: `INSTALLOMATOR`. Decides which tool wins when a package is available from both.
	- Managed Preference Key: `<key>HomebrewPreferredPackages</key>` `<string>pkg1 pkg2</string>` - per-package override of `HomebrewPriority`. Under `INSTALLOMATOR` priority these packages are taken from Homebrew instead; under `HOMEBREW` priority they are taken from Installomator instead.
	- Managed Preference Key: `<key>HomebrewBinaryPath</key>` `<string>/opt/homebrew/bin/brew</string>` - optional; auto-detected when unset
	- Managed Preference Key: `<key>HomebrewIgnoredCasks</key>` `<string>cask1 cask2</string>`
	- Managed Preference Key: `<key>HomebrewIgnoredFormulae</key>` `<string>formula1 formula2</string>`
	- CLI: `--homebrew-enabled` / `-disabled`, `--homebrew-cask-enabled` / `-disabled`, `--homebrew-formula-enabled` / `-disabled`, `--homebrew-priority=`, `--homebrew-preferred-packages=`, `--homebrew-binary-path=`, `--homebrew-ignored-casks=`, `--homebrew-ignored-formulae=`
	- Casks that declare `auto_updates true` or `version :latest` are not managed - they update themselves
	- Casks installed from a `.pkg` that requires an administrator password cannot be upgraded unattended; the failure is logged and counted, and does not abort the run
	- `--reset-labels` clears the discovered Homebrew queue alongside the other label lists

**Fixes**

- Fixed: the temporary wrapper script used when resolving a label's download URL was created at a fixed, predictable path in world-writable `/private/tmp` instead of a randomised one, because a trailing `.sh` in the `mktemp` template stops BSD `mktemp` from substituting the placeholder. That path was written by a root LaunchDaemon, and a crash that left the file behind made every later staging attempt fail until it was removed by hand. Pre-existing; unrelated to Homebrew support

## Version 3.7.1
### 02-Sep-2026

**Fixes**

- Fixed: Mosyle Slack/Teams **View in Mosyle** links no longer use the enrollment `ServerURL` (for example `https://biz-1234.mosyle.com`), which is the MDM check-in host and does not open the admin console. Business enrollments now link to `https://mybusiness.mosyle.com`; other Mosyle enrollments link to `https://my.mosyle.com`. Set `MosyleConsoleURL` or `--mosyle-console-url=` to override. (#267)
- Fixed: console user detection now takes the ConsoleUser UID from `scutil` and resolves the account RecordName with `id -un`. `scutil`'s `Name` field can be a login alias rather than the short name (for example `nathan` instead of `nathan.beranger`), which then breaks `su`, `id`, and other per-user lookups. Login window still reports no GUI user. (#264)

## Version 3.7.0
### 08-Aug-2026

**New Features**

- **Business Hours** — Block interactive discovery/dialogs/patching during configured weekday time windows (do-not-disturb hours). Format `DAY:hh:mm-hh:mm`. Multiple windows per day are supported (e.g. morning + afternoon with lunch left clear). Outside those windows, the full workflow is allowed. During a window, AAP only reschedules `NextAutoLaunch` to the next clear time — unless Silent During is enabled. Deferral and monthly-cadence relaunches are clamped outside Business Hours. `--workflow-install-now` / `--workflow-install-now-silent` / `--preview-deferral-dialog` / `--pending-apps-dialog` and headless discovery-only workflows intentionally bypass Business Hours. Overdue hard deadlines bypass by default; set `BusinessHoursRespectHardDeadline` to `true` for strict mode. Replaces the earlier allow-list `ScheduleWorkflowActive` model. (#166)
	- Managed Preference Key: `<key>BusinessHours</key>` `<string>MON:09:00-17:00,TUE:09:00-17:00,...</string>` — empty/unset = always allowed
	- Managed Preference Key: `<key>BusinessHoursRespectHardDeadline</key>` `<true/>` | `<false/>` — default: `false` (hard deadline bypasses Business Hours)
	- Managed Preference Key: `<key>BusinessHoursSilentDuring</key>` `<true/>` | `<false/>` — default: `false`. When `true`, during Business Hours AAP still runs discovery and silently patches **closed apps only** (no dialogs, even if InteractiveMode is 1/2). Open/blocked apps stay queued until Business Hours clear.
	- Managed Preference Key: `<key>BusinessHoursAllowDiscovery</key>` `<true/>` | `<false/>` — default: `false`. When `true` and SilentDuring is off, run discovery during Business Hours then defer (no interactive dialogs / silent patch). Default `false` = historical immediate defer with no discovery.
	- CLI: `--business-hours=...` / `--business-hours-respect-hard-deadline` / `-off` / `--business-hours-silent-during` / `-off` / `--business-hours-allow-discovery` / `-off`
- **Skip Pre-Update Verification** — Optionally skip the local Gatekeeper (`spctl`) / Team ID pre-update check during discovery. Some already-installed apps fail `spctl -a` intermittently and were being dropped from the update queue entirely; enabling this keeps them eligible while Installomator still validates the downloaded package. Default off. (#256)
	- Managed Preference Key: `<key>SkipPreUpdateVerification</key>` `<true/>` | `<false/>` — default: `false`
	- CLI: `--skip-pre-update-verification` / `--skip-pre-update-verification-off`
- **Dock Icon** — Workflow swiftDialog windows show the App Auto-Patch logo in the macOS Dock (`--dockicon`) when swiftDialog 3.0+ is installed (default on). The deferral dialog badges the icon with the pending update count; the installation dialog counts that badge down as each update finishes. Disable with `ShowDockIcon` / `--show-dock-icon-off`. Dock Quit / ⌘Q on deferral reopens the dialog (does not install); quitting the patching window offers Show Progress or Continue in Background. Discovery/staging windows follow `DialogQuitHandlingDiscoveryStaging`.
	- Managed Preference Key: `<key>ShowDockIcon</key>` `<true/>` | `<false/>` — default: `true`
	- CLI: `--show-dock-icon` / `--show-dock-icon-off`
- **Discovery/Staging Dock Quit** — Dock Quit / ⌘Q on the discovery or staging window no longer always continues silently. Default **PROMPT** asks **Keep Running** vs **Stop App Auto-Patch** (stop preserves `NextAutoLaunch` until the next scheduled run). **CONTINUE** keeps the previous implicit keep-running behavior with no prompt. **STOP** ends the current run at the next safe label boundary. Stop is ignored when a hard deadline is already due or Install Now is running.
	- Managed Preference Key: `<key>DialogQuitHandlingDiscoveryStaging</key>` `<string>PROMPT,CONTINUE,STOP</string>` — default: `PROMPT`
	- Language keys: `display_string_preparationdismissed_message`, `display_string_preparationdismissed_button1` (default `Keep Running`), `display_string_preparationdismissed_button2` (default `Stop App Auto-Patch`)
- **Stale process recovery** — Heartbeat + PID-identity validation so a leftover hung AAP process (or a recycled PID in `/var/run/aap.pid`) cannot block `aap-starter` indefinitely. Timeout-based recovery sends `TERM`, then `KILL` if the process does not exit. Staging `curl` downloads abort when no data is transferred (hung/no-data timeout) instead of waiting forever. `--stop` is an admin escape hatch that ends a live run and keeps the existing LaunchDaemon schedule.
	- Managed Preference Key: `<key>StaleProcessTimeoutSeconds</key>` `<integer>3600</integer>` — default: `3600` (1 hour). `0` disables timeout-based stale-process killing (dead/reused PID cleanup still runs). Any other value below `300` is raised to `300`
	- CLI: `--stop`
- **Scheduled Discovery Only** — A user-driven installation mode for fleets that need fresh pending-app inventory without automatic patch prompts or installs. Set `WorkflowDisableRelaunch=true` and `WorkflowScheduledDiscovery=true`; AAP schedules headless scans using `DiscoveryFrequency`, refreshes the report/Support App queue, optionally stages installers, and optionally sends queued-app notifications. It skips silent patching, deferral/deadline UI, and installation. Explicit pending-apps and Install Now triggers continue to work. (#258)
	- Managed Preference Key: `<key>WorkflowScheduledDiscovery</key>` `<true/>` | `<false/>` — default: `false`
	- CLI: `--workflow-discovery-only` performs one immediate, one-shot discovery-only refresh without replacing an existing schedule
- **Banner Notifications** — Non-persistent swiftDialog `--notification --style banner` alerts (default on):
	- After silent closed-app patching succeeds: “updated {count} application(s) in the background”
	- During Business Hours without SilentDuring: when `BusinessHoursAllowDiscovery` is on and apps are found, optionally notify “{count} application(s) require updates” with Install Now / Dismiss (requires `ShowNotificationsAll` or `ShowNotificationsAppsQueued`) — Install Now opens the pending-apps dialog
	- During Business Hours with SilentDuring after silent patch: “{count} updated… {remaining} remain queued” (Install Now opens the pending-apps dialog when remaining &gt; 0)
	- Managed Preference Key: `<key>ShowNotificationsAll</key>` `<true/>` | `<false/>` — default: `true` (master switch; wins over individual type keys)
	- Managed Preference Key: `<key>ShowNotificationsSilentUpdated</key>` / `<key>ShowNotificationsAppsQueued</key>` / `<key>ShowNotificationsSilentAndQueued</key>` `<true/>` | `<false/>` — default: `false`; opt-in when All is false
	- CLI: `--show-notifications-all` / `-off` (aliases `--show-notifications` / `-off`) and per-type `--show-notifications-silent-updated` / `--show-notifications-apps-queued` / `--show-notifications-silent-and-queued` (each with `-off`)
	- Requires notifications to be approved for swiftDialog via a `com.apple.notificationsettings` profile: `au.csiro.dialog.notifier.banner` and `au.csiro.dialog.notifier.alert` (swiftDialog 3.1+ helper apps), plus `au.csiro.dialog` for 3.0 and earlier
- **Pending Apps Dialog** — Near-instant list of queued updates from the report PLIST (no discovery). **Later** dismisses; **Install Now** continues in-process — it patches exactly the queue shown (report PLIST `ItemsToInstall` only; no Required/Converted/Discovered extras, no fresh discovery scan) using the standard install-now workflow, rather than spawning a second `appautopatch --workflow-install-now` process. Install Now goes straight to the patching dialog, skipping pre-staging and the background closed-app patch since the user already approved the install. Intent survives restart/network defer via `.PendingAppsInstallNow`. Used by queued-app notification Install Now; also CLI / Support App.
	- CLI Trigger: `--pending-apps-dialog`
	- Language key: `display_string_pendingapps_button_later` (default `Later`)
- **Cleaner, faster logging** — `aap.log` now contains only regular workflow output; `[VERBOSE]` lines no longer appear there even with `VerboseMode` on. `aap_verbose.log` is written only when `VerboseMode` is on, and then holds the full transcript (regular output plus VERBOSE lines) — so default fleets no longer pay for always-on verbose-file I/O. Fixed duplicate VERBOSE lines in the verbose log. Log writes now cache host/script identity and keep append file descriptors open, and per-tick `swiftDialogUpdate` verbose logging was removed. Log lines are now tagged with the script name instead of the internal logging function name.
	- Managed Preference Key: `<key>VerboseMode</key>` `<true/>` | `<false/>`
	- CLI: `--verbose-mode` / `--verbose-mode-off`
- **Pre/Post Patch Scripts** — Run a managed, root-owned script once before and/or after Installomator installations (e.g. `jamf recon`). Scripts must live under `/Library/Management/AppAutoPatch/Hooks/`, cannot be symlinks, and must not be group/world-writable. Managed preferences only — never CLI or local prefs, never `eval`'d. (#156)
	- Managed Preference Key: `<key>PrePatchScript</key>` `<string>/Library/Management/AppAutoPatch/Hooks/pre.sh</string>`
	- Managed Preference Key: `<key>PostPatchScript</key>` `<string>/Library/Management/AppAutoPatch/Hooks/post.sh</string>`
	- Managed Preference Key: `<key>PrePatchScriptFailAction</key>` `<string>ABORT,CONTINUE</string>` — default: `ABORT`
	- Managed Preference Key: `<key>PostPatchScriptFailAction</key>` `<string>ABORT,CONTINUE</string>` — default: `CONTINUE`
	- Managed Preference Key: `<key>PatchScriptTimeoutSeconds</key>` `<integer>300</integer>`
- **Mosyle MDM support** — Detect Mosyle from the enrollment ServerURL, include a “View in Mosyle” device deep-link in Slack/Teams webhooks, and prefer the Mosyle Self Service overlay icon when present. Webhook console host prefers the enrolled MDM URL, with a fallback to `https://business.mosyle.com`. (#240)
- **GitHub API Authentication** — Optionally authenticate `api.github.com` requests with a GitHub personal access token so AAP stays under GitHub's rate limits in large fleets (60 → 5,000 requests/hour). Managed preferences only; the token is never written to the local preference file and is never logged. If auth is enabled without a token, startup validation fails. (#249)
	- Managed Preference Key: `<key>GitHubAPIAuthEnabled</key>` `<string>TRUE,FALSE</string>` — default: `FALSE`
	- Managed Preference Key: `<key>GitHubAPIToken</key>` `<string>github_pat_...</string>` — required when auth is enabled
- **Excluded Background Labels** — Pin specific apps so AAP still discovers and reports them, but does not update them during fully-silent runs (`InteractiveMode 0` / `--workflow-install-now-silent`) or Background Patch Closed Apps. Interactive Install Now and hard-deadline installs still update them, so there's a manual escape hatch. Unlike `IgnoredLabels`, these apps stay visible in discovery, logs, and inventory — useful for runtimes like Amazon Corretto, Node, or Python where "latest" isn't always correct. Supports wildcards. (#238)
	- Managed Preference Key: `<key>ExcludedBackgroundLabels</key>` `<string>label1 label2*</string>`
	- CLI Trigger: `--excluded-background-labels="label1 label2*"`
	- Cleared by `--reset-labels` along with the other label lists
- **Preview Deferral Dialog** — Quickly preview how the deferral dialog looks with your current banner/icon/language settings, without running discovery or installing anything. Uses sample apps with realistic icons and version subtitles. Both Install Now and Defer are no-ops for patching, and `NextAutoLaunch` is left unchanged.
	- CLI Trigger: `--preview-deferral-dialog`

**Behavior Changes**

- Changed: InteractiveMode 2 staging / background closed-app patch mini dialog now shows a determinate progress bar by queued app count, with per-app status text and icon (`Staging …` / `Installing …`) instead of an indeterminate bouncing bar. Default `display_string_silent_patch_progress` is now `Installing` (app name is appended)
- Changed: Dock Quit / ⌘Q during discovery or staging now follows `DialogQuitHandlingDiscoveryStaging` (default prompt) instead of always continuing without UI. Stop is unavailable after a hard deadline or during Install Now.
- Changed: leftover AAP processes are recovered via heartbeat age and PID validation, using graceful `TERM` then `KILL`; staging downloads time out when `curl` receives no data
- Changed: `--windowbuttons min` is now set on every interactive swiftDialog window, including deferral and pending-apps
- Changed: if no user is logged in, AAP no longer exits after waiting for the Dock — it waits up to 20 seconds, then continues without an active user session and skips the swiftDialog install/update check (since dialogs can't be shown without a user session). Fully-silent runs still skip the Dock wait entirely
- Fixed: Teams webhooks now resolve Workspace One device links the same way Slack webhooks already did
- Changed: when no custom dialog icon is configured, AAP logs an info message that it is using the SF Symbol fallback instead of a warning that incorrectly said the icon was "not found"

**Fixes**

- Fixed: a running AAP instance started as `sudo appautopatch …` was misread as an unrelated process (`aap.pid points to live non-AAP PID`), so `aap-starter` released the runtime markers and launched a second instance beside the first — two AAP runs patching and two deferral dialogs on screen. Ownership is now matched on the program AAP was actually invoked as, after skipping `sudo` and the interpreter, and a heartbeat naming the recorded PID is accepted as proof of ownership on its own. Startup also terminates any other live AAP instance that is running without runtime markers, so a lost PID file can no longer produce duplicate runs
- Fixed: choosing **Later** (or the “all up to date” dismiss) on `--pending-apps-dialog` no longer discards the schedule AAP was already on. Previously the key was cleared twice during startup (once for crash recovery, once while re-enabling automatic relaunch) and Later exited without writing a new one — so the LaunchDaemon’s 60-second interval relaunched AAP almost immediately. A deferral you had already chosen (e.g. “defer 30 minutes”) is now kept as-is, rather than being replaced by a freshly calculated default-deferral or monthly-cadence date. Only Install Now clears the schedule before continuing into the install workflow, and a missing or overdue schedule is still rescheduled on dismiss so the daemon can’t spin
- Changed: `--preview-deferral-dialog` no longer rewrites `NextAutoLaunch` either — previewing cosmetics leaves the existing LaunchDaemon schedule alone
- Fixed: the `AAP-LatestPatches` Jamf Pro extension attribute could stall `jamf recon` / inventory updates. It no longer uses NUL-delimited `read` with process substitution, always emits a `<result>` block, and discovers receipts via a temp-file listing instead
- Fixed: ignored labels could be silently disregarded on any run where app discovery actually executed, so apps you had ignored were queued and patched anyway. Discovery sets `IFS` to a newline in order to parse Installomator label fragments and never restored it, which broke the ignored-label membership checks and the array subtraction that removes ignored labels from the install queue. Runs that skipped discovery (via `DiscoveryFrequency`) were unaffected, which is why the problem looked intermittent. `IFS` is now restored as soon as label parsing finishes, and all label membership checks use exact-element matching that does not depend on `IFS` (#254)
- Fixed: `IgnoredLabels="*"` is no longer expanded into one local preference entry per Installomator label. That expansion issued roughly 1,200 `PlistBuddy` writes on every run, which left the preferences cache out of sync with the file on disk and made unrelated keys read back blank — most visibly `AAPPatchingStartDate` and `AAPPatchingCompletionStatus`, which produced a "Days Since Patching Start Date" in the tens of thousands and reset the patching cadence unexpectedly. The wildcard is now stored as a single `*` entry and evaluated in memory. No configuration change is required; `IgnoredLabels="*"` keeps its documented meaning of "ignore every label except those in `RequiredLabels` and `OptionalLabels`" (#254)
- Fixed: labels listed in `RequiredLabels` could be swept into the ignored list by a wildcard in `IgnoredLabels` and then dropped from the install queue, so required apps were never patched. Required labels are now always excluded from wildcard ignore matching (#254)
- Fixed: reads of the local preference file now fall back to reading the file directly when `defaults` returns an empty value for a key that is present on disk, and an unreadable `AAPPatchingStartDate` now falls back to the current patch week start date instead of being fed to a date conversion that silently produced the Unix epoch (#254)
- Fixed: label lists read back from an array-typed preference brought the surrounding parentheses, quotes, and trailing commas along as label names of their own — visible in logs as entries like `Required labels: ( )`. These are now stripped when the lists are parsed (#254)

## Version 3.6.3
### 04-Aug-2026

**Fixes**

- Changed: if no user is logged in, AAP no longer exits after waiting for the Dock - it waits up to 20 seconds, then continues without an active user session and skips the swiftDialog install/update check (since dialogs can't be shown without a user session). Fully-silent runs still skip the Dock wait entirely
- Fixed: the `AAP-LatestPatches` Jamf Pro extension attribute could stall `jamf recon` / inventory updates. It no longer uses NUL-delimited `read` with process substitution, always emits a `<result>` block, and discovers receipts via a temp-file listing instead

## Version 3.6.2
### 01-Aug-2026

**Fixes**

- Fixed: the fully-silent Dock-wait skip (introduced in 3.6.1, below) didn't actually take effect - the check that determines whether a run is fully silent ran too late, after the Dock-wait loop it was meant to skip, so `InteractiveMode 0`/`--workflow-install-now-silent` runs still waited on the Dock (and could fail outright on a Mac with no user ever logged in). Only the later loginwindow wait and swiftDialog check were being skipped as intended. The Dock wait is now skipped correctly as well
- Fixed: the overlay icon could still appear blank on Jamf-managed Macs. If the Jamf plist kept a `self_service_app_path` pointing at a Self Service.app that is no longer installed (common after moving to Self Service+), AAP used that stale path anyway - shadowing the correctly-configured Self Service+ and pointing at an icon file that doesn't exist. Self Service and Self Service+ are now each checked for an icon that actually exists and is readable before being used
- Fixed: extracting a custom Self Service icon only checked that the result wasn't empty, so a partially-read icon could still be passed to the dialog as a blank overlay. The extracted file is now verified to be a real `.icns` before it's used, falling back to the app's own icon if not
- Changed: if no usable overlay icon can be found at all, dialogs now render normally without an overlay instead of showing an empty overlay badge
- Added: verbose logging for the whole overlay icon selection process (which Jamf paths were read, whether each app and its icon were found, extraction results, and the final icon chosen), so a blank overlay icon can be diagnosed from a verbose log
- Fixed: the installer `.pkg` attached to each release reported its version as `0`, so every release looked like the same version to an MDM. In Intune this showed up as version `0` on the pkg's auto-generated detection rule and blocked replacing an already-uploaded pkg with a newer one ("The version of your existing package is [0], and the selected package equals version [0]"). The pkg now carries real version numbers - the short version (e.g. `3.6.2`) as the product version, and the full build string (e.g. `3.6.2.2608030900`) as the package version an MDM reads and compares. The package identifier is unchanged, so existing detection rules keep matching (#248)

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
- Fixed: with `MonthlyPatchingCadenceEnabled`, if AAP was re-triggered ahead of its scheduled relaunch (e.g. a manual run, or a reinstall/upgrade) after that cycle's patching had already completed, `NextAutoLaunch` was recalculated using the regular deferral timer (24 hours by default) instead of leaving the already-correct, further-out monthly cadence date in place - causing AAP to relaunch far more often than intended, especially with a shorter `DaysUntilReset` (#236)
- Fixed: the Jamf Self Service/Self Service+ overlay icon could end up blank if the admin hadn't set a custom icon for Self Service - AAP only checked whether the custom-icon marker file existed, not whether it actually contained icon data, and now falls back to Self Service's own default icon when no custom icon is present
- Fixed: the installer `.pkg` attached to GitHub releases prompted to install Rosetta 2 on Apple Silicon Macs before installing, even though the package has no compiled payload and only ever runs a zsh script - the package's distribution file was missing the `hostArchitectures` declaration, which macOS Installer treats as "Intel-only" by default

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
