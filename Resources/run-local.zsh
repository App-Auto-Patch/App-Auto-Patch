#!/bin/zsh --no-rcs

# Run the working-copy App Auto-Patch script on this Mac, for development.
#
# AAP hardcodes its state under /Library/Management/AppAutoPatch and must run as root, so there is
# no sandboxed mode - this really patches this Mac. What it gives you over calling the script by
# hand is: it runs the repo copy (not the deployed /Library/Management one), it stops the
# LaunchDaemon first so the deployed copy can't relaunch on top of you, and it defaults to verbose
# logging with the relaunch workflow disabled.
#
#   sudo ./Resources/run-local.zsh                                        # normal interactive run
#   sudo ./Resources/run-local.zsh --force-discovery                      # re-scan even if DiscoveryFrequency hasn't elapsed
#   sudo ./Resources/run-local.zsh --interactiveMode=0 --workflow-install-now-silent
#
# Note: AAP has no discovery-only mode - discovery always feeds straight into patching. To watch
# discovery without anything being installed, add every label you care about to --ignored-labels.
#
# Any other arguments are passed through to App-Auto-Patch-via-Dialog.zsh untouched.

scriptDir="${0:A:h}"
repoRoot="${scriptDir:h}"
aapScript="${repoRoot}/App-Auto-Patch-via-Dialog.zsh"
launchDaemonLabel="xyz.techitout.aap"
launchDaemonPlist="/Library/LaunchDaemons/${launchDaemonLabel}.plist"

if [[ $(id -u) -ne 0 ]]; then
    print -u2 "Error: App Auto-Patch must run as root. Re-run with sudo."
    exit 1
fi

if [[ ! -f "${aapScript}" ]]; then
    print -u2 "Error: ${aapScript} not found."
    exit 1
fi

# ConvertAppsInHomeFolder deletes apps out of ~/Applications during discovery. That is destructive
# and easy to trigger by accident on a dev machine that installs apps with Homebrew Cask, so a
# local run refuses to start until it is explicitly turned off or on.
convertSetting=$(/usr/bin/defaults read /Library/Management/AppAutoPatch/xyz.techitout.appAutoPatch ConvertAppsInHomeFolder 2> /dev/null)
managedIgnoreSetting=$(/usr/bin/defaults read "/Library/Managed Preferences/xyz.techitout.appAutoPatch" IgnoreAppsInHomeFolder 2> /dev/null)
if [[ -z "${convertSetting}" ]] && [[ "${managedIgnoreSetting}" != "1" ]] && [[ "${managedIgnoreSetting:u}" != "TRUE" ]]; then
    print -u2 "Error: neither ConvertAppsInHomeFolder nor IgnoreAppsInHomeFolder is set."
    print -u2 "A run would delete apps found under ~/Applications (Homebrew Cask installs them there)."
    print -u2 "Set one first, e.g.:"
    print -u2 "  sudo defaults write /Library/Management/AppAutoPatch/xyz.techitout.appAutoPatch ConvertAppsInHomeFolder -string FALSE"
    exit 1
fi

# Stop the deployed copy so it can't relaunch over this run, and restore it on the way out.
daemonWasLoaded="FALSE"
if /bin/launchctl print "system/${launchDaemonLabel}" > /dev/null 2>&1; then
    daemonWasLoaded="TRUE"
    print "Unloading ${launchDaemonLabel} for the duration of this run"
    /bin/launchctl bootout "system/${launchDaemonLabel}" 2> /dev/null
fi

restore_daemon() {
    if [[ "${daemonWasLoaded}" == "TRUE" ]] && [[ -f "${launchDaemonPlist}" ]]; then
        print "Reloading ${launchDaemonLabel}"
        /bin/launchctl bootstrap system "${launchDaemonPlist}" 2> /dev/null
    fi
}
trap restore_daemon EXIT INT TERM

runArgs=(--verbose-mode --workflow-disable-relaunch "$@")

print "Running ${aapScript} ${runArgs[*]}"
/bin/zsh "${aapScript}" "${runArgs[@]}"
exitCode=$?

print "App Auto-Patch exited with code ${exitCode}"
print "Logs: /Library/Management/AppAutoPatch/logs/aap.log"
print "      /Library/Management/AppAutoPatch/logs/aap_verbose.log"
print "      /var/log/Installomator.log"

exit ${exitCode}
