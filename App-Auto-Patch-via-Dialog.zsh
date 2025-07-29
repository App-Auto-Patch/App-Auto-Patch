#!/bin/zsh --no-rcs

####################################################################################################
#
# App Auto-Patch
#
####################################################################################################
#
# HISTORY
#
#   Full Change Log: https://github.com/App-Auto-Patch/App-Auto-Patch/blob/main/CHANGELOG.md
#
#
####################################################################################################

####################################################################################################
#
# Global Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="3.2.2"
scriptDate="2025/05/20"
scriptFunctionalName="App Auto-Patch"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

### Usage and Help ###
show_usage() {
echo "
    App Auto-Patch

    Version ${scriptVersion}
    ${scriptDate}
    https://github.com/App-Auto-Patch
	
    Wiki:
    https://github.com/App-Auto-Patch/App-Auto-Patch/wiki

    Usage:
    sudo ./AppAutoPatch

    App Auto Patch Behavior Options
    [--interactiveMode=number]
    [--reset-defaults]
    [--patch-week-start-day=number]
    [--days-until-reset=number]

    Workflow Options:
    [--workflow-disable-relaunch] [--workflow-disable-relaunch-off]
    [--workflow-disable-app-discovery] [--workflow-disable-app-discovery-off]
    [--workflow-install-now] [--workflow-install-now-silent]
    [--workflow-install-now-patching-status-action-never]
    [--workflow-install-now-patching-status-action-always]
    [--workflow-install-now-patching-status-action-sucess]

    Deferral Deadline COUNT Options:
    [--deadline-count-focus=number]
    [--deadline-count-hard=number]
    [--deadline-count-delete-all]

    Deferral Deadline DAYS Options:
    [--deadline-days-focus=number] [--deadline-days-hard=number] 
    [--deadline-days-delete-all]

    App Label Options:
    [--ignored-labels="label1 label2"]
    [--required-labels="label1 label2"]
    [--optional-labels="label1 label2"]
    [--reset-labels]

    Deferral Timer Options:
    [--deferral-timer-default=minutes]
    [--deferral-timer-menu=minutes,minutes,etc...]
    [--deferral-timer-focus=minutes] [--deferral-timer-error=minutes]
    [--deferral-timer-workflow-relaunch=minutes] [--deferral-timer-reset-all]

    Webhook Options:
    [--webhook-feature-all] [--webhook-feature-failures] [--webhook-feature-off]
    [--webhook-url-slack=URL] [--webhook-url-teams=URL] [--webhook-url-zoom=URL]
    [--webhook-url-zoom-verification-token]

    Troubleshooting Options:
    [--verbose-mode] [--verbose-mode-off]
    [--debug-mode] [--debug-mode-off]
    [--usage] [--help]
    [--uninstall]
    [--version]
    [--vers]

    ** Managed preferences override local options via domain: xyz.techitout.appAutoPatch

    <key>AppTitle</key> <string>App Auto-Patch</string>
    <key>ConvertAppsInHomeFolder</key> <string>TRUE,FALSE</string>
    <key>DaysUntilReset</key> <integer>number</integer>
    <key>DeadlineCountFocus</key> <integer>number</integer>
    <key>DeadlineCountHard</key> <integer>number</integer>
    <key>DeadlineDaysFocus</key> <string>number</string>
    <key>DeadlineDaysHard</key> <string>number</string>
    <key>DeferralTimerDefault</key> <integer>minutes</integer>
    <key>DeferralTimerError</key> <integer>minutes</integer>
    <key>DeferralTimerFocus</key> <integer>minutes</integer>
    <key>DeferralTimerMenu</key> <string>minutes,minutes,minutes,etc...</string>
    <key>DeferralTimerWorkflowRelaunch</key> <integer>minutes</integer>
    <key>DialogOnTop</key> <string>TRUE,FALSE</string>
    <key>DialogTimeoutDeferral</key> <integer>seconds</integer>
    <key>DialogTimeoutDeferralAction</key> <string>Defer,Continue</string>
    <key>IgnoreAppsInHomeFolder</key> <string>TRUE,FALSE</string>
    <key>IgnoredLabels</key> <string>label label label etc</string>
    <key>InstallomatorOptions</key> <string>OPTION=option OPTION=option etc</string>
    <key>InstallomatorUpdateDisable</key> <string>TRUE,FALSE</string>
    <key>InstallomatorVersion</key> <string>Main,Release,Custom</string>
    <key>InstallomatorVersionCustomRepoPath</key> <string>Installomator/Installomator</string>
    <key>InstallomatorVersionCustomBranchName</key> <string>main</string>
    <key>InteractiveMode</key> <integer>number</integer>
    <key>OptionalLabels</key> <string>label label label etc</string>
    <key>PatchWeekStartDay</key> <integer>number</integer>
    <key>RemoveInstallomatorPath</key> <string>TRUE,FALSE</string>
    <key>RequiredLabels</key> <string>label label label etc</string>
    <key>SupportTeamEmail</key> <string>email</string>
    <key>SupportTeamName</key> <string>name</string>
    <key>SupportTeamPhone</key> <string>phoem</string>
    <key>SupportTeamWebsite</key> <string>URL</string>
    <key>UnattendedExit</key> <string>TRUE,FALSE</string>
    <key>UnattendedExitSeconds</key> <integer>seconds</integer>
    <key>UseOverlayIcon</key> <string>TRUE,FALSE</string>
    <key>WebhookFeature</key> <string>FALSE,ALL,FAILURES</string>
    <key>WebhookURLSlack</key> <string>URL</string>
    <key>WebhookURLTeams</key> <string>URL</string>
    <key>WebhookURLZoom</key> <string>URL</string>
    <key>WebhookURLZoomVerificationToken</key> <string>secret</string>
    <key>WorkflowDisableAppDiscovery</key> <true/> | <false/>
    <key>WorkflowDisableRelaunch</key> <true/> | <false/>
    <key>WorkflowInstallNowPatchingStatusAction</key> <string>NEVER | ALWAYS | SUCCESS</string>

    ** Detailed documentation can be found at: https://github.com/App-Auto-Patch/App-Auto-Patch/wiki
"
# Error log any unrecognized options.
if [[ -n "${unrecognized_options_array[*]}" ]]; then
	if [[ $(id -u) -eq 0 ]] && [[ -d "${appAutoPatchFolder}" ]]; then
		log_error "Unrecognized Parameter Options: ${unrecognized_options_array[*]%%=*}"
		[[ "${parent_process_is_jamf}" == "TRUE" ]] && log_warning "Note that each Jamf Pro Policy Parameter can only contain a single option."
		write_status "Inactive Error: Unrecognized Options: ${unrecognized_options_array[*]%%=*}"
	else # App Auto Patch is not running as root or not installed yet.
		log_echo "[ERROR] Unrecognized Parameter Options: ${unrecognized_options_array[*]%%=*}"
		[[ "${parent_process_is_jamf}" == "TRUE" ]] && log_echo "Warning: Note that each Jamf Pro Policy Parameter can only contain a single option."
	fi
fi
log_echo "#### ${scriptFunctionalName} ${scriptVersion} - USAGE EXIT ###"
exit 0

}

show_help() {
    get_logged_in_user
    if [[ "${currentUserAccountName}" != "FALSE" ]]; then
        log_echo "[STATUS] Opening App Auto-Patch wiki for user account: ${currentUserAccountName}"
        sudo -u "${currentUserAccountName}" open "https://github.com/App-Auto-Patch/App-Auto-Patch/wiki" &
        log_echo "#### ${scriptFunctionalName} ${scriptVersion} - HELP EXIT ####"
    else
        log_echo "Warning: Unable to open App Auto-Patch Wiki because there is no user logged in"
        show_usage
    fi
    exit 0

}

show_version() {
echo "
    App Auto-Patch

    Version ${scriptVersion}
    ${scriptDate}
    https://github.com/App-Auto-Patch
"
exit 0
}

show_version_short() {
    echo "${scriptVersion}"
    exit 0
}

### App Auto-Patch Path Variables ###
### MDM Enabled Config Noted Below ##

set_defaults() {

    timestamp="$( date '+%Y-%m-%d-%H%M%S' )"
    
    appTitle="App Auto-Patch" # MDM Enabled

    appAutoPatchFolder="/Library/Management/AppAutoPatch"

    appAutoPatchLogFolder="${appAutoPatchFolder}/logs"

    appAutoPatchLogArchiveFolder="${appAutoPatchFolder}/logs-archive"

    appAutoPatchLog="${appAutoPatchLogFolder}/aap.log"

    appAutoPatchLogArchiveSize=1000

    appAutoPatchLink="/usr/local/bin/appautopatch"

    appAutoPatchPIDfile="/var/run/aap.pid"

    InteractiveMode="2" # MDM Enabled

    installomatorPath="${appAutoPatchFolder}/Installomator"

    installomatorScript="${installomatorPath}/Installomator.sh"
    
    installomator_update_disable_option="FALSE"

    fragmentsPath="${installomatorPath}/fragments"

    convertAppsInHomeFolder="TRUE" # MDM Enabled

    ignoreAppsInHomeFolder="FALSE" # MDM Enabled

    installomatorOptions="BLOCKING_PROCESS_ACTION=prompt_user NOTIFY=silent LOGO=appstore" # MDM Enabled
    
    installomatorVersion="Main" # MDM Enabled - Use:  Release|Main 

    DialogTimeoutDeferral="300" # MDM Enabled
    
    DialogTimeoutDeferralAction="Defer" # MDM Enabled
    
    deferral_timer_minutes=1440

    DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES=1440
    
    patch_week_start_day_default="2" # MDM Enabled

    daysUntilReset="1" # MDM Enabled

    workflow_install_now_patching_status_action_option="SUCCESS" # MDM Enabled - Determines what happens when  NEVER | ALWAYS | SUCCESS 

    UnattendedExit="FALSE" # MDM Enabled

    UnattendedExitSeconds="60" # MDM Enabled

    appAutoPatchLocalPLIST="${appAutoPatchFolder}/xyz.techitout.appAutoPatch"

    appAutoPatchManagedPLIST="/Library/Managed Preferences/xyz.techitout.appAutoPatch"

    appAutoPatchLaunchDaemonLabel="xyz.techitout.aap"

    WORKFLOW_INSTALL_NOW_FILE="${appAutoPatchFolder}/.WorkflowInstallNow"
    
    WORKFLOW_INSTALL_NOW_SILENT_FILE="${appAutoPatchFolder}/.WorkflowInstallNowSilent"

    jamfBinary="/usr/local/bin/jamf"

    dialogBinary="/usr/local/bin/dialog"

    dialogCommandFile=$( mktemp /var/tmp/dialog.appAutoPatch.XXXXX )

    dialogTargetVersion="2.5.5"

    dialogOnTop="FALSE" # MDM Enabled

    reset_defaults_option="FALSE"

    useOverlayIcon="TRUE" # MDM Enabled

    debug_mode_option="FALSE"

    removeInstallomatorPath="FALSE" # MDM Enabled

    DEFERRAL_TIMER_DEFAULT_MINUTES="60"

    REGEX_ANY_WHOLE_NUMBER="^[0-9]+$"
    
    REGEX_CSV_WHOLE_NUMBERS="^[0-9*,]+$"

    supportTeamName="Add IT Support" # MDM Enabled

    supportTeamPhone="Add IT Phone Number" # MDM Enabled

    supportTeamEmail="Add email" # MDM Enabled

    supportTeamWebsite="Add IT Help site" # MDM Enabled

    computerName=$( scutil --get ComputerName )

    osVersion=$( sw_vers -productVersion )

    osBuild=$( sw_vers -buildVersion )

    osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )

    serialNumber=$( ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}' )

    modelName=$( /usr/libexec/PlistBuddy -c 'Print :0:_items:0:machine_name' /dev/stdin <<< "$(system_profiler -xml SPHardwareDataType)" )
    
    # Deadline date display format.
    DISPLAY_STRING_FORMAT_DATE="%a %b %d" # Formatting options can be found in the man page for the date command.
    readonly DISPLAY_STRING_FORMAT_DATE
    
    # Deadline time display format.
    DISPLAY_STRING_FORMAT_TIME="+%l:%M %p" # Formatting options can be found in the man page for the date command.
    readonly DISPLAY_STRING_FORMAT_TIME
    
}

# Set language strings for dialogs and notifications.
set_display_strings_language() {

    #### Language for the defer button in dialogs when the deferral time is sometime today.
    display_string_defer_today_button="Defer"
    display_string_defer_today_button_test="Defer"
    
    #### Language for the defer button in dialogs when the deferral time is tomorrow.
    display_string_defer_tomorrow_button="Defer Until Tomorrow"
    
    #### Language for the defer button in dialogs when the deferral time is in the future.
    display_string_defer_future_button="Defer Until"
    
    ### Language for various deferral timer durations.
    display_string_minutes="Minutes"
    display_string_hour="Hour"
    display_string_hours="Hours"
    display_string_and="and"
    display_string_days="days"
    display_string_times="times"
    display_string_there_are="There are"
    
    #### Language for the App Discovery dialog
    display_string_discovery_message="Analyzing installed apps"
    display_string_discovery_action_message="Analyzing"
    display_string_discovery_progress="Scanning"
    
    #### Language for the Deferral Dialog with Deferrals
    display_string_deferral_button1="Continue"
    display_string_deferral_button2="Defer"
    display_string_deferral_infobox1="Deferral available until"
    display_string_deferral_infobox2="out of"
    display_string_deferral_infobox3="deferrals remaining\n"
    display_string_deferral_message_01="You can **Defer** the updates or **Continue** to close the applications and apply updates.  \n\n"
    display_string_deferral_message_02="application(s) that require updates:"
    display_string_deferral_unlimited="No deadline date and unlimited deferrals\n"
    
    #### Language for the Deferral Dialog with NO deferrals remaining
    display_string_deferraldeadline_button1="Continue"
    display_string_deferraldeadline_button2="Max Deferrals Reached"
    display_string_deferraldeadline_infobox="Updates will automatically install after the timer expires. \n\n #### No Deferrals Remaining ####"
    display_string_deferraldeadline_message_deadline="application(s) that require updates\n\n You have deferred the maximum number of"
    
    #### Language for the Patching dialog
    display_string_patching_button1="Done"
    display_string_patching_checking="Checking"
    display_string_patching_progress="Processing"
    display_string_patching_infobox_computer_name="**Computer Name:**"
    display_string_patching_infobox_macos_version="**macOS Version:**"
    display_string_patching_infobox_updates="Updates:"
    display_string_patching_message="Updating the following apps"
    
    #### Language for Patching Complete Dialog
    display_string_complete_progress="Updates Complete!"
    
    #### All apps up to date
    display_string_uptodate_button1="Close"
    display_string_uptodate_message="All apps are up to date."
    
    #### Help Message
    display_string_help_message_intro="If you need assistance, please contact"
    display_string_help_message_telephone="Telephone"
    display_string_help_message_email="Email"
    display_string_help_message_help_website="Help Website"
    display_string_help_message_computer_info="Computer Information"
    display_string_help_message_operating_system="Operating System"
    display_string_help_message_serial="Serial Number"
    display_string_help_message_dialog="Dialog"
    display_string_help_message_started="Started"
    display_string_help_message_script_version="Script Version"
    
    # Count the number of dictionaries in dialogElements
    numElements=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements" "$appAutoPatchManagedPLIST.plist" | grep -c "Dict")
    log_verbose "Language Element Count: $numElements"
    log_verbose "User Languaget: ${langUser}"
    # Loop through each index and check the _language key
    # Optionally, enforce that numElements is treated as an integer.
    typeset -i numElements=$numElements
    if [[ $numElements == 0 ]]; then
        log_verbose "No language elements found in Managed Configuration Profile... Using defaults"
    else
        log_verbose "Language elements found in Managed Configuration Profile... Checking for matching language"
    for (( elements=0; elements<numElements; elements++ )); do
    
        #lang=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:language" "$appAutoPatchManagedPLIST.plist")
        lang="$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:language" "$appAutoPatchManagedPLIST.plist")"
        log_verbose "Found Language $lang in Managed Config Profile"
        if [ "$lang" = "${langUser}" ]; then
            # Print the entire dictionary (or a specific key as needed)
            /usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements" "$appAutoPatchManagedPLIST.plist"
            # If you want a specific key, e.g., customDeferralButtonText:
            
            # local display_string_defer_today_button_managed
            display_string_defer_today_button_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_defer_today_button" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_defer_tomorrow_button_managed
            display_string_defer_tomorrow_button_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_defer_tomorrow_button" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_defer_future_button_managed
            display_string_defer_future_button_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_defer_future_button" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_minutes_managed
            display_string_minutes_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_minutes" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_hour_managed
            display_string_hour_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_hour" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_hours_managed
            display_string_hours_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_hours" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_and_managed
            display_string_and_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_and" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_days_managed
            display_string_days_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_days" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_times_managed
            display_string_times_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_times" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_there_are_managed
            display_string_there_are_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_there_are" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_discovery_message_managed
            display_string_discovery_message_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_discovery_message" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_discovery_action_message_managed
            display_string_discovery_action_message_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_discovery_action_message" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_discovery_progress_managed
            display_string_discovery_progress_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_discovery_progress" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_button1_managed
            display_string_deferral_button1_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_button1" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_button2_managed
            display_string_deferral_button2_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_button2" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_infobox1_managed
            display_string_deferral_infobox1_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_infobox1" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_infobox2_managed
            display_string_deferral_infobox2_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_infobox2" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_infobox3_managed
            display_string_deferral_infobox3_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_infobox3" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_message_01_managed
            display_string_deferral_message_01_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_message_01" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_message_02_managed
            display_string_deferral_message_02_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_message_02" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferral_unlimited_managed
            display_string_deferral_unlimited_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferral_unlimited" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferraldeadline_button1_managed
            display_string_deferraldeadline_button1_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferraldeadline_button1" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferraldeadline_button2_managed
            display_string_deferraldeadline_button2_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferraldeadline_button2" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferraldeadline_infobox_managed
            display_string_deferraldeadline_infobox_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferraldeadline_infobox" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_deferraldeadline_message_deadline_managed
            display_string_deferraldeadline_message_deadline_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_deferraldeadline_message_deadline" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_patching_button1_managed
            display_string_patching_button1_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_patching_button1" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_patching_checking_managed
            display_string_patching_checking_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_patching_checking" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_patching_progress_managed
            display_string_patching_progress_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_patching_progress" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_patching_infobox_computer_name_managed
            display_string_patching_infobox_computer_name_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_patching_infobox_computer_name" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_patching_infobox_macos_version_managed
            display_string_patching_infobox_macos_version_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_patching_infobox_macos_version" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_patching_infobox_updates_managed
            display_string_patching_infobox_updates_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_patching_infobox_updates" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_patching_message_managed
            display_string_patching_message_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_patching_message" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_complete_progress_managed
            display_string_complete_progress_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_complete_progress" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_uptodate_button1_managed
            display_string_uptodate_button1_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_uptodate_button1" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_uptodate_message_managed
            display_string_uptodate_message_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_uptodate_message" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_intro_managed
            display_string_help_message_intro_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_intro" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_telephone_managed
            display_string_help_message_telephone_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_telephone" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_email_managed
            display_string_help_message_email_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_email" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_help_website_managed
            display_string_help_message_help_website_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_help_website" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_computer_info_managed
            display_string_help_message_computer_info_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_computer_info" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_operating_system_managed
            display_string_help_message_operating_system_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_operating_system" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_serial_managed
            display_string_help_message_serial_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_serial" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_dialog_managed
            display_string_help_message_dialog_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_dialog" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_started_managed
            display_string_help_message_started_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_started" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
            # local display_string_help_message_script_version_managed
            display_string_help_message_script_version_managed=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:$elements:display_string_help_message_script_version" "$appAutoPatchManagedPLIST.plist" 2>/dev/null)
        fi
        
    done
        fi
    
    
#   if [[ -n "${display_string_defer_today_button_managed}" ]]; then
#       #display_string_defer_future_button=$display_string_defer_future_button_managed
#       display_string_defer_today_button="${display_string_defer_today_button_managed}"
#   fi
    
    
    [[ -n "${display_string_defer_today_button_managed}" ]] && display_string_defer_today_button="${display_string_defer_today_button_managed}"
    # [[ -z "${display_string_defer_today_button_managed}" ]] && display_string_defer_today_button="${display_string_defer_today_button}"
    [[ -n "${display_string_defer_tomorrow_button_managed}" ]] && display_string_defer_tomorrow_button="${display_string_defer_tomorrow_button_managed}"
    # [[ -z "${display_string_defer_tomorrow_button_managed}" ]] && display_string_defer_tomorrow_button="${display_string_defer_tomorrow_button}"
    [[ -n "${display_string_defer_future_button_managed}" ]] && display_string_defer_future_button="${display_string_defer_future_button_managed}"
    # [[ -z "${display_string_defer_future_button_managed}" ]] && display_string_defer_future_button="${display_string_defer_future_button}"
    [[ -n "${display_string_minutes_managed}" ]] && display_string_minutes="${display_string_minutes_managed}"
    # [[ -z "${display_string_minutes_managed}" ]] && display_string_minutes="${display_string_minutes}"
    [[ -n "${display_string_hour_managed}" ]] && display_string_hour="${display_string_hour_managed}"
    # [[ -z "${display_string_hour_managed}" ]] && display_string_hour="${display_string_hour}"
    [[ -n "${display_string_hours_managed}" ]] && display_string_hours="${display_string_hours_managed}"
    # [[ -z "${display_string_hours_managed}" ]] && display_string_hours="${display_string_hours}"
    [[ -n "${display_string_and_managed}" ]] && display_string_and="${display_string_and_managed}"
    # [[ -z "${display_string_and_managed}" ]] && display_string_and="${display_string_and}"
    [[ -n "${display_string_days_managed}" ]] && display_string_days="${display_string_days_managed}"
    # [[ -z "${display_string_days_managed}" ]] && display_string_days="${display_string_days}"
    [[ -n "${display_string_times_managed}" ]] && display_string_times="${display_string_times_managed}"
    # [[ -z "${display_string_times_managed}" ]] && display_string_times="${display_string_times}"
    [[ -n "${display_string_there_are_managed}" ]] && display_string_there_are="${display_string_there_are_managed}"
    # [[ -z "${display_string_there_are_managed}" ]] && display_string_there_are="${display_string_there_are}"
    [[ -n "${display_string_discovery_message_managed}" ]] && display_string_discovery_message="${display_string_discovery_message_managed}"
    # [[ -z "${display_string_discovery_message_managed}" ]] && display_string_discovery_message="${display_string_discovery_message}"
    [[ -n "${display_string_discovery_action_message_managed}" ]] && display_string_discovery_action_message="${display_string_discovery_action_message_managed}"
    # [[ -z "${display_string_discovery_action_message_managed}" ]] && display_string_discovery_action_message="${display_string_discovery_action_message}"
    [[ -n "${display_string_discovery_progress_managed}" ]] && display_string_discovery_progress="${display_string_discovery_progress_managed}"
    # [[ -z "${display_string_discovery_progress_managed}" ]] && display_string_discovery_progress="${display_string_discovery_progress}"
    [[ -n "${display_string_deferral_button1_managed}" ]] && display_string_deferral_button1="${display_string_deferral_button1_managed}"
    # [[ -z "${display_string_deferral_button1_managed}" ]] && display_string_deferral_button1="${display_string_deferral_button1}"
    [[ -n "${display_string_deferral_button2_managed}" ]] && display_string_deferral_button2="${display_string_deferral_button2_managed}"
    # [[ -z "${display_string_deferral_button2_managed}" ]] && display_string_deferral_button2="${display_string_deferral_button2}"
    [[ -n "${display_string_deferral_infobox1_managed}" ]] && display_string_deferral_infobox1="${display_string_deferral_infobox1_managed}"
    # [[ -z "${display_string_deferral_infobox1_managed}" ]] && display_string_deferral_infobox1="${display_string_deferral_infobox1}"
    [[ -n "${display_string_deferral_infobox2_managed}" ]] && display_string_deferral_infobox2="${display_string_deferral_infobox2_managed}"
    # [[ -z "${display_string_deferral_infobox2_managed}" ]] && display_string_deferral_infobox2="${display_string_deferral_infobox2}"
    [[ -n "${display_string_deferral_infobox3_managed}" ]] && display_string_deferral_infobox3="${display_string_deferral_infobox3_managed}"
    # [[ -z "${display_string_deferral_infobox3_managed}" ]] && display_string_deferral_infobox3="${display_string_deferral_infobox3}"
    [[ -n "${display_string_deferral_message_01_managed}" ]] && display_string_deferral_message_01="${display_string_deferral_message_01_managed}"
    # [[ -z "${display_string_deferral_message_01_managed}" ]] && display_string_deferral_message_01="${display_string_deferral_message_01}"
    [[ -n "${display_string_deferral_message_02_managed}" ]] && display_string_deferral_message_02="${display_string_deferral_message_02_managed}"
    # [[ -z "${display_string_deferral_message_02_managed}" ]] && display_string_deferral_message_02="${display_string_deferral_message_02}"
    [[ -n "${display_string_deferral_unlimited_managed}" ]] && display_string_deferral_unlimited="${display_string_deferral_unlimited_managed}"
    # [[ -z "${display_string_deferral_unlimited_managed}" ]] && display_string_deferral_unlimited="${display_string_deferral_unlimited}"
    [[ -n "${display_string_deferraldeadline_button1_managed}" ]] && display_string_deferraldeadline_button1="${display_string_deferraldeadline_button1_managed}"
    # [[ -z "${display_string_deferraldeadline_button1_managed}" ]] && display_string_deferraldeadline_button1="${display_string_deferraldeadline_button1}"
    [[ -n "${display_string_deferraldeadline_button2_managed}" ]] && display_string_deferraldeadline_button2="${display_string_deferraldeadline_button2_managed}"
    # [[ -z "${display_string_deferraldeadline_button2_managed}" ]] && display_string_deferraldeadline_button2="${display_string_deferraldeadline_button2}"
    [[ -n "${display_string_deferraldeadline_infobox_managed}" ]] && display_string_deferraldeadline_infobox="${display_string_deferraldeadline_infobox_managed}"
    # [[ -z "${display_string_deferraldeadline_infobox_managed}" ]] && display_string_deferraldeadline_infobox="${display_string_deferraldeadline_infobox}"
    [[ -n "${display_string_deferraldeadline_message_deadline_managed}" ]] && display_string_deferraldeadline_message_deadline="${display_string_deferraldeadline_message_deadline_managed}"
    # [[ -z "${display_string_deferraldeadline_message_deadline_managed}" ]] && display_string_deferraldeadline_message_deadline="${display_string_deferraldeadline_message_deadline}"
    [[ -n "${display_string_patching_button1_managed}" ]] && display_string_patching_button1="${display_string_patching_button1_managed}"
    # [[ -z "${display_string_patching_button1_managed}" ]] && display_string_patching_button1="${display_string_patching_button1}"
    [[ -n "${display_string_patching_checking_managed}" ]] && display_string_patching_checking="${display_string_patching_checking_managed}"
    # [[ -z "${display_string_patching_checking_managed}" ]] && display_string_patching_checking="${display_string_patching_checking}"
    [[ -n "${display_string_patching_progress_managed}" ]] && display_string_patching_progress="${display_string_patching_progress_managed}"
    # [[ -z "${display_string_patching_progress_managed}" ]] && display_string_patching_progress="${display_string_patching_progress}"
    [[ -n "${display_string_patching_infobox_computer_name_managed}" ]] && display_string_patching_infobox_computer_name="${display_string_patching_infobox_computer_name_managed}"
    # [[ -z "${display_string_patching_infobox_computer_name_managed}" ]] && display_string_patching_infobox_computer_name="${display_string_patching_infobox_computer_name}"
    [[ -n "${display_string_patching_infobox_macos_version_managed}" ]] && display_string_patching_infobox_macos_version="${display_string_patching_infobox_macos_version_managed}"
    # [[ -z "${display_string_patching_infobox_macos_version_managed}" ]] && display_string_patching_infobox_macos_version="${display_string_patching_infobox_macos_version}"
    [[ -n "${display_string_patching_infobox_updates_managed}" ]] && display_string_patching_infobox_updates="${display_string_patching_infobox_updates_managed}"
    # [[ -z "${display_string_patching_infobox_updates_managed}" ]] && display_string_patching_infobox_updates="${display_string_patching_infobox_updates}"
    [[ -n "${display_string_patching_message_managed}" ]] && display_string_patching_message="${display_string_patching_message_managed}"
    # [[ -z "${display_string_patching_message_managed}" ]] && display_string_patching_message="${display_string_patching_message}"
    [[ -n "${display_string_complete_progress_managed}" ]] && display_string_complete_progress="${display_string_complete_progress_managed}"
    # [[ -z "${display_string_complete_progress_managed}" ]] && display_string_complete_progress="${display_string_complete_progress}"
    [[ -n "${display_string_uptodate_button1_managed}" ]] && display_string_uptodate_button1="${display_string_uptodate_button1_managed}"
    # [[ -z "${display_string_uptodate_button1_managed}" ]] && display_string_uptodate_button1="${display_string_uptodate_button1}"
    [[ -n "${display_string_uptodate_message_managed}" ]] && display_string_uptodate_message="${display_string_uptodate_message_managed}"
    # [[ -z "${display_string_uptodate_message_managed}" ]] && display_string_uptodate_message="${display_string_uptodate_message}"
    [[ -n "${display_string_help_message_intro_managed}" ]] && display_string_help_message_intro="${display_string_help_message_intro_managed}"
    # [[ -z "${display_string_help_message_intro_managed}" ]] && display_string_help_message_intro="${display_string_help_message_intro}"
    [[ -n "${display_string_help_message_telephone_managed}" ]] && display_string_help_message_telephone="${display_string_help_message_telephone_managed}"
    # [[ -z "${display_string_help_message_telephone_managed}" ]] && display_string_help_message_telephone="${display_string_help_message_telephone}"
    [[ -n "${display_string_help_message_email_managed}" ]] && display_string_help_message_email="${display_string_help_message_email_managed}"
    # [[ -z "${display_string_help_message_email_managed}" ]] && display_string_help_message_email="${display_string_help_message_email}"
    [[ -n "${display_string_help_message_help_website_managed}" ]] && display_string_help_message_help_website="${display_string_help_message_help_website_managed}"
    # [[ -z "${display_string_help_message_help_website_managed}" ]] && display_string_help_message_help_website="${display_string_help_message_help_website}"
    [[ -n "${display_string_help_message_computer_info_managed}" ]] && display_string_help_message_computer_info="${display_string_help_message_computer_info_managed}"
    # [[ -z "${display_string_help_message_computer_info_managed}" ]] && display_string_help_message_computer_info="${display_string_help_message_computer_info}"
    [[ -n "${display_string_help_message_operating_system_managed}" ]] && display_string_help_message_operating_system="${display_string_help_message_operating_system_managed}"
    # [[ -z "${display_string_help_message_operating_system_managed}" ]] && display_string_help_message_operating_system="${display_string_help_message_operating_system}"
    [[ -n "${display_string_help_message_serial_managed}" ]] && display_string_help_message_serial="${display_string_help_message_serial_managed}"
    # [[ -z "${display_string_help_message_serial_managed}" ]] && display_string_help_message_serial="${display_string_help_message_serial}"
    [[ -n "${display_string_help_message_dialog_managed}" ]] && display_string_help_message_dialog="${display_string_help_message_dialog_managed}"
    # [[ -z "${display_string_help_message_dialog_managed}" ]] && display_string_help_message_dialog="${display_string_help_message_dialog}"
    [[ -n "${display_string_help_message_started_managed}" ]] && display_string_help_message_started="${display_string_help_message_started_managed}"
    # [[ -z "${display_string_help_message_started_managed}" ]] && display_string_help_message_started="${display_string_help_message_started}"
    [[ -n "${display_string_help_message_script_version_managed}" ]] && display_string_help_message_script_version="${display_string_help_message_script_version_managed}"
    # [[ -z "${display_string_help_message_script_version_managed}" ]] && display_string_help_message_script_version="${display_string_help_message_script_version}"
    
    log_verbose "display_string_defer_today_button: $display_string_defer_today_button"
    log_verbose "display_string_defer_tomorrow_button: $display_string_defer_tomorrow_button"
    log_verbose "display_string_defer_future_button: $display_string_defer_future_button"
    log_verbose "display_string_minutes: $display_string_minutes"
    log_verbose "display_string_hour: $display_string_hour"
    log_verbose "display_string_hours: $display_string_hours"
    log_verbose "display_string_and: $display_string_and"
    log_verbose "display_string_days: $display_string_days"
    log_verbose "display_string_times: $display_string_times"
    log_verbose "display_string_there_are: $display_string_there_are"
    log_verbose "display_string_discovery_message: $display_string_discovery_message"
    log_verbose "display_string_discovery_action_message: $display_string_discovery_action_message"
    log_verbose "display_string_discovery_progress: $display_string_discovery_progress"
    log_verbose "display_string_deferral_button1: $display_string_deferral_button1"
    log_verbose "display_string_deferral_button2: $display_string_deferral_button2"
    log_verbose "display_string_deferral_infobox1: $display_string_deferral_infobox1"
    log_verbose "display_string_deferral_infobox2: $display_string_deferral_infobox2"
    log_verbose "display_string_deferral_infobox3: $display_string_deferral_infobox3"
    log_verbose "display_string_deferral_message_01: $display_string_deferral_message_01"
    log_verbose "display_string_deferral_message_02: $display_string_deferral_message_02"
    log_verbose "display_string_deferral_unlimited: $display_string_deferral_unlimited"
    log_verbose "display_string_deferraldeadline_button1: $display_string_deferraldeadline_button1"
    log_verbose "display_string_deferraldeadline_button2: $display_string_deferraldeadline_button2"
    log_verbose "display_string_deferraldeadline_infobox: $display_string_deferraldeadline_infobox"
    log_verbose "display_string_deferraldeadline_message_deadline: $display_string_deferraldeadline_message_deadline"
    log_verbose "display_string_patching_button1: $display_string_patching_button1"
    log_verbose "display_string_patching_checking: $display_string_patching_checking"
    log_verbose "display_string_patching_progress: $display_string_patching_progress"
    log_verbose "display_string_patching_infobox_computer_name: $display_string_patching_infobox_computer_name"
    log_verbose "display_string_patching_infobox_macos_version: $display_string_patching_infobox_macos_version"
    log_verbose "display_string_patching_infobox_updates: $display_string_patching_infobox_updates"
    log_verbose "display_string_patching_message: $display_string_patching_message"
    log_verbose "display_string_complete_progress: $display_string_complete_progress"
    log_verbose "display_string_uptodate_button1: $display_string_uptodate_button1"
    log_verbose "display_string_uptodate_message: $display_string_uptodate_message"
    log_verbose "display_string_help_message_intro: $display_string_help_message_intro"
    log_verbose "display_string_help_message_telephone: $display_string_help_message_telephone"
    log_verbose "display_string_help_message_email: $display_string_help_message_email"
    log_verbose "display_string_help_message_help_website: $display_string_help_message_help_website"
    log_verbose "display_string_help_message_computer_info: $display_string_help_message_computer_info"
    log_verbose "display_string_help_message_operating_system: $display_string_help_message_operating_system"
    log_verbose "display_string_help_message_serial: $display_string_help_message_serial"
    log_verbose "display_string_help_message_dialog: $display_string_help_message_dialog"
    log_verbose "display_string_help_message_started: $display_string_help_message_started"
    log_verbose "display_string_help_message_script_version: $display_string_help_message_script_version"

}

get_localized_path() {
    itemPath=$1
    langPath="${langUser}"
    
    if [[ "${langUser}" == "zh" ]]; then
        langPath="${langPath}_CN"
    fi
    
    # Check that we have a localization for the detected user language
    if [[ -d "/System/Library/CoreServices/SystemFolderLocalizations/${langPath}.lproj" ]]; then
        
        # Create a temp plist for reading localization values
        aapTempDir=$(/usr/bin/mktemp -d -t "aap-localization")
        ln -s "/System/Library/CoreServices/SystemFolderLocalizations/${langPath}.lproj/SystemFolderLocalizations.strings" "${aapTempDir}/SystemFolderLocalizations.plist"
        
        # Split the path into an array
        pathParts=(${(@s:/:)itemPath})
        for pathItem in $pathParts; do
            pathItemLocalized=$(/usr/bin/defaults read "${aapTempDir}/SystemFolderLocalizations.plist" "$pathItem" 2>/dev/null)
            if [[ -n $pathItemLocalized ]]; then 
                pathLocalized+="/${pathItemLocalized}"
            else
                pathLocalized+="/${pathItem}"
            fi
        done
        
        # Clean up the temp directory and symlink plist
        rm -R "${aapTempDir}"
    else
        # No localization available
        pathLocalized="${itemPath}"
    fi
    # return the localized path
    echo "${pathLocalized}"
}

get_options() {

    write_status "Running: Getting parameter options"
    if [[ "$1" == "/" ]] || [[ $(ps -p "${PPID}" | grep -c -e 'bin/jamf' -e 'jamf/bin' -e '\sjamf\s') -gt 0 ]]; then
        parent_process_is_jamf="TRUE"
        if [[ "$1" == "/" ]]; then
        shift 3
        fi
    fi

    while [[ -n "$1" ]]; do
        case "$1" in
            -u|-U|--usage)
                show_usage
            ;;
            -h|-H|--help)
                show_help
            ;;
            --interactiveMode=*)
                InteractiveModeOption="${1##*=}"
            ;;
            --deferral-timer-default=*)
                deferral_timer_default_option="${1##*=}"
            ;;
            --reset-defaults)
                reset_defaults_option="TRUE"
            ;;
            --reset-labels)
                reset_labels_option="TRUE"
            ;;
            --ignored-labels=*)
                ignored_labels_option="${1##*=}"
            ;;
            --required-labels=*)
                required_labels_option="${1##*=}"
            ;;
            --optional-labels=*)
                optional_labels_option="${1##*=}"
            ;;
            -V|--verbose-mode)
                verbose_mode_option="TRUE"
            ;;
            -v|--verbose-mode-off)
                verbose_mode_option="FALSE"
            ;;
            -D|--debug-mode)
                debug_mode_option="TRUE"
            ;;
            -d|--debug-mode-off)
                debug_mode_option="FALSE"
            ;;
            --deferral-timer-menu=*)
                deferral_timer_menu_option="${1##*=}"
            ;;
            --deferral-timer-focus=*)
                deferral_timer_focus_option="${1##*=}"
            ;;
            --deferral-timer-error=*)
                deferral_timer_error_option="${1##*=}"
            ;;
            --deferral-timer-workflow-relaunch=*)
                deferral_timer_workflow_relaunch_option="${1##*=}"
            ;;
            --deferral-timer-reset-all)
                deferral_timer_reset_all_option="TRUE"
            ;;
            --deadline-count-focus=*)
                deadline_count_focus_option="${1##*=}"
            ;;
            --deadline-count-hard=*)
                deadline_count_hard_option="${1##*=}"
            ;;
            --deadline-count-delete-all)
                deadline_count_delete_all_option="TRUE"
            ;;
            --deadline-days-focus=*)
                deadline_days_focus_option="${1##*=}"
            ;;
            --deadline-days-hard=*)
                deadline_days_hard_option="${1##*=}"
            ;;
            --deadline-days-restart-all)
                deadline_days_restart_all_option="TRUE"
            ;;
            --deadline-days-delete-all)
                deadline_days_delete_all_option="TRUE"
            ;;
            --patch-week-start-day=*)
                patch_week_start_day_option="${1##*=}"
            ;;
            --days-until-reset=*)
                days_until_reset_option="${1##*=}"
            ;;
            --workflow-disable-app-discovery)
                workflow_disable_app_discovery_option="TRUE"
            ;;
            --workflow-disable-app-discovery-off)
                workflow_disable_app_discovery_option="FALSE"
            ;;
            --workflow-install-now)
                workflow_install_now_option="TRUE"
            ;;
            --workflow-install-now-silent)
                workflow_install_now_silent_option="TRUE"
            ;;
            --workflow-install-now-patching-status-action-never)
                workflow_install_now_patching_status_action_option="NEVER"
            ;;
            --workflow-install-now-patching-status-action-always)
                workflow_install_now_patching_status_action_option="ALWAYS"
            ;;
            --workflow-install-now-patching-status-action-success)
                workflow_install_now_patching_status_action_option="SUCCESS"
            ;;
            --workflow-disable-relaunch)
                workflow_disable_relaunch_option="TRUE"
            ;;
            --workflow-disable-relaunch-off)
                workflow_disable_relaunch_option="FALSE"
            ;;
            --webhook-feature-off)
                webhook_feature_option="FALSE"
            ;;
            --webhook-feature-all)
                webhook_feature_option="ALL"
            ;;
            --webhook-feature-failures)
                webhook_feature_option="FAILURES"
            ;;
            --webhook-url-slack=*)
                webhook_url_slack_option="${1##*=}"
            ;;
            --webhook-url-teams=*)
                webhook_url_teams_option="${1##*=}"
            ;;
            --webhook-url-zoom=*)
                webhook_url_zoom_option="${1#*=}"
            ;;
            --webhook-url-zoom-verification-token=*)
                webhook_url_zoom_verification_token_option="${1##*=}"
            ;;
            --uninstall)
                uninstall_app_auto_patch
            ;;
            --version)
                show_version
            ;;
            --vers)
                show_version_short
            ;;
            *)
                unrecognized_options_array+=("$1")
            ;;  
        esac
        shift
    done

    [[ -n "${unrecognized_options_array[*]}" ]] && show_usage

}

get_preferences() {

    write_status "Running: Collecting preferences"
    
    # Get current local user
    currentUserAccountName=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ {$1=$2="";print $0;}' | xargs)
    # Get language setting for current local user
    langUser=$(su - ${currentUserAccountName} -c "/usr/bin/defaults read -g AppleLocale | cut -d'_' -f1")
    if [[ "${reset_defaults_option}" == "TRUE" ]]; then
        log_status "Resetting defaults for App Auto Patch"

        defaults delete "${appAutoPatchLocalPLIST}"
        defaults write "${appAutoPatchLocalPLIST}" AAPVersion -string "${scriptVersion}"
        defaults write "${appAutoPatchLocalPLIST}" MacLastStartup -string "${mac_last_startup}"
        defaults write "${appAutoPatchLocalPLIST}" InteractiveMode -integer "${InteractiveMode}"
        [[ "${verbose_mode_option}" == "TRUE" ]] && defaults write "${appAutoPatchLocalPLIST}" VerboseMode -bool true
        [[ "${debug_mode_option}" == "TRUE" ]] && defaults write "${appAutoPathLocalPLIST}" DebugMode -bool true
        rm -f "${WORKFLOW_INSTALL_NOW_FILE}" 2> /dev/null
        rm -f "${WORKFLOW_INSTALL_NOW_SILENT_FILE}" 2> /dev/null
        
    else
        if [[ "${deferral_timer_reset_all_option}" == "TRUE" ]]; then
            log_status "Resetting all local deferral timer preferences."
            defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerDefault 2> /dev/null
            defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerMenu 2> /dev/null
            defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerFocus 2> /dev/null
            defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerError 2> /dev/null
            defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerWorkflowRelaunch 2> /dev/null
        fi
        if [[ "${deadline_count_delete_all_option}" == "TRUE" ]]; then
            log_status "Deleting all local deadline count preferences."
            defaults delete "${appAutoPatchLocalPLIST}" DeadlineCountFocus 2> /dev/null
            defaults delete "${appAutoPatchLocalPLIST}" DeadlineCountHard 2> /dev/null
        fi
        if [[ "${deadline_days_delete_all_option}" == "TRUE" ]]; then
            log_status "Status: Deleting all local deadline days preferences."
            defaults delete "${appAutoPatchLocalPLIST}" DeadlineDaysFocus 2>/dev/null
            defaults delete "${appAutoPatchLocalPLIST}" DeadlineDaysHard 2>/dev/null
        fi
        
        log_status "Continuing to gather new preferences"
    fi


    # Collect Managed PLIST preferences if any
    if [[ -f ${appAutoPatchManagedPLIST}.plist ]]; then
        log_verbose "Managed preference file: ${appAutoPatchManagedPLIST}:\n$(defaults read "${appAutoPatchManagedPLIST}" 2> /dev/null)"
        local deferral_timer_default_managed
        deferral_timer_default_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeferralTimerDefault 2> /dev/null)
        local deferral_timer_menu_managed
        deferral_timer_menu_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeferralTimerMenu 2>/dev/null)
        local deferral_timer_focus_managed
        deferral_timer_focus_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeferralTimerFocus 2> /dev/null)
        local deferral_timer_error_managed
        deferral_timer_error_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeferralTimerError 2> /dev/null)
        local deferral_timer_workflow_relaunch_managed
        deferral_timer_workflow_relaunch_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeferralTimerWorkflowRelaunch 2>/dev/null)
        local deadline_count_focus_managed
        deadline_count_focus_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeadlineCountFocus 2> /dev/null)
        local deadline_count_hard_managed
        deadline_count_hard_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeadlineCountHard 2> /dev/null)
        local deadline_days_focus_managed
        deadline_days_focus_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeadlineDaysFocus 2>/dev/null)
        local deadline_days_hard_managed
        deadline_days_hard_managed=$(defaults read "${appAutoPatchManagedPLIST}" DeadlineDaysHard 2>/dev/null)
        local interactive_mode_managed
        interactive_mode_managed=$(defaults read "${appAutoPatchManagedPLIST}" InteractiveMode 2> /dev/null)
        local patch_week_start_day_managed
        patch_week_start_day_managed=$(defaults read "${appAutoPatchManagedPLIST}" PatchWeekStartDay 2> /dev/null)
        local workflow_disable_app_discovery_managed
        workflow_disable_app_discovery_managed=$(defaults read "${appAutoPatchManagedPLIST}" WorkflowDisableAppDiscovery 2> /dev/null)
        local workflow_disable_relaunch_managed
        workflow_disable_relaunch_managed=$(defaults read "${appAutoPatchManagedPLIST}" WorkflowDisableRelaunch 2>/dev/null)
        local webhook_feature_managed
        webhook_feature_managed=$(defaults read "${appAutoPatchManagedPLIST}" WebhookFeature 2> /dev/null)
        local webhook_url_slack_managed
        webhook_url_slack_managed=$(defaults read "${appAutoPatchManagedPLIST}" WebhookURLSlack 2> /dev/null)
        local webhook_url_teams_managed
        webhook_url_teams_managed=$(defaults read "${appAutoPatchManagedPLIST}" WebhookURLTeams 2> /dev/null)
        local webhook_url_zoom_managed
        webhook_url_zoom_managed=$(defaults read "${appAutoPatchManagedPLIST}" WebhookURLZoom 2> /dev/null)
        local webhook_url_zoom_verification_token_managed
        webhook_url_zoom_verification_token_managed=$(defaults read "${appAutoPatchManagedPLIST}" WebhookURLZoomSecret 2> /dev/null)
        local ignored_labels_managed
        ignored_labels_managed=$(defaults read "${appAutoPatchManagedPLIST}" IgnoredLabels 2> /dev/null)
        local required_labels_managed
        required_labels_managed=$(defaults read "${appAutoPatchManagedPLIST}" RequiredLabels 2> /dev/null)
        local optional_labels_managed
        optional_labels_managed=$(defaults read "${appAutoPatchManagedPLIST}" OptionalLabels 2> /dev/null)
        local app_title_managed
        app_title_managed=$(defaults read "${appAutoPatchManagedPLIST}" AppTitle 2> /dev/null)
        local convert_apps_in_home_folder_managed
        convert_apps_in_home_folder_managed=$(defaults read "${appAutoPatchManagedPLIST}" ConvertAppsInHomeFolder 2> /dev/null)
        local ignore_apps_in_home_folder_managed
        ignore_apps_in_home_folder_managed=$(defaults read "${appAutoPatchManagedPLIST}" IgnoreAppsInHomeFolder 2> /dev/null)
        local installomator_options_managed
        installomator_options_managed=$(defaults read "${appAutoPatchManagedPLIST}" InstallomatorOptions 2> /dev/null)
        local installomator_update_disable_managed
        installomator_update_disable_managed=$(defaults read "${appAutoPatchManagedPLIST}" InstallomatorUpdateDisable 2> /dev/null)
        local installomator_version_managed
        installomator_version_managed=$(defaults read "${appAutoPatchManagedPLIST}" InstallomatorVersion 2> /dev/null)
        local installomator_version_custom_repo_path_managed
        installomator_version_custom_repo_path_managed=$(defaults read "${appAutoPatchManagedPLIST}" InstallomatorVersionCustomRepoPath 2> /dev/null)
        local installomator_version_custom_branch_name_managed
        installomator_version_custom_branch_name_managed=$(defaults read "${appAutoPatchManagedPLIST}" InstallomatorVersionCustomBranchName 2> /dev/null)
        local dialog_timeout_deferral_managed
        dialog_timeout_deferral_managed=$(defaults read "${appAutoPatchManagedPLIST}" DialogTimeoutDeferral 2> /dev/null)
        local dialog_timeout_deferral_action_managed
        dialog_timeout_deferral_action_managed=$(defaults read "${appAutoPatchManagedPLIST}" DialogTimeoutDeferralAction 2> /dev/null)
        local days_until_reset_managed
        days_until_reset_managed=$(defaults read "${appAutoPatchManagedPLIST}" DaysUntilReset 2> /dev/null)
        local Unattended_exit_managed
        Unattended_exit_managed=$(defaults read "${appAutoPatchManagedPLIST}" UnattendedExit 2> /dev/null)
        local Unattended_exit_seconds_managed
        Unattended_exit_seconds_managed=$(defaults read "${appAutoPatchManagedPLIST}" UnattendedExitSeconds 2> /dev/null)
        local dialog_on_top_managed
        dialog_on_top_managed=$(defaults read "${appAutoPatchManagedPLIST}" DialogOnTop 2> /dev/null)
        local workflow_install_now_patching_status_action_managed
        workflow_install_now_patching_status_action_managed=$(defaults read "${appAutoPatchManagedPLIST}" WorkflowInstallNowPatchingStatusAction 2> /dev/null)
        local use_overlay_icon_managed
        use_overlay_icon_managed=$(defaults read "${appAutoPatchManagedPLIST}" UseOverlayIcon 2> /dev/null)
        local remove_installomator_path_managed
        remove_installomator_path_managed=$(defaults read "${appAutoPatchManagedPLIST}" RemoveInstallomatorPath 2> /dev/null)
        local support_team_name_managed
        support_team_name_managed=$(defaults read "${appAutoPatchManagedPLIST}" SupportTeamName 2> /dev/null)
        local support_team_phone_managed
        support_team_phone_managed=$(defaults read "${appAutoPatchManagedPLIST}" SupportTeamPhone 2> /dev/null)
        local support_team_email_managed
        support_team_email_managed=$(defaults read "${appAutoPatchManagedPLIST}" SupportTeamEmail 2> /dev/null)
        local support_team_website_managed
        support_team_website_managed=$(defaults read "${appAutoPatchManagedPLIST}" SupportTeamWebsite 2> /dev/null)
    else
        log_verbose "No managed preference file found for App Auto-Patch"
    fi

    # Collect any local preferences from ${appAutoPatchLocalPLIST}
    if [[ -f ${appAutoPatchLocalPLIST}.plist ]]; then
        # This is where any preferences locally would be collected, example below
        local script_version_local
        script_version_local=$(defaults read "${appAutoPatchLocalPLIST}" AAPVersion 2> /dev/null)
        local deferral_timer_default_local
        deferral_timer_default_local=$(defaults read "${appAutoPatchLocalPLIST}" DeferralTimerDefault 2> /dev/null)
        local deferral_timer_menu_local
        deferral_timer_menu_local=$(defaults read "${appAutoPatchLocalPLIST}" DeferralTimerMenu 2>/dev/null)
        local deferral_timer_focus_local
        deferral_timer_focus_local=$(defaults read "${appAutoPatchLocalPLIST}" DeferralTimerFocus 2> /dev/null)
        local deferral_timer_error_local
        deferral_timer_error_local=$(defaults read "${appAutoPatchLocalPLIST}" DeferralTimerError 2> /dev/null)
        local deferral_timer_workflow_relaunch_local
        deferral_timer_workflow_relaunch_local=$(defaults read "${appAutoPatchLocalPLIST}" DeferralTimerWorkflowRelaunch 2>/dev/null)
        local deadline_count_focus_local
        deadline_count_focus_local=$(defaults read "${appAutoPatchLocalPLIST}" DeadlineCountFocus 2> /dev/null)
        local deadline_count_hard_local
        deadline_count_hard_local=$(defaults read "${appAutoPatchLocalPLIST}" DeadlineCountHard 2> /dev/null)
        local deadline_days_focus_local
        deadline_days_focus_local=$(defaults read "${appAutoPatchLocalPLIST}" DeadlineDaysFocus 2>/dev/null)
        local deadline_days_hard_local
        deadline_days_hard_local=$(defaults read "${appAutoPatchLocalPLIST}" DeadlineDaysHard 2>/dev/null)
        local interactive_mode_local
        interactive_mode_local=$(defaults read "${appAutoPatchLocalPLIST}" InteractiveMode 2> /dev/null)
        local patch_week_start_day_local
        patch_week_start_day_local=$(defaults read "${appAutoPatchLocalPLIST}" PatchWeekStartDay 2> /dev/null)
        local workflow_disable_app_discovery_local
        workflow_disable_app_discovery_local=$(defaults read "${appAutoPatchLocalPLIST}" WorkflowDisableAppDiscovery 2> /dev/null)
        local workflow_disable_relaunch_local
        workflow_disable_relaunch_local=$(defaults read "${appAutoPatchLocalPLIST}" WorkflowDisableRelaunch 2>/dev/null)
        local webhook_feature_local
        webhook_feature_local=$(defaults read "${appAutoPatchLocalPLIST}" WebhookFeature 2> /dev/null)
        local webhook_url_slack_local
        webhook_url_slack_local=$(defaults read "${appAutoPatchLocalPLIST}" WebhookURLSlack 2> /dev/null)
        local webhook_url_teams_local
        webhook_url_teams_local=$(defaults read "${appAutoPatchLocalPLIST}" WebhookURLTeams 2> /dev/null)
        local webhook_url_zoom_local
        webhook_url_zoom_local=$(defaults read "${appAutoPatchLocalPLIST}" WebhookURLZoom 2> /dev/null)
        local webhook_url_zoom_verification_token_local
        webhook_url_zoom_verification_token_local=$(defaults read "${appAutoPatchLocalPLIST}" WebhookURLZoomVerificationToken 2> /dev/null)
        local ignored_labels_local
        ignored_labels_local=$(defaults read "${appAutoPatchLocalPLIST}" IgnoredLabels 2> /dev/null)
        local required_labels_local
        required_labels_local=$(defaults read "${appAutoPatchLocalPLIST}" RequiredLabels 2> /dev/null)
        local optional_labels_local
        optional_labels_local=$(defaults read "${appAutoPatchLocalPLIST}" OptionalLabels 2> /dev/null)
        local app_title_local
        app_title_local=$(defaults read "${appAutoPatchLocalPLIST}" AppTitle 2> /dev/null)
        local convert_apps_in_home_folder_local
        convert_apps_in_home_folder_local=$(defaults read "${appAutoPatchLocalPLIST}" ConvertAppsInHomeFolder 2> /dev/null)
        local ignore_apps_in_home_folder_local
        ignore_apps_in_home_folder_local=$(defaults read "${appAutoPatchLocalPLIST}" IgnoreAppsInHomeFolder 2> /dev/null)
        local installomator_options_local
        installomator_options_local=$(defaults read "${appAutoPatchLocalPLIST}" InstallomatorOptions 2> /dev/null)
        local installomator_update_disable_local
        installomator_update_disable_local=$(defaults read "${appAutoPatchLocalPLIST}" InstallomatorUpdateDisable 2> /dev/null)
        local installomator_version_local
        installomator_version_local=$(defaults read "${appAutoPatchLocalPLIST}" InstallomatorVersion 2> /dev/null)
        local installomator_version_custom_repo_path_local
        installomator_version_custom_repo_path_local=$(defaults read "${appAutoPatchLocalPLIST}" InstallomatorVersionCustomRepoPath 2> /dev/null)
        local installomator_version_custom_branch_name_local
        installomator_version_custom_branch_name_local=$(defaults read "${appAutoPatchLocalPLIST}" InstallomatorVersionCustomBranchName 2> /dev/null)
        local dialog_timeout_deferral_local
        dialog_timeout_deferral_local=$(defaults read "${appAutoPatchLocalPLIST}" DialogTimeoutDeferral 2> /dev/null)
        local dialog_timeout_deferral_action_local
        dialog_timeout_deferral_action_local=$(defaults read "${appAutoPatchLocalPLIST}" DialogTimeoutDeferralAction 2> /dev/null)
        local days_until_reset_local
        days_until_reset_local=$(defaults read "${appAutoPatchLocalPLIST}" DaysUntilReset 2> /dev/null)
        local Unattended_exit_local
        Unattended_exit_local=$(defaults read "${appAutoPatchLocalPLIST}" UnattendedExit 2> /dev/null)
        local Unattended_exit_seconds_local
        Unattended_exit_seconds_local=$(defaults read "${appAutoPatchLocalPLIST}" UnattendedExitSeconds 2> /dev/null)
        local dialog_on_top_local
        dialog_on_top_local=$(defaults read "${appAutoPatchLocalPLIST}" DialogOnTop 2> /dev/null)
        local workflow_install_now_patching_status_action_local
        workflow_install_now_patching_status_action_local=$(defaults read "${appAutoPatchLocalPLIST}" WorkflowInstallNowPatchingStatusAction 2> /dev/null)
        local use_overlay_icon_local
        use_overlay_icon_local=$(defaults read "${appAutoPatchLocalPLIST}" UseOverlayIcon 2> /dev/null)
        local remove_installomator_path_local
        remove_installomator_path_local=$(defaults read "${appAutoPatchLocalPLIST}" RemoveInstallomatorPath 2> /dev/null)
        local support_team_name_local
        support_team_name_local=$(defaults read "${appAutoPatchLocalPLIST}" SupportTeamName 2> /dev/null)
        local support_team_phone_local
        support_team_phone_local=$(defaults read "${appAutoPatchLocalPLIST}" SupportTeamPhone 2> /dev/null)
        local support_team_email_local
        support_team_email_local=$(defaults read "${appAutoPatchLocalPLIST}" SupportTeamEmail 2> /dev/null)
        local support_team_website_local
        support_team_website_local=$(defaults read "${appAutoPatchLocalPLIST}" SupportTeamWebsite 2> /dev/null)
    fi
    
    log_verbose  "Local preference file before startup validation: ${appAutoPatchLocalPLIST}:\n$(defaults read "${appAutoPatchLocalPLIST}" 2> /dev/null)"

    # Need logic to ensures the priority order of managed preference overrides the new input option which overrides the saved local preference.
    [[ -n "${deferral_timer_menu_managed}" ]] && deferral_timer_menu_option="${deferral_timer_menu_managed}"
    { [[ -z "${deferral_timer_menu_managed}" ]] && [[ -z "${deferral_timer_menu_option}" ]] && [[ -n "${deferral_timer_menu_local}" ]]; } && deferral_timer_menu_option="${deferral_timer_menu_local}"
    [[ -n "${deferral_timer_focus_managed}" ]] && deferral_timer_focus_option="${deferral_timer_focus_managed}"
    { [[ -z "${deferral_timer_focus_managed}" ]] && [[ -z "${deferral_timer_focus_option}" ]] && [[ -n "${deferral_timer_focus_local}" ]]; } && deferral_timer_focus_option="${deferral_timer_focus_local}"
    [[ -n "${deferral_timer_error_managed}" ]] && deferral_timer_error_option="${deferral_timer_error_managed}"
    { [[ -z "${deferral_timer_error_managed}" ]] && [[ -z "${deferral_timer_error_option}" ]] && [[ -n "${deferral_timer_error_local}" ]]; } && deferral_timer_error_option="${deferral_timer_error_local}"
    [[ -n "${deferral_timer_workflow_relaunch_managed}" ]] && deferral_timer_workflow_relaunch_option="${deferral_timer_workflow_relaunch_managed}"
    { [[ -z "${deferral_timer_workflow_relaunch_managed}" ]] && [[ -z "${deferral_timer_workflow_relaunch_option}" ]] && [[ -n "${deferral_timer_workflow_relaunch_local}" ]]; } && deferral_timer_workflow_relaunch_option="${deferral_timer_workflow_relaunch_local}"
    [[ -n "${deadline_count_focus_managed}" ]] && deadline_count_focus_option="${deadline_count_focus_managed}"
    { [[ -z "${deadline_count_focus_managed}" ]] && [[ -z "${deadline_count_focus_option}" ]] && [[ -n "${deadline_count_focus_local}" ]]; } && deadline_count_focus_option="${deadline_count_focus_local}"
    [[ -n "${deadline_count_hard_managed}" ]] && deadline_count_hard_option="${deadline_count_hard_managed}"
    { [[ -z "${deadline_count_hard_managed}" ]] && [[ -z "${deadline_count_hard_option}" ]] && [[ -n "${deadline_count_hard_local}" ]]; } && deadline_count_hard_option="${deadline_count_hard_local}"
    
    
    [[ -n "${deadline_days_focus_managed}" ]] && deadline_days_focus_option="${deadline_days_focus_managed}"
    { [[ -z "${deadline_days_focus_managed}" ]] && [[ -z "${deadline_days_focus_option}" ]] && [[ -n "${deadline_days_focus_local}" ]]; } && deadline_days_focus_option="${deadline_days_focus_local}"
    [[ -n "${deadline_days_hard_managed}" ]] && deadline_days_hard_option="${deadline_days_hard_managed}"
    { [[ -z "${deadline_days_hard_managed}" ]] && [[ -z "${deadline_days_hard_option}" ]] && [[ -n "${deadline_days_hard_local}" ]]; } && deadline_days_hard_option="${deadline_days_hard_local}"
    
    
    [[ -n "${deferral_timer_default_managed}" ]] && deferral_timer_default_option="${deferral_timer_default_managed}"
    { [[ -z "${deferral_timer_default_managed}" ]] && [[ -z "${deferral_timer_default_option}" ]] && [[ -n "${deferral_timer_default_local}" ]]; } && deferral_timer_default_option="${deferral_timer_default_local}"
    
    [[ -n "${interactive_mode_managed}" ]] && InteractiveModeOption="${interactive_mode_managed}"
    { [[ -z "${interactive_mode_managed}" ]] && [[ -z "${InteractiveModeOption}" ]] && [[ -n "${interactive_mode_local}" ]]; } && InteractiveModeOption="${interactive_mode_local}"
    
    
    [[ -n "${patch_week_start_day_managed}" ]] && patch_week_start_day_option="${patch_week_start_day_managed}"
    { [[ -z "${patch_week_start_day_managed}" ]] && [[ -z "${patch_week_start_day_option}" ]] && [[ -n "${patch_week_start_day_local}" ]]; } && patch_week_start_day_option="${patch_week_start_day_local}"
    [[ -n "${workflow_disable_app_discovery_managed}" ]] && workflow_disable_app_discovery_option="${workflow_disable_app_discovery_managed}"
    { [[ -z "${workflow_disable_app_discovery_managed}" ]] && [[ -z "${workflow_disable_app_discovery_option}" ]] && [[ -n "${workflow_disable_app_discovery_local}" ]]; } && workflow_disable_app_discovery_option="${workflow_disable_app_discovery_local}"
    [[ -n "${workflow_disable_relaunch_managed}" ]] && workflow_disable_relaunch_option="${workflow_disable_relaunch_managed}"
    { [[ -z "${workflow_disable_relaunch_managed}" ]] && [[ -z "${workflow_disable_relaunch_option}" ]] && [[ -n "${workflow_disable_relaunch_local}" ]]; } && workflow_disable_relaunch_option="${workflow_disable_relaunch_local}"
    [[ -n "${webhook_feature_managed}" ]] && webhook_feature_option="${webhook_feature_managed}"
    { [[ -z "${webhook_feature_managed}" ]] && [[ -z "${webhook_feature_option}" ]] && [[ -n "${webhook_feature_local}" ]]; } && webhook_feature_option="${webhook_feature_local}"
    [[ -n "${webhook_url_slack_managed}" ]] && webhook_url_slack_option="${webhook_url_slack_managed}"
    { [[ -z "${webhook_url_slack_managed}" ]] && [[ -z "${webhook_url_slack_option}" ]] && [[ -n "${webhook_url_slack_local}" ]]; } && webhook_url_slack_option="${webhook_url_slack_local}"
    [[ -n "${webhook_url_teams_managed}" ]] && webhook_url_teams_option="${webhook_url_teams_managed}"
    { [[ -z "${webhook_url_teams_managed}" ]] && [[ -z "${webhook_url_teams_option}" ]] && [[ -n "${webhook_url_teams_local}" ]]; } && webhook_url_teams_option="${webhook_url_teams_local}"
    [[ -n "${webhook_url_zoom_managed}" ]] && webhook_url_zoom_option="${webhook_url_zoom_managed}"
    { [[ -z "${webhook_url_zoom_managed}" ]] && [[ -z "${webhook_url_zoom_option}" ]] && [[ -n "${webhook_url_zoom_local}" ]]; } && webhook_url_zoom_option="${webhook_url_zoom_local}"
    [[ -n "${webhook_url_zoom_verification_token_managed}" ]] && webhook_url_zoom_verification_token_managed="${webhook_url_verification_token_managed}"
    { [[ -z "${webhook_url_zoom_verification_token_managed}" ]] && [[ -z "${webhook_url_zoom_verification_token_option}" ]] && [[ -n "${webhook_url_zoom_Verification_token_local}" ]]; } && webhook_url_zoom_verification_token_option="${webhook_url_zoom_verification_token_local}"
    [[ -n "${ignored_labels_managed}" ]] && ignored_labels_option="${ignored_labels_managed}"
    { [[ -z "${ignored_labels_managed}" ]] && [[ -z "${ignored_labels_option}" ]] && [[ -n "${ignored_labels_local}" ]]; } && ignored_labels_option="${ignored_labels_local}"
    [[ -n "${required_labels_managed}" ]] && required_labels_option="${required_labels_managed}"
    { [[ -z "${required_labels_managed}" ]] && [[ -z "${required_labels_option}" ]] && [[ -n "${required_labels_local}" ]]; } && required_labels_option="${required_labels_local}"
    [[ -n "${optional_labels_managed}" ]] && optional_labels_option="${optional_labels_managed}"
    { [[ -z "${optional_labels_managed}" ]] && [[ -z "${optional_labels_option}" ]] && [[ -n "${optional_labels_local}" ]]; } && optional_labels_option="${optional_labels_local}"

    # Need logic to ensures the priority order of managed preference overrides the saved local preference which overrides the script embedded variables .
    [[ -n "${app_title_managed}" ]] && appTitle="${app_title_managed}"
    { [[ -z "${app_title_managed}" ]] && [[ -n "${appTitle}" ]] && [[ -n "${app_title_local}" ]]; } && appTitle="${app_title_local}"
    [[ -n "${convert_apps_in_home_folder_managed}" ]] && convertAppsInHomeFolder="${convert_apps_in_home_folder_managed}"
    { [[ -z "${convert_apps_in_home_folder_managed}" ]] && [[ -n "${convertAppsInHomeFolder}" ]] && [[ -n "${convert_apps_in_home_folder_local}" ]]; } && convertAppsInHomeFolder="${convert_apps_in_home_folder_local}"
    [[ -n "${ignore_apps_in_home_folder_managed}" ]] && ignoreAppsInHomeFolder="${ignore_apps_in_home_folder_managed}"
    { [[ -z "${ignore_apps_in_home_folder_managed}" ]] && [[ -n "${ignoreAppsInHomeFolder}" ]] && [[ -n "${ignore_apps_in_home_folder_local}" ]]; } && ignoreAppsInHomeFolder="${ignore_apps_in_home_folder_local}"
    [[ -n "${installomator_options_managed}" ]] && installomatorOptions="${installomator_options_managed}"
    { [[ -z "${installomator_options_managed}" ]] && [[ -n "${installomatorOptions}" ]] && [[ -n "${installomator_options_local}" ]]; } && installomatorOptions="${installomator_options_local}"
    
    [[ -n "${installomator_update_disable_managed}" ]] && installomator_update_disable_option="${installomator_update_disable_managed}"
    { [[ -z "${installomator_update_disable_managed}" ]] && [[ -n "${installomator_update_disable_option}" ]] && [[ -n "${installomator_update_disable_local}" ]]; } && installomator_update_disable_option="${installomator_update_disable_local}"
    
    [[ -n "${installomator_version_managed}" ]] && installomatorVersion="${installomator_version_managed}"
    { [[ -z "${installomator_version_managed}" ]] && [[ -n "${installomatorVersion}" ]] && [[ -n "${installomator_version_local}" ]]; } && installomatorVersion="${installomator_version_local}"
    
    [[ -n "${installomator_version_custom_repo_path_managed}" ]] && installomatorVersionCustomRepoPath="${installomator_version_custom_repo_path_managed}"
    { [[ -z "${installomator_version_custom_repo_path_managed}" ]] && [[ -z "${installomatorVersionCustomRepoPath}" ]] && [[ -n "${installomator_version_custom_repo_path_local}" ]]; } && installomatorVersionCustomRepoPath="${installomator_version_custom_repo_path_local}"
    
    [[ -n "${installomator_version_custom_branch_name_managed}" ]] && installomatorVersionCustomBranchName="${installomator_version_custom_branch_name_managed}"
    { [[ -z "${installomator_version_custom_branch_name_managed}" ]] && [[ -z "${installomatorVersionCustomBranchName}" ]] && [[ -n "${installomator_version_custom_branch_name_local}" ]]; } && installomatorVersionCustomBranchName="${installomator_version_custom_branch_name_local}"
    
    [[ -n "${dialog_timeout_deferral_managed}" ]] && DialogTimeoutDeferral="${dialog_timeout_deferral_managed}"
    { [[ -z "${dialog_timeout_deferral_managed}" ]] && [[ -n "${DialogTimeoutDeferral}" ]] && [[ -n "${dialog_timeout_deferral_local}" ]]; } && DialogTimeoutDeferral="${dialog_timeout_deferral_local}"
    [[ -n "${dialog_timeout_deferral_action_managed}" ]] && DialogTimeoutDeferralAction="${dialog_timeout_deferral_action_managed}"
    { [[ -z "${dialog_timeout_deferral_action_managed}" ]] && [[ -n "${DialogTimeoutDeferralAction}" ]] && [[ -n "${dialog_timeout_deferral_action_local}" ]]; } && DialogTimeoutDeferralAction="${dialog_timeout_deferral_action_local}"
    [[ -n "${days_until_reset_managed}" ]] && days_until_reset_option="${days_until_reset_managed}"
    { [[ -z "${days_until_reset_managed}" ]] && [[ -z "${days_until_reset_option}" ]] && [[ -n "${days_until_reset_local}" ]]; } && days_until_reset_option="${days_until_reset_local}"
    [[ -n "${Unattended_exit_managed}" ]] && UnattendedExit="${Unattended_exit_managed}"
    { [[ -z "${Unattended_exit_managed}" ]] && [[ -n "${UnattendedExit}" ]] && [[ -n "${Unattended_exit_local}" ]]; } && UnattendedExit="${Unattended_exit_local}"
    [[ -n "${Unattended_exit_seconds_managed}" ]] && UnattendedExitSeconds="${Unattended_exit_seconds_managed}"
    { [[ -z "${Unattended_exit_seconds_managed}" ]] && [[ -n "${UnattendedExitSeconds}" ]] && [[ -n "${Unattended_exit_seconds_local}" ]]; } && UnattendedExitSeconds="${Unattended_exit_seconds_local}"
    [[ -n "${dialog_on_top_managed}" ]] && dialogOnTop="${dialog_on_top_managed}"
    { [[ -z "${dialog_on_top_managed}" ]] && [[ -n "${dialogOnTop}" ]] && [[ -n "${dialog_on_top_local}" ]]; } && dialogOnTop="${dialog_on_top_local}"
    
    [[ -n "${workflow_install_now_patching_status_action_managed}" ]] && workflow_install_now_patching_status_action_option="${workflow_install_now_patching_status_action_managed}"
    { [[ -z "${workflow_install_now_patching_status_action_managed}" ]] && [[ -z "${workflow_install_now_patching_status_action_option}" ]] && [[ -n "${workflow_install_now_patching_status_action_local}" ]]; } && workflow_install_now_patching_status_action_option="${workflow_install_now_patching_status_action_local}"
    
    
    [[ -n "${use_overlay_icon_managed}" ]] && useOverlayIcon="${use_overlay_icon_managed}"
    { [[ -z "${use_overlay_icon_managed}" ]] && [[ -n "${useOverlayIcon}" ]] && [[ -n "${use_overlay_icon_local}" ]]; } && useOverlayIcon="${use_overlay_icon_local}"
    [[ -n "${remove_installomator_path_managed}" ]] && removeInstallomatorPath="${remove_installomator_path_managed}"
    { [[ -z "${remove_installomator_path_managed}" ]] && [[ -n "${removeInstallomatorPath}" ]] && [[ -n "${remove_installomator_path_local}" ]]; } && removeInstallomatorPath="${remove_installomator_path_local}"
    [[ -n "${support_team_name_managed}" ]] && supportTeamName="${support_team_name_managed}"
    { [[ -z "${support_team_name_managed}" ]] && [[ -n "${supportTeamName}" ]] && [[ -n "${support_team_name_local}" ]]; } && supportTeamName="${support_team_name_local}"
    [[ -n "${support_team_phone_managed}" ]] && supportTeamPhone="${support_team_phone_managed}"
    { [[ -z "${support_team_phone_managed}" ]] && [[ -n "${supportTeamPhone}" ]] && [[ -n "${support_team_phone_local}" ]]; } && supportTeamPhone="${support_team_phone_local}"
    [[ -n "${support_team_email_managed}" ]] && supportTeamEmail="${support_team_email_managed}"
    { [[ -z "${support_team_email_managed}" ]] && [[ -n "${supportTeamEmail}" ]] && [[ -n "${support_team_email_local}" ]]; } && supportTeamEmail="${support_team_email_local}"
    [[ -n "${support_team_website_managed}" ]] && supportTeamWebsite="${support_team_website_managed}"
    { [[ -z "${support_team_website_managed}" ]] && [[ -n "${supportTeamWebsite}" ]] && [[ -n "${support_team_website_local}" ]]; } && supportTeamWebsite="${support_team_website_local}"
    
    #Verbose Configuration Option Output
    log_verbose "DeferralTimerMenu: $deferral_timer_menu_option"
    log_verbose "DeferralTimerFocus: $deferral_timer_focus_option"
    log_verbose "DeferralTimerError: $deferral_timer_error_option"
    log_verbose "DeferralTimerWorkflowRelaunch: $deferral_timer_workflow_relaunch_option"
    log_verbose "DeadlineCountFocus: $deadline_count_focus_option"
    log_verbose "DeadlineCountHard: $deadline_count_hard_option"
    log_verbose "DeadlineDaysFocus: $deadline_days_focus_option"
    log_verbose "DeadlineDaysHard: $deadline_days_hard_option"
    log_verbose "DeferralTimerDefault: $deferral_timer_default_option"
    log_verbose "InteractiveMode: $InteractiveModeOption"
    log_verbose "PatchWeekStartDay: $patch_week_start_day_option"
    log_verbose "WorkflowDisableAppDiscovery: $workflow_disable_app_discovery_option"
    log_verbose "WorkflowDisableRelaunch: $workflow_disable_relaunch_option"
    log_verbose "WebhookFeature: $webhook_feature_option"
    log_verbose "WebhookURLSlack: $webhook_url_slack_option"
    log_verbose "WebhookURLTeams: $webhook_url_teams_option"
    log_verbose "WebhookURLZoom: $webhook_url_zoom_option"
    log_verbose "WebhookURLZoomVerificationToken: $webhook_url_zoom_verification_token_option"
    log_verbose "IgnoredLabels: $ignored_labels_option"
    log_verbose "RequiredLabels: $required_labels_option"
    log_verbose "OptionalLabels: $optional_labels_option"
    log_verbose "AppTitle: $appTitle"
    log_verbose "ConvertAppsInHomeFolder: $convertAppsInHomeFolder"
    log_verbose "IgnoreAppsInHomeFolder: $ignoreAppsInHomeFolder"
    log_verbose "InstallomatorOptions: $installomatorOptions"
    log_verbose "InstallomatorUpdateDisable: $installomator_update_disable_option"
    log_verbose "InstallomatorVersion: $installomatorVersion"
    log_verbose "InstallomatorVersionCustomRepoPath: $installomatorVersionCustomRepoPath"
    log_verbose "InstallomatorVersionCustomBranchName: $installomatorVersionCustomBranchName"
    log_verbose "DialogTimeoutDeferral: $DialogTimeoutDeferral"
    log_verbose "DialogTimeoutDeferralAction: $DialogTimeoutDeferralAction"
    log_verbose "DaysUntilReset: $days_until_reset_option"
    log_verbose "UnattendedExit: $UnattendedExit"
    log_verbose "UnattendedExitSeconds: $UnattendedExitSeconds"
    log_verbose "DialogOnTop: $dialogOnTop"
    log_verbose "WorkflowInstallNowPatchingStatusAction: $workflow_install_now_patching_status_action_option"
    log_verbose "UseOverlayIcon: $useOverlayIcon"
    log_verbose "RemoveInstallomatorPath: $removeInstallomatorPath"
    log_verbose "SupportTeamName: $supportTeamName"
    log_verbose "SupportTeamPhone: $supportTeamPhone"
    log_verbose "SupportTeamEmail: $supportTeamEmail"
    log_verbose "SupportTeamWebsite: $supportTeamWebsite"
    
    
    # Write App Labels to PLIST
    ignoredLabelsArray=($(echo ${ignored_labels_option}))
    requiredLabelsArray=($(echo ${required_labels_option}))
    optionalLabelsArray=($(echo ${optional_labels_option}))
    convertedLabelsArray=($(echo ${convertedLabels}))

    /usr/libexec/PlistBuddy -c 'add ":DiscoveredLabels" array' "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
    /usr/libexec/PlistBuddy -c 'add ":IgnoredLabels" array' "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
    /usr/libexec/PlistBuddy -c 'add ":RequiredLabels" array' "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
    /usr/libexec/PlistBuddy -c 'add ":OptionalLabels" array' "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
    /usr/libexec/PlistBuddy -c 'add ":ConvertedLabels" array' "${appAutoPatchLocalPLIST}.plist" 2> /dev/null

    log_info "Attempting to populate ignored labels"
    for ignoredLabel in "${ignoredLabelsArray[@]}"; do
        if [[ -f "${fragmentsPath}/labels/${ignoredLabel}.sh" ]]; then
            if /usr/libexec/PlistBuddy -c "Print :IgnoredLabels:" "${appAutoPatchLocalPLIST}.plist" | grep -w -q $ignoredLabel; then
                log_verbose "$ignoredLabel already exists, skipping for now"
            else
                log_verbose "Writing ignored label $ignoredLabel to configuration plist"
                /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"${ignoredLabel}\"" "${appAutoPatchLocalPLIST}.plist"
            fi
        else
            if [[ "${ignoredLabel}" == *"*"* ]]; then
                log_verbose "Ignoring all labels with $ignoredLabel"
                wildIgnored=( $(find $fragmentsPath/labels -name "$ignoredLabel") )
                for i in "${wildIgnored[@]}"; do
                    ignored=$( echo $i | cut -d'.' -f1 | sed 's@.*/@@' )
                    if [[ ! "$ignored" == "Application" ]]; then
                        # Issue 141 https://github.com/App-Auto-Patch/App-Auto-Patch/issues/141
                        #if /usr/libexec/PlistBuddy -c "Print :IgnoredLabels:" "${appAutoPatchLocalPLIST}".plist | grep -w -q $ignored; then
                        if /usr/libexec/PlistBuddy -c "Print :IgnoredLabels:" "${appAutoPatchLocalPLIST}".plist | grep -x -q "$ignored"; then
                            log_verbose "$ignored already exists, skipping for now"
                        else
                            log_verbose "Writing ignored label $ignored to configuration plist"
                            ignored=$(echo $ignored | sed "s/[\"]//g" )
                            /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"${ignored}\"" "${appAutoPatchLocalPLIST}.plist"
                            ignoredLabelsArray+=($ignored)
                        fi
                    else
                        sleep .1
                    fi
                done 
            else
                log_verbose "No such label ${ignoredLabel}"
            fi
        fi
    done

    # Attempting to populate Required Labels
    log_info "Attempting to populate required labels"
    for requiredLabel in "${requiredLabelsArray[@]}"; do
        if [[ -f "${fragmentsPath}/labels/${requiredLabel}.sh" ]]; then
            if /usr/libexec/PlistBuddy -c "Print :RequiredLabels:" "${appAutoPatchLocalPLIST}.plist" | grep -w -q $requiredLabel; then
                log_verbose "$requiredLabel already exists, skipping for now"
            else
                log_verbose "Writing required label $requiredLabel to configuration plist"
                /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${requiredLabel}\"" "${appAutoPatchLocalPLIST}.plist"
            fi
        else
            if [[ "${requiredLabel}" == *"*"* ]]; then
                log_verbose "Ignoring all labels with $requiredLabel"
                wildrequired=( $(find $fragmentsPath/labels -name "$requiredLabel") )
                for i in "${wildrequired[@]}"; do
                    required=$( echo $i | cut -d'.' -f1 | sed 's@.*/@@' )
                    if [[ ! "$required" == "Application" ]]; then
                        # Issue 141 https://github.com/App-Auto-Patch/App-Auto-Patch/issues/141
                        #if /usr/libexec/PlistBuddy -c "Print :RequiredLabels:" "${appAutoPatchLocalPLIST}".plist | grep -w -q $required; then
                        if /usr/libexec/PlistBuddy -c "Print :RequiredLabels:" "${appAutoPatchLocalPLIST}".plist | grep -x -q $required; then
                            log_verbose "$required already exists, skipping for now"
                        else
                            log_verbose "Writing required label $required to configuration plist"
                            /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${required}\"" "${appAutoPatchLocalPLIST}.plist"
                            requiredLabelsArray+=($required)
                        fi
                    else
                        sleep .1
                    fi
                done 
            else
                log_verbose "No such label ${requiredLabel}"
            fi
        fi
    done

    # Attempt to populate the Optional Labels
    log_info "Attempting to populate optional labels"
    for optionalLabel in "${optionalLabelsArray[@]}"; do
        if [[ -f "${fragmentsPath}/labels/${optionalLabel}.sh" ]]; then
            if /usr/libexec/PlistBuddy -c "Print :OptionalLabels:" "${appAutoPatchLocalPLIST}.plist" | grep -w -q $optionalLabel; then
                log_verbose "$optionalLabel already exists, skipping for now"
            else
                log_verbose "Writing optional label $optionalLabel to configuration plist"
                /usr/libexec/PlistBuddy -c "add \":OptionalLabels:\" string \"${optionalLabel}\"" "${appAutoPatchLocalPLIST}.plist"
            fi
            # Checking if app is installed and adding Optional Label to Required if it exists
            if ${installomatorScript} ${optionalLabel} DEBUG=2 NOTIFY="silent" BLOCKING_PROCESS_ACTION="ignore" | grep "No previous app found" >/dev/null 2>&1
            then
                log_notice "$optionalLabel is not installed, skipping ..."
            elif /usr/libexec/PlistBuddy -c "Print :RequiredLabels:" "${appAutoPatchLocalPLIST}.plist" | grep -w -q $optionalLabel; then
                log_verbose "$optionalLabel Installed but already exists in Required list, skipping for now"
            else
                log_verbose "Writing optional label ${optionalLabel} to required configuration plist"
                /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${optionalLabel}\"" "${appAutoPatchLocalPLIST}.plist"
            fi
            
            
            
        else
            log_verbose "No such label ${optionalLabel}"
        fi
    done

    # Ignore swiftDialog as it should already be installed. This is to reduce issues re-downloading swiftDialog
    if /usr/libexec/PlistBuddy -c "Print :IgnoredLabels:" "${appAutoPatchLocalPLIST}.plist" | grep -w -q swiftdialog; then
        log_verbose "swiftDialog is already ignored"
    else
        log_verbose "Ignoring swiftDialog"
        /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"swiftdialog\"" "${appAutoPatchLocalPLIST}.plist"
        ignoredLabelsArray+=("swiftdialog")
    fi
    if /usr/libexec/PlistBuddy -c "Print :IgnoredLabels:" "${appAutoPatchLocalPLIST}.plist" | grep -w -q dialog; then
        log_verbose "dialog is already ignored"
    else
        log_verbose "Ignoring dialog"
        /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"dialog\"" "${appAutoPatchLocalPLIST}.plist"
        ignoredLabelsArray+=("dialog")
    fi

    
    
    write_status "Completed: Collecting preferences"
}

manage_parameter_options() {

    option_error="FALSE"

    if [[ "${deferral_timer_default_option}" == "X" ]]; then
        log_status "Deleting local preference for the --deferral-timer-default option, defaulting to ${DEFERRAL_TIMER_DEFAULT_MINUTES} minutes."
        defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerDefault 2> /dev/null
    elif [[ -n "${deferral_timer_default_option}" ]] && [[ "${deferral_timer_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        if [[ "${deferral_timer_default_option}" -lt 2 ]]; then
            log_warning "Specified --deferral-timer-default=minutes value of ${deferral_timer_default_option} is too low, rounding to 2 minutes."
            deferral_timer_minutes=2
        elif [[ "${deferral_timer_default_option}" -gt 10080 ]]; then
            log_warning "Specified --deferral-timer-default=minutes value of ${deferral_timer_default_option} is too high, rounding down to 10080 minutes (1 week)."
            deferral_timer_minutes=10080
        else
            deferral_timer_minutes="${deferral_timer_default_option}"
        fi
        defaults write "${appAutoPatchLocalPLIST}" DeferralTimerDefault -string "${deferral_timer_minutes}"
        # deprecate next_auto_launch_minutes: next_auto_launch_minutes="${deferral_timer_minutes}"
        elif [[ -n "${deferral_timer_default_option}" ]] && ! [[ "${deferral_timer_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
            log_error "The --deferral-timer-default=minutes value must only be a number."; option_error="TRUE"
        fi
    [[ -z "${deferral_timer_minutes}" ]] && deferral_timer_minutes="${DEFERRAL_TIMER_DEFAULT_MINUTES}"
    # deprecate next_auto_launch_minutes: next_auto_launch_minutes="${deferral_timer_minutes}"
    log_verbose  "deferral_timer_minutes is: ${deferral_timer_minutes}"


    if [[ "${deferral_timer_default_option}" == "X" ]]; then
        log_status "Status: Deleting local preference for the --deferral-timer-default option, defaulting to ${DEFERRAL_TIMER_DEFAULT_MINUTES} minutes."
        defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerDefault 2>/dev/null
        unset deferral_timer_default_option
    elif [[ -n "${deferral_timer_default_option}" ]] && [[ "${deferral_timer_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        if [[ "${deferral_timer_default_option}" -lt 2 ]]; then
            log_warning "Parameter Warning: Specified --deferral-timer-default=minutes value of ${deferral_timer_default_option} is too low, rounding up to 2 minutes."
            deferral_timer_minutes=2
        elif [[ "${deferral_timer_default_option}" -gt 10080 ]]; then
            log_warning "Parameter Warning: Specified --deferral-timer-default=minutes value of ${deferral_timer_default_option} is too high, rounding down to 10080 minutes (1 week)."
            deferral_timer_minutes=10080
        else
            deferral_timer_minutes="${deferral_timer_default_option}"
        fi
        defaults write "${appAutoPatchLocalPLIST}" DeferralTimerDefault -string "${deferral_timer_minutes}"
    elif [[ -n "${deferral_timer_default_option}" ]] && ! [[ "${deferral_timer_default_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "Parameter Error: The --deferral-timer-default=minutes value must only be a number."
        option_error="TRUE"
    fi
    [[ -z "${deferral_timer_minutes}" ]] && deferral_timer_minutes="${DEFERRAL_TIMER_DEFAULT_MINUTES}"
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_minutes is: ${deferral_timer_minutes}"


    # Validate ${deadline_count_focus_option} input and if valid set ${deadline_count_focus} and save to ${appAutoPatchLocalPLIST}.
    if [[ "${deadline_count_focus_option}" == "X" ]]; then
        log_status "Deleting local preference for the --deadline-count-focus option."
        defaults delete "${appAutoPatchLocalPLIST}" DeadlineCountFocus 2> /dev/null
    elif [[ -n "${deadline_count_focus_option}" ]] && [[ "${deadline_count_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        deadline_count_focus="${deadline_count_focus_option}"
        defaults write "${appAutoPatchLocalPLIST}" DeadlineCountFocus -string "${deadline_count_focus}"
    elif [[ -n "${deadline_count_focus_option}" ]] && ! [[ "${deadline_count_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "The --deadline-count-focus=number value must only be a number."; option_error="TRUE"
    fi
    
    # Validate ${deadline_count_hard_option} input and if valid set ${deadline_count_hard}.
    if [[ "${deadline_count_hard_option}" == "X" ]]; then
        log_status "Deleting local preference for the --deadline-count-hard option."
        defaults delete "${appAutoPatchLocalPLIST}" DeadlineCountHard 2> /dev/null
    elif [[ -n "${deadline_count_hard_option}" ]] && [[ "${deadline_count_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        deadline_count_hard="${deadline_count_hard_option}"
        defaults write "${appAutoPatchLocalPLIST}" DeadlineCountHard -string "${deadline_count_hard}"
    elif [[ -n "${deadline_count_hard_option}" ]] && ! [[ "${deadline_count_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "The --deadline-count-hard=number value must only be a number."; option_error="TRUE"
    fi
    
    #Validate Custom Installomator Options
    
    if [[ "${installomatorVersion}" == "Custom" ]] || [[ "${installomatorVersion}" == "custom" ]]; then
        if [[ -z "${installomatorVersionCustomRepoPath}" ]] || [[ -z "${installomatorVersionCustomBranchName}" ]]; then
            log_status "Parameter Error: The Custom InstallomatorVersion option requires both the InstallomatorVersionCustomRepoPath and InstallomatorVersionCustomBranchName keys"; option_error="TRUE"
        fi
        fi
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${installomatorVersionCustomRepoPath}" ]]; } && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: installomatorVersionCustomRepoPath is: ${installomatorVersionCustomRepoPath}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${installomatorVersionCustomBranchName}" ]]; } && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: installomatorVersionCustomBranchName is: ${installomatorVersionCustomBranchName}"

    # Validate ${deadline_days_focus_option} input and if valid set ${deadline_days_focus} and ${deadline_days_focus_seconds}.
    if [[ "${deadline_days_focus_option}" == "X" ]]; then
        log_status "Status: Deleting local preference for the --deadline-days-focus option."
        defaults delete "${appAutoPatchLocalPLIST}" DeadlineDaysFocus 2> /dev/null
    elif [[ -n "${deadline_days_focus_option}" ]] && [[ "${deadline_days_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        deadline_days_focus="${deadline_days_focus_option}"
        deadline_days_focus_seconds=$((deadline_days_focus*86400))
    elif [[ -n "${deadline_days_focus_option}" ]] && ! [[ "${deadline_days_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_status "Parameter Error: The --deadline-days-focus=number value must only be a number."; option_error="TRUE"
    fi
    
    # Validate ${deadline_days_hard_option} input and if valid set ${deadline_days_hard} and ${deadline_days_hard_seconds}.
    if [[ "${deadline_days_hard_option}" == "X" ]]; then
        log_status "Status: Deleting local preference for the --deadline-days-hard option."
        defaults delete "${appAutoPatchLocalPLIST}" DeadlineDaysHard 2> /dev/null
    elif [[ -n "${deadline_days_hard_option}" ]] && [[ "${deadline_days_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        deadline_days_hard="${deadline_days_hard_option}"
        deadline_days_hard_seconds=$((deadline_days_hard*86400))
    elif [[ -n "${deadline_days_hard_option}" ]] && ! [[ "${deadline_days_hard_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_status "Parameter Error: The --deadline-days-hard=number value must only be a number."; option_error="TRUE"
    fi
    
    # Validate ${deadline_days_focus}, and ${deadline_days_hard} in relation to each other, and if valid save to ${appAutoPatchLocalPLIST}.
    if [[ -n "${deadline_days_hard}" ]] && [[ -n "${deadline_days_focus}" ]] && [[ "${deadline_days_hard}" -le "${deadline_days_focus}" ]]; then
        log_status "Parameter Error: The --deadline-days-hard=number value of ${deadline_days_hard} day(s) must be more than the --deadline-days-focus=number value of ${deadline_days_focus} day(s)."; option_error="TRUE"
    fi

    if [[ "${option_error}" != "TRUE" ]]; then
        [[ -n "${deadline_days_focus}" ]] && defaults write "${appAutoPatchLocalPLIST}" DeadlineDaysFocus -string "${deadline_days_focus}"
        [[ -n "${deadline_days_hard}" ]] && defaults write "${appAutoPatchLocalPLIST}" DeadlineDaysHard -string "${deadline_days_hard}"
    fi
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_days_focus}" ]]; } && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_focus is: ${deadline_days_focus}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_days_hard}" ]]; } && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_hard is: ${deadline_days_hard}"
    

    # Validate ${patch_week_start_day_option} input and if valid set ${patch_week_start_day}.
    if [[ "${patch_week_start_day_option}" == "X" ]]; then
        log_status "Deleting local preference for the --patch-week-start-day option."
        defaults delete "${appAutoPatchLocalPLIST}" PatchWeekStartDay 2> /dev/null
    elif [[ -n "${patch_week_start_day_option}" ]] && [[ "${patch_week_start_day_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        patch_week_start_day="${patch_week_start_day_option}"
        defaults write "${appAutoPatchLocalPLIST}" PatchWeekStartDay -string "${patch_week_start_day}"
    elif [[ -n "${patch_week_start_day_option}" ]] && ! [[ "${patch_week_start_day_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "The --patch-week-start-day=number value must only be a number."; option_error="TRUE"
    fi
    
    # Validate ${days_until_reset_option} input and if valid set ${patch_week_start_day}.
    if [[ "${days_until_reset_option}" == "X" ]]; then
        log_status "Deleting local preference for the --days_until_reset option."
        defaults delete "${appAutoPatchLocalPLIST}" DaysUntilReset 2> /dev/null
    elif [[ -n "${days_until_reset_option}" ]] && [[ "${days_until_reset_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        days_until_reset="${days_until_reset_option}"
        defaults write "${appAutoPatchLocalPLIST}" DaysUntilReset -string "${days_until_reset}"
    elif [[ -n "${days_until_reset_option}" ]] && ! [[ "${days_until_reset_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "The --patch-week-start-day=number value must only be a number."; option_error="TRUE"
    fi
    
    if [[ -z "${days_until_reset_option}" ]]; then
        days_until_reset_option="${daysUntilReset}"
        days_until_reset="${days_until_reset_option}"
    fi
    
    # Manage ${workflow_disable_app_discovery_option} and save to ${appAutoPatchLocalPLIST}.
    if [[ "${workflow_disable_app_discovery_option}" -eq 1 ]] || [[ "${workflow_disable_app_discovery_option}" == "TRUE" ]]; then
        workflow_disable_app_discovery_option="TRUE"
        defaults write "${appAutoPatchLocalPLIST}" WorkflowDisableAppDiscovery -bool true
    else
        workflow_disable_app_discovery_option="FALSE"
        defaults delete "${appAutoPatchLocalPLIST}" WorkflowDisableAppDiscovery 2> /dev/null
    fi
    
    # Manage ${workflow_disable_relaunch_option} and save to ${appAutoPatchLocalPLIST}.
    if [[ "${workflow_disable_relaunch_option}" -eq 1 ]] || [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
        workflow_disable_relaunch_option="TRUE"
        defaults write "${appAutoPatchLocalPLIST}" WorkflowDisableRelaunch -bool true
    else
        workflow_disable_relaunch_option="FALSE"
        defaults delete "${appAutoPatchLocalPLIST}" WorkflowDisableRelaunch 2>/dev/null
    fi
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${workflow_disable_relaunch_option}" ]]; } && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: workflow_disable_relaunch_option is: ${workflow_disable_relaunch_option}"
    
    # Manage ${UnattendedExit} and save to ${appAutoPatchLocalPLIST}.
    if [[ "${UnattendedExit}" -eq 1 ]] || [[ "${UnattendedExit}" == "TRUE" ]]; then
        UnattendedExit="TRUE"
        defaults write "${appAutoPatchLocalPLIST}" UnattendedExit -bool true
    else
        UnattendedExit="FALSE"
        defaults delete "${appAutoPatchLocalPLIST}" UnattendedExit 2>/dev/null
    fi
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${UnattendedExit}" ]]; } && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: UnattendedExit is: ${UnattendedExit}"
    
    if [[ -n "${UnattendedExitSeconds}" ]] && [[ "${UnattendedExitSeconds}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        if [[ "${UnattendedExitSeconds}" -lt 2 ]]; then
            log_warning "Parameter Warning: Specified UnattendedExitSeconds value of ${UnattendedExitSeconds} is too low, rounding up to 2 seconds."
            UnattendedExitSeconds=2
        elif [[ "${UnattendedExitSeconds}" -gt 86400 ]]; then
            log_warning "Parameter Warning: Specified UnattendedExitSeconds value of ${UnattendedExitSeconds} is too high, rounding down to 86400 (24 hours)."
            UnattendedExitSeconds=86400
        fi
        defaults write "${appAutoPatchLocalPLIST}" UnattendedExitSeconds -int "${UnattendedExitSeconds}"
    elif [[ -n "${UnattendedExitSeconds}" ]] && ! [[ "${UnattendedExitSeconds}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "Parameter Error: The UnattendedExitSeconds value must only be a number."
        option_error="TRUE"
    fi
    [[ -z "${UnattendedExitSeconds}" ]] && UnattendedExitSeconds=60
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: UnattendedExitSeconds is: ${UnattendedExitSeconds}"
    

    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_count_focus}" ]]; } && log_verbose "deadline_count_focus is: ${deadline_count_focus}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${deadline_count_hard}" ]]; } && log_verbose "deadline_count_hard is: ${deadline_count_hard}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${patch_week_start_day}" ]]; } && log_verbose "patch_week_start_day is: ${patch_week_start_day}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${days_until_reset}" ]]; } && log_verbose "days_until_reset is: ${days_until_reset}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${workflow_disable_app_discovery_option}" ]]; } && log_verbose "workflow_disable_app_discovery_option is: ${workflow_disable_app_discovery_option}"
    
    # Validate ${deferral_timer_menu_option} input and if valid set ${deferral_timer_menu_minutes} and save to ${appAutoPatchLocalPLIST}.
    local previous_ifs
    if [[ "${deferral_timer_menu_option}" == "X" ]]; then
        log_status "Status: Deleting local preference for the --deferral-timer-menu option, defaulting to ${deferral_timer_minutes} minutes."
        defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerMenu 2>/dev/null
        unset deferral_timer_menu_option
    elif [[ -n "${deferral_timer_menu_option}" ]] && [[ "${deferral_timer_menu_option}" =~ ${REGEX_CSV_WHOLE_NUMBERS} ]]; then
        previous_ifs="${IFS}"
        IFS=','
        local deferral_timer_menu_option_array
        
        # Split the string into an array, splitting on ','
        deferral_timer_menu_option_array=("${(@s/,/)deferral_timer_menu_option}")
        
        array_length=${#deferral_timer_menu_option_array[@]}
        
        for (( array_index = 1; array_index <= array_length; array_index++ )); do
            if [[ "${deferral_timer_menu_option_array[array_index]}" -lt 2 ]]; then
                log_status "Parameter Warning: Specified --deferral-timer-menu=minutes value of ${deferral_timer_menu_option_array[array_index]} minutes is too low, rounding up to 2 minutes."
                deferral_timer_menu_option_array[array_index]=2
            elif [[ "${deferral_timer_menu_option_array[array_index]}" -gt 10080 ]]; then
                log_status "Parameter Warning: Specified --deferral-timer-menu=minutes value of ${deferral_timer_menu_option_array[array_index]} minutes is too high, rounding down to 10080 minutes (1 week)."
                deferral_timer_menu_option_array[array_index]=10080
            fi
        done
        
        # Join the array elements into a string separated by spaces
        deferral_timer_menu_minutes="${(j:,:)deferral_timer_menu_option_array}"
        
        defaults write "${appAutoPatchLocalPLIST}" DeferralTimerMenu -string "${deferral_timer_menu_minutes}"
        IFS="${previous_ifs}"
    elif [[ -n "${deferral_timer_menu_option}" ]] && ! [[ "${deferral_timer_menu_option}" =~ ${REGEX_CSV_WHOLE_NUMBERS} ]]; then
        log_status "Parameter Error: The --deferral-timer-menu=minutes,minutes,etc... value must only contain numbers and commas (no spaces)."
        option_error="TRUE"
    fi
    
    # Validate ${deferral_timer_focus_option} input and if valid set ${deferral_timer_focus_minutes} and save to ${appAutoPatchLocalPLIST}. If there is no ${deferral_timer_focus_minutes} then set it to ${deferral_timer_minutes}.
    if [[ "${deferral_timer_focus_option}" == "X" ]]; then
        log_status "Deleting local preference for the --deferral-timer-focus option, defaulting to ${deferral_timer_minutes} minutes."
        defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerFocus 2> /dev/null
    elif [[ -n "${deferral_timer_focus_option}" ]] && [[ "${deferral_timer_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        if [[ "${deferral_timer_focus_option}" -lt 2 ]]; then
            log_warning "Specified --deferral-timer-focus=minutes value of ${deferral_timer_focus_option} minutes is too low, rounding up to 2 minutes."
            deferral_timer_focus_minutes=2
        elif [[ "${deferral_timer_focus_option}" -gt 10080 ]]; then
            log_warning "Specified --deferral-timer-focus=minutes value of ${deferral_timer_focus_option} minutes is too high, rounding down to 1440 minutes (1 week)."
            deferral_timer_focus_minutes=10080
        else
            deferral_timer_focus_minutes="${deferral_timer_focus_option}"
        fi
        defaults write "${appAutoPatchLocalPLIST}" DeferralTimerFocus -string "${deferral_timer_focus_minutes}"
    elif [[ -n "${deferral_timer_focus_option}" ]] && ! [[ "${deferral_timer_focus_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "The --deferral-timer-focus=minutes value must only be a number."; option_error="TRUE"
    fi
    [[ -z "${deferral_timer_focus_minutes}" ]] && deferral_timer_focus_minutes="${deferral_timer_minutes}"
    log_verbose  "deferral_timer_focus_minutes is: ${deferral_timer_focus_minutes}"
    
    # Validate ${deferral_timer_error_option} input and if valid set ${deferral_timer_error_minutes} and save to ${appAutoPatchLocalPLIST}. If there is no ${deferral_timer_error_minutes} then set it to ${deferral_timer_minutes}.
    if [[ "${deferral_timer_error_option}" == "X" ]]; then
        log_status "Deleting local preference for the --deferral-timer-error option, defaulting to ${deferral_timer_minutes} minutes."
        defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerError 2> /dev/null
    elif [[ -n "${deferral_timer_error_option}" ]] && [[ "${deferral_timer_error_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        if [[ "${deferral_timer_error_option}" -lt 2 ]]; then
            log_warning "Specified --deferral-timer-error=minutes value of ${deferral_timer_error_option} minutes is too low, rounding up to 2 minutes."
            deferral_timer_error_minutes=2
        elif [[ "${deferral_timer_error_option}" -gt 10080 ]]; then
            log_warning "Specified --deferral-timer-error=minutes value of ${deferral_timer_error_option} minutes is too high, rounding down to 1440 minutes (1 week)."
            deferral_timer_error_minutes=10080
        else
            deferral_timer_error_minutes="${deferral_timer_error_option}"
        fi
        defaults write "${appAutoPatchLocalPLIST}" DeferralTimerError -string "${deferral_timer_error_minutes}"
    elif [[ -n "${deferral_timer_error_option}" ]] && ! [[ "${deferral_timer_error_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "The --deferral-timer-error=minutes value must only be a number."; option_error="TRUE"
    fi
    [[ -z "${deferral_timer_error_minutes}" ]] && deferral_timer_error_minutes="${deferral_timer_minutes}"
    log_verbose  "deferral_timer_error_minutes is: ${deferral_timer_error_minutes}"

    # Validate ${deferral_timer_workflow_relaunch_option} input and if valid set ${deferral_timer_workflow_relaunch_minutes} and save to ${appAutoPatchLocalPLIST}. If there is no ${deferral_timer_workflow_relaunch_minutes} then set it to ${DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES}.
    if [[ "${deferral_timer_workflow_relaunch_option}" == "X" ]]; then
        log_status "Status: Deleting local preference for the --deferral-timer-workflow-relaunch option, defaulting to ${DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES} minutes."
        defaults delete "${appAutoPatchLocalPLIST}" DeferralTimerWorkflowRelaunch 2>/dev/null
        unset deferral_timer_workflow_relaunch_option
    elif [[ -n "${deferral_timer_workflow_relaunch_option}" ]] && [[ "${deferral_timer_workflow_relaunch_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        if [[ "${deferral_timer_workflow_relaunch_option}" -lt 2 ]]; then
            log_warning "Parameter Warning: Specified --deferral-timer-workflow-relaunch=minutes value of ${deferral_timer_workflow_relaunch_option} minutes is too low, rounding up to 2 minutes."
            deferral_timer_workflow_relaunch_minutes=2
        elif [[ "${deferral_timer_workflow_relaunch_option}" -gt 43200 ]]; then
            log_warning "Parameter Warning: Specified --deferral-timer-workflow-relaunch=minutes value of ${deferral_timer_workflow_relaunch_option} minutes is too high, rounding down to 43200 minutes (30 days)."
            deferral_timer_workflow_relaunch_minutes=43200
        else
            deferral_timer_workflow_relaunch_minutes="${deferral_timer_workflow_relaunch_option}"
        fi
        defaults write "${appAutoPatchLocalPLIST}" DeferralTimerWorkflowRelaunch -string "${deferral_timer_workflow_relaunch_minutes}"
    elif [[ -n "${deferral_timer_workflow_relaunch_option}" ]] && ! [[ "${deferral_timer_workflow_relaunch_option}" =~ ${REGEX_ANY_WHOLE_NUMBER} ]]; then
        log_error "Parameter Error: The --deferral-timer-workflow-relaunch=minutes value must only be a number."
        option_error="TRUE"
    fi
    [[ -z "${deferral_timer_workflow_relaunch_minutes}" ]] && deferral_timer_workflow_relaunch_minutes="${DEFERRAL_TIMER_WORKFLOW_RELAUNCH_DEFAULT_MINUTES}"
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: Line ${LINENO}: deferral_timer_workflow_relaunch_minutes is: ${deferral_timer_workflow_relaunch_minutes}"
    
    # Some validation and logging for the focus deferral timer option.
    if [[ -n "${deferral_timer_focus_option}" ]] && { [[ -z "${deadline_count_focus}" ]] && [[ -z "${deadline_days_focus}" ]]; }; then
        log_error "The --deferral-timer-focus option requires that you also specify at least one focus deadline option."; option_error="TRUE"
    fi
    
    # Manage ${InteractiveModeOption} and save to ${appAutoPatchLocalPLIST}
    if [[ -n "${InteractiveModeOption}" ]]; then
        defaults write "${appAutoPatchLocalPLIST}" InteractiveMode -integer "${InteractiveModeOption}"
    else
        defaults write "${appAutoPatchLocalPLIST}" InteractiveMode -integer "${InteractiveMode}"
        InteractiveModeOption="${InteractiveMode}"
    fi
    log_verbose "InteractiveModeOption: $InteractiveModeOption"
    
    # Manage ${workflow_install_now_patching_status_action_option} and save to ${appAutoPatchLocalPLIST}
    if [[ -n "${workflow_install_now_patching_status_action_option}" ]]; then
        defaults write "${appAutoPatchLocalPLIST}" WorkflowInstallNowPatchingStatusAction -string "${workflow_install_now_patching_status_action_option}"
    fi
    log_verbose "WorkflowInstallNowPatchingStatusAction: $workflow_install_now_patching_status_action_option"

    # Manage ${webhook_feature_option} and save to ${appAutoPatchLocalPLIST}.
    if [[ "${webhook_feature_option}" == "ALL" ]] || [[ "${webhook_feature_option}" == "FAILURES" ]]; then
        defaults write "${appAutoPatchLocalPLIST}" WebhookFeature -string "${webhook_feature_option}"
    else
        webhook_feature_option="FALSE"
        defaults delete "${appAutoPatchLocalPLIST}" WebhookFeature 2> /dev/null
    fi
    
    # Manage ${webhook_url_slack_option} and save to ${appAutoPatchLocalPLIST}.
    if [[ -n "${webhook_url_slack_option}" ]]; then
        defaults write "${appAutoPatchLocalPLIST}" WebhookURLSlack -string "${webhook_url_slack_option}"
    else
        defaults delete "${appAutoPatchLocalPLIST}" WebhookURLSlack 2> /dev/null
    fi
    
    # Manage ${webhook_url_teams_option} and save to ${appAutoPatchLocalPLIST}.
    if [[ -n "${webhook_url_teams_option}" ]]; then
        defaults write "${appAutoPatchLocalPLIST}" WebhookURLTeams -string "${webhook_url_teams_option}"
    else
        defaults delete "${appAutoPatchLocalPLIST}" WebhookURLTeams 2> /dev/null
    fi

    # Manage ${webhook_url_zoom_option} and save to ${appAutoPatchLocalPLIST}.
    if [[ -n "${webhook_url_zoom_option}" ]]; then
        defaults write "${appAutoPatchLocalPLIST}" WebhookURLZoom -string "${webhook_url_zoom_option}"
    else
        defaults delete "${appAutoPatchLocalPLIST}" WebhookURLZoom 2> /dev/null
    fi

    # Manage ${webhook_url_zoom_verification_token_option} and save to ${appAutoPatchLocalPLIST}.
    if [[ -n "${webhook_url_zoom_verification_token_option}" ]]; then
        defaults write "${appAutoPatchLocalPLIST}" WebhookURLZoomVerificationToken -string "${webhook_url_zoom_verification_token_option}"
    else
        defaults delete "${appAutoPatchLocalPLIST}" WebhookURLZoomVerificationToken 2> /dev/null
    fi

    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${webhook_feature_option}" ]]; } && log_verbose "webhook_feature_option is: ${webhook_feature_option}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${webhook_url_slack_option}" ]]; } && log_verbose "webhook_url_slack_option is: ${webhook_url_slack_option}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${webhook_url_teams_option}" ]]; } && log_verbose "webhook_url_teams_option is: ${webhook_url_teams_option}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${webhook_url_zoom_option}" ]]; } && log_verbose "webhook_url_zoom_option is: ${webhook_url_zoom_option}"
    { [[ "${verbose_mode_option}" == "TRUE" ]] && [[ -n "${webhook_url_zoom_verification_token_option}" ]]; } && log_verbose "Zoom webhook verification token has been provided."
}

gather_error_log(){
    # Gather Error Log (used for webhooks)

    installomatorLogFile="/var/log/Installomator.log"
    duplicate_log_dir=$( mktemp -d /var/tmp/InstallomatorErrors.XXXXXX )
    marker_file="/var/tmp/Installomator_marker.txt"
    
    chmod 655 "$duplicate_log_dir" 
    
    function createMarkerFile(){
        
        if [ ! -f "$marker_file" ]; then
            log_install "Marker file not found, creating temp marker file"
            touch "$marker_file"
        else
            log_install "marker file exist, continuing"
        fi
    }
    
    function createLastErrorPosition() {
        
        # Create a timestamp for the current run
        timestamp=$(date +%Y%m%d%H%M%S)
        log_install "Current time stamp: $timestamp"
        
        # Create a directory for duplicate log files if it doesn't exist
        if [ ! -d "$duplicate_log_dir" ]; then
            mkdir -p "$duplicate_log_dir"
            log_install "Creating duplicate log file"
        else
            log_install "Duplicate log directory exists, continuing"
        fi
        
        # Create a directory for duplicate log files if it doesn't exist
        if [ ! -f "$marker_file" ]; then
            log_install "Marker file not found, creating temp marker file"
            touch "$marker_file"
        else
            log_install "marker file exist, continuing"
        fi
        
        # Specify the duplicate log file with a timestamp
        duplicate_installomatorLogFile="$duplicate_log_dir/Installomator_error_$timestamp.log"
        log_install "Duplicate Log File location: $duplicate_installomatorLogFile"
        
        # Find the last position marker or start from the beginning if not found
        if [[ -f "$marker_file" ]] && [[ -f "$installomatorLogFile" ]]; then
            lastPosition=$(cat "$marker_file")
        else 
            log_install "Creating Installomator log file and setting error position as zero"
            touch "$installomatorLogFile"
            chmod 755 "$installomatorLogFile"
            lastPosition=0
        fi
        
        # Copy new entries from Installomator.log to the duplicate log file
        if [ -f "$installomatorLogFile" ]; then
            tail -n +$((lastPosition + 1)) "$installomatorLogFile" > "$duplicate_installomatorLogFile"
            log_install "Installomator log file exists. Tailing new entries from log file to duplicate log file" 
        else 
            log_install "Installomator log file not found. Creating now"
            checkInstallomator
        fi
        
        # Update the marker file with the new position
        wc -l "$installomatorLogFile" | awk '{print $1}' > "$marker_file"
        log_install "Updating marker file"
        
        lastPosition=$(cat "$marker_file")
        log_install "Last position: $lastPosition"
    }
    
    function verifyLastPosition(){
        # Find the last position text in scriptLog
        lastPosition_line=$(tail -n 400 "$scriptLog" | grep 'Last position:' | tail -n 1)
        
        if [ -n "$lastPosition_line" ]; then
            # Extract the last position from the line
            lastPosition=$(echo "$lastPosition_line" | awk -F 'Last position:' '{print $2}' | tr -d '[:space:]')
            
            echo "$lastPosition" > "$marker_file"
            
            # Check if last position is less than or equal to zero
            if [[ ! -f "{$installomatorLogFile}" ]] || [[ "${lastPosition}" -le 0 ]]; then
                log_install "Last position is less than one or Installomator log doesn't exist. Creating position."
                createLastErrorPosition
            else
                log_install "Last position is greater than zero and Installomator log file exists. Continuing."
                lastPositionUpdated=$(cat "$marker_file")
                log_install "Last position: $lastPositionUpdated"
            fi
        else
            log_install "Last position not found. Setting it to zero and continuing."
            createLastErrorPosition
        fi
    }
    
    log_install "Creating Marker file and checking if last error position exists"
    createMarkerFile
    verifyLastPosition

}

# Prepare App Auto-Patch by cleaning after previous AAP runs, record various maintenance modes, validate parameters, and if necessary restart via the AAP LaunchDaemon.
workflow_startup() {
	# Make sure AAP is running as root.
	if [[ $(id -u) -ne 0 ]]; then
		log_echo "Exit: App Auto-Patch must run with root privileges."
		exit 1
	fi
	
	# Make sure macOS meets the minimum requirement of macOS 12.
	macos_version_major=$(sw_vers -productVersion | cut -d'.' -f1) # Expected output: 10, 11, 12
	if [[ "${macos_version_major}" -lt 12 ]]; then
		if [[ -d "${appAutoPatchFolder}" ]]; then
			log_exit "This computer is running macOS ${macos_version_major} and aap requires macOS 12 Monterey or newer."
			exit_error
		else # aap is not installed yet.
			log_exit "This computer is running macOS ${macos_version_major} and aap requires macOS 12 Monterey or newer."
			exit 1
		fi
	fi
	
	# Check for any previous aap processes and kill them.
	local aapPreviousPID
	aapPreviousPID=$(pgrep -F "${appAutoPatchPIDfile}" 2> /dev/null)
	if [[ -n "${aapPreviousPID}" ]]; then
		[[ -d "${appAutoPatchLogFolder}" ]] && log_status "Found previous aap instance running with PID ${aapPreviousPID}, killing processes..."
		[[ ! -d "${appAutoPatchLogFolder}" ]] && log_echo "Status: Found previous aap instance running with PID ${aapPreviousPID}, killing processes..."
		kill -9 "${aapPreviousPID}" > /dev/null 2>&1
        killProcess "Dialog"
	fi
	
	# Create new ${appAutoPatchPIDfile} for this instance of aap
	echo $$ > "${appAutoPatchPIDfile}"
	
	# If aap crashes or the system restarts unexpectedly before aap exits, then automatically launch again.
	defaults delete "${appAutoPatchLocalPLIST}" NextAutoLaunch 2> /dev/null
	
	# Check for aap installation.
	local aapCurrentFolder
	aapCurrentFolder=$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")
	! { [[ "${aapCurrentFolder}" == "${appAutoPatchFolder}" ]] || [[ "${aapCurrentFolder}" == $(dirname "${appAutoPatchLink}") ]]; } && install_app_auto_patch
	
    # Since swiftDialog and App Auto-Patch require at least macOS 12 Monterey, first confirm the major OS version
    if [[ "${osMajorVersion}" -ge 12 ]] ; then
        log_info "macOS ${osMajorVersion} installed; proceeding ..."
    else
        # The Mac is running an operating system older than macOS 12 Monterey; exit with an error
        log_error "swiftDialog and ${appTitle} require at least macOS 12 Monterey and this Mac is running ${osVersion} (${osBuild}), exiting with an error."
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Monterey (or newer), but found macOS '"${osVersion}"' ('"${osBuild}"').\r\r" with title "'"${scriptFunctionalName}"': Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
        #preFlight "Executing /usr/bin/open '${outdatedOsAction}' …"
        #su - "${currentUserAccountName}" -c "/usr/bin/open \"${outdatedOsAction}\""
        exit 1
    fi

    #Check for Dialog
    get_dialog
    
    # Check for logs that need to be archived.
    archive_logs
	
	#Checking for AAPLogo
    if [[ ! -e "${appAutoPatchFolder}/AAPLogo.png" ]]; then
        log_info "downloading AAP Logo"
        logoImage="https://raw.githubusercontent.com/App-Auto-Patch/App-Auto-Patch/main/Images/AAPLogo.png"
        logoImageFileName=$( echo ${logoImage} | awk -F '/' '{print $NF}' )
        curl -L --location --silent "$logoImage" -o "${appAutoPatchFolder}/${logoImageFileName}"
    fi
    logoImage="${appAutoPatchFolder}/AAPLogo.png"
    
    # After installation is verified, the startup workflow can begin.
	log_aap "**** App Auto-Patch ${scriptVersion} - AAP STARTUP WORKFLOW ****"
	write_status "Running: Startup workflow."

    get_logged_in_user
    # Computer stats here
    log_info "Computer Serial: $serialNumber"
    log_info "Computer Name: $computerName"
    log_info "OS Version: $osVersion"
    log_info "OS Build: $osBuild"
    log_info "Logged in-user: $currentUserAccountName"
    get_mdm

	
	# Manage the ${verbose_mode_option} and if enabled start additional logging.
	[[ "${reset_defaults_option}" == "TRUE" ]] && defaults delete "${appAutoPatchLocalPLIST}" VerboseMode 2> /dev/null
    if [[ -f ${appAutoPatchManagedPLIST}.plist ]]; then
		local verbose_mode_managed
		verbose_mode_managed=$(defaults read "${appAutoPatchManagedPLIST}" VerboseMode 2> /dev/null)
    fi

	if [[ -f ${appAutoPatchLocalPLIST}.plist ]]; then
		local verbose_mode_local
		verbose_mode_local=$(defaults read "${appAutoPatchLocalPLIST}" VerboseMode 2> /dev/null)
	fi

	[[ -n "${verbose_mode_managed}" ]] && verbose_mode_option="${verbose_mode_managed}"
	{ [[ -z "${verbose_mode_managed}" ]] && [[ -z "${verbose_mode_option}" ]] && [[ -n "${verbose_mode_local}" ]]; } && verbose_mode_option="${verbose_mode_local}"
    if [[ "${verbose_mode_option}" -eq 1 ]] || [[ "${verbose_mode_option}" == "TRUE" ]]; then
		verbose_mode_option="TRUE"
		defaults write "${appAutoPatchLocalPLIST}" VerboseMode -bool true
	else
		verbose_mode_option="FALSE"
		defaults delete "${appAutoPatchLocalPLIST}" VerboseMode 2> /dev/null
	fi
	if [[ "${verbose_mode_option}" == "TRUE" ]]; then
		log_verbose "Verbose mode enabled."
		log_verbose "aapCurrentFolder is: ${aapCurrentFolder}"
		log_verbose "Uptime is: $(uptime)"
	fi

    # Manage the ${debug_mode_option}
    if [[ -f "${appAutoPatchLocalPLIST}.plist" ]]; then
        local debug_mode_local
        debug_mode_local=$(defaults read "${appAutoPatchLocalPLIST}" DebugMode 2> /dev/null)
    fi
    [[ -n "${debug_mode_managed}" ]] && debug_mode_option="${debug_mode_managed}"
    { [[ -z "${debug_mode_managed}" ]] && [[ -z "${debug_mode_option}" ]] && [[ -n "${debug_mode_local}" ]]; } && debug_mode_option="${debug_mode_local}"
	if [[ "${debug_mode_option}" -eq 1 ]] || [[ "${debug_mode_option}" == "TRUE" ]]; then
		debug_mode_option="TRUE"
		defaults write "${appAutoPatchLocalPLIST}" DebugMode -bool true
	else
		debug_mode_option="FALSE"
		defaults delete "${appAutoPatchLocalPLIST}" DebugMode 2> /dev/null
	fi
	if [[ "${debug_mode_option}" == "TRUE" ]]; then
		log_debug "Debug mode enabled."
	fi
	
	# In case aap is running at system startup, wait for the loginwindow process befor continuing.
	local startup_timeout
	startup_timeout=0
	while [[ ! $(pgrep "loginwindow") ]] && [[ "${startup_timeout}" -lt 600 ]]; do
		log_status "Waiting for macOS startup to complete..."
		sleep 10
		startup_timeout=$((startup_timeout + 10))
	done
	
	# Detailed system and user checks.
	get_logged_in_user
	
	# Initial Parameter and helper validation, if any of these fail then it's unsafe for the workflow to continue.
	get_preferences

    # Check for Installomator
    get_installomator

    # Management parameter options
    manage_parameter_options

	#Check if workflow_install_now workflow was triggered
    if [[ "${workflow_install_now_option}" == "TRUE" ]] || [[ -f "${WORKFLOW_INSTALL_NOW_FILE}" ]]; then
        log_status "Install now alternate workflow enabled."
        workflow_install_now_option="TRUE" # This is re-set in case the script restarts.
        InteractiveModeOption=2 # This is to make sure all dialogs are displayed for the install now workflow
        touch "${WORKFLOW_INSTALL_NOW_FILE}" # This is created in case the script restarts.
    fi
    
    #Check if workflow_install_now silemnt workflow was triggered
    if [[ "${workflow_install_now_silent_option}" == "TRUE" ]] || [[ -f "${WORKFLOW_INSTALL_NOW_SILENT_FILE}" ]]; then
        log_status "Install now silent alternate workflow enabled."
        workflow_install_now_silent_option="TRUE" # This is re-set in case the script restarts.
        InteractiveModeOption=0 # This is to make sure all dialogs are displayed for the install now workflow
        touch "${WORKFLOW_INSTALL_NOW_SILENT_FILE}" # This is created in case the script restarts.
    fi

    
	if [[ "${check_error}" == "TRUE" ]] || [[ "${option_error}" == "TRUE" ]] || [[ "${helper_error}" == "TRUE" ]]; then
		log_exit "Initial startup validation failed."
		write_status "Inactive Error: Initial startup validation failed."
		exit_error
	fi
	
	# If aap is running via Jamf, then restart via LaunchDaemon to release the jamf parent process.
	if [[ "${parent_process_is_jamf}" == "TRUE" ]]; then
        if [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
            log_aap "Status: Found that Jamf is installing or is the parent process and Automatic Relaunch is disabled. Exiting."
            log_status "Inactive: Jamf is parent process or AAP Installing. Automatic relaunch is disabled."
            /usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string FALSE" "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
            { sleep 5; launchctl bootout system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; } &
            disown
            exit_clean
        else
		log_status "Found that Jamf is installing or is the parent process, restarting via App Auto-Patch LaunchDaemon..."
		{ sleep 5; launchctl bootout system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; } &
		disown
		exit_clean
        fi
	fi
	
	# If aap is running from outside the ${appAutoPatchFolder}, then restart via LaunchDaemon to release any parent installer process.
	if ! { [[ "${aapCurrentFolder}" == "${appAutoPatchFolder}" ]] || [[ "${aapCurrentFolder}" == $(dirname "${appAutoPatchLink}") ]]; }; then
        if [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
            log_aap "Status: Found App Auto-Patch is installing and Automatic Relaunch is disabled. Exiting."
            log_status "Inactive: App Auto-Patch Installing. Automatic relaunch is disabled."
            /usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string FALSE" "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
            { sleep 5; launchctl bootout system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; } &
            disown
            exit_clean
        else
		log_status "Found that App Auto-Patch is installing, restarting via App Auto-Patch LaunchDaemon..."
		{ sleep 5; launchctl bootout system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; } &
        disown
		exit_clean
        fi
	fi
	
	# Wait for a valid network connection. If there is still no network after two minutes, an automatic deferral is started.
	local network_timeout
	network_timeout=0
	while [[ $(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l) -le 0 ]] && [[ "${network_timeout}" -lt 120 ]]; do
		log_status "Waiting for network..."
		sleep 5
		network_timeout=$((network_timeout + 5))
	done
    if [[ $(ifconfig -a inet 2>/dev/null | sed -n -e '/127.0.0.1/d' -e '/0.0.0.0/d' -e '/inet/p' | wc -l) -le 0 ]]; then
        deferral_timer_minutes="${deferral_timer_error_minutes}"
        log_error "Network unavailable, trying again in ${deferral_timer_minutes} minutes."
        write_status "Pending: Network unavailable, trying again in ${deferral_timer_minutes} minutes."
        set_auto_launch_deferral
    fi
	
    # Set icon based on whether the Mac is a desktop or laptop
    if system_profiler SPPowerDataType | grep -q "Battery Power"; then
        icon="SF=laptopcomputer.and.arrow.down,weight=regular,colour1=gray,colour2=red"
    else
        icon="SF=desktopcomputer.and.arrow.down,weight=regular,colour1=gray,colour2=red"
    fi

    # Create `overlayicon` from Self Service's custom icon (thanks, @meschwartz!)
    if [[ "$useOverlayIcon" == "TRUE" ]]; then
        if defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path &> /dev/null; then
            # Use Self Service icon for overlay if found
            xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
            overlayicon="/var/tmp/overlayicon.icns"
        # Computer is not Jamf enrolled (or can't use Self Service logo), get a different overlay icon
        elif [[ -e "/Library/Application Support/JAMF/Jamf.app" ]]; then
            overlayicon="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"
        elif [[ -e "/Applications/Self-Service.app" ]]; then
            overlayicon="/Applications/Self-Service.app/Contents/Resources/AppIcon.icns"
        elif [[ -e "/Applications/Manager.app" ]]; then
            overlayicon="/Applications/Manager.app/Contents/Resources/AppIcon.icns"
        elif [[ -e "/Library/Addigy/macmanage/MacManage.app" ]]; then
            overlayicon="/Library/Addigy/macmanage/MacManage.app/Contents/Resources/atom.icns"
        elif [[ "$(profiles show | grep -A4 "Management Profile" | sed -n -e 's/^.*profileIdentifier: //p')" == "Microsoft.Profiles.MDM" ]]; then
            # Managed by Intune
            if [[ -e "/Library/Intune/Microsoft Intune Agent.app" ]]; then
                overlayicon="/Library/Intune/Microsoft Intune Agent.app/Contents/Resources/AppIcon.icns"
            elif [[ -e "/Applications/Company Portal.app" ]]; then
            # Added for cases when the Intune Agent is not yet present
                overlayicon="/Applications/Company Portal.app/Contents/Resources/AppIcon.icns"
            fi
        elif [[ -e "/Applications/Workspace ONE Intelligent Hub.app" ]]; then
            overlayicon="/Applications/Workspace ONE Intelligent Hub.app/Contents/Resources/AppIcon.icns"
        elif [[ -e "/Applications/Kandji Self Service.app" ]]; then
            overlayicon="/Applications/Kandji Self Service.app/Contents/Resources/AppIcon.icns"
        elif [[ -e "/usr/local/sbin/FileWave.app" ]]; then
            overlayicon="/usr/local/sbin/FileWave.app/Contents/Resources/fwGUI.app/Contents/Resources/kiosk.icns"
        elif [[ -e "/System/Applications/App Store.app" || -e "/Applications/App Store.app" ]]; then
            if [[ $(sw_vers -buildVersion) > "19" ]]; then
                overlayicon="/System/Applications/App Store.app/Contents/Resources/AppIcon.icns"
            else
                overlayicon="/Applications/App Store.app/Contents/Resources/AppIcon.icns"
            fi
        fi
    else
        overlayicon=""
    fi
    
    if [[ "${debug_mode_option}" == "TRUE" ]]; then
        infoTextScriptVersion="DEBUG MODE | Dialog: v${dialogVersion} • ${appTitle}: v${scriptVersion}"
    else
        infoTextScriptVersion="${scriptVersion}"
    fi
    
    set_display_strings_language
    supportTeamHyperlink="[${supportTeamWebsite}](https://${supportTeamWebsite})"
    helpMessage="${display_string_help_message_intro} ${supportTeamName}: \n- ${display_string_help_message_telephone} ${supportTeamPhone} \n- ${display_string_help_message_email} ${supportTeamEmail}  \n- ${display_string_help_message_help_website} ${supportTeamHyperlink}  \n\n${display_string_help_message_computer_info} \n- ${display_string_help_message_operating_system} $osVersion ($osBuild)  \n- ${display_string_help_message_serial} $serialNumber  \n- ${display_string_help_message_dialog} $dialogVersion  \n- ${display_string_help_message_started} $timestamp  \n- ${display_string_help_message_script_version} $scriptVersion" # helpMessage="If you need assistance, please contact ${supportTeamName}:  \n- **Telephone:** ${supportTeamPhone}  \n- **Email:** ${supportTeamEmail}  \n- **Help Website:** ${supportTeamHyperlink}  \n\n**Computer Information:**  \n- **Operating System:**  $osVersion ($osBuild)  \n- **Serial Number:** $serialNumber  \n- **Dialog:** $dialogVersion  \n- **Started:** $timestamp  \n- **Script Version:** $scriptVersion"
    infobox="${display_string_patching_infobox_computer_name} \n\n- $computerName \n\n${display_string_patching_infobox_macos_version} \n\n- $osVersion ($osBuild)"
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # "Patching" dialog Title, Message, and Icon
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    dialogPatchingConfigurationOptions=(
        --title "${appTitle}"
        --message "${display_string_patching_message} ..." # Updating the following apps …
        --commandfile "$dialogCommandFile"
        --moveable
        --button1text "${display_string_patching_button1}" # Done
        --button1disabled
        --height 600
        --width 650
        --position bottomright
        --progress
        --helpmessage "${helpMessage}"
        --infobox "${infobox}" # "**Computer Name:**  \n\n- $computerName  \n\n**macOS Version:**  \n\n- $osVersion ($osBuild)"
        --infotext "${infoTextScriptVersion}"
        --windowbuttons min
        --titlefont size=18
        --messagefont size=14
        --quitkey k
        --icon "$icon"
        --overlayicon "$overlayicon"
    )

	if [[ "$dialogOnTop" == "TRUE" ]]; then
		dialogPatchingConfigurationOptions+=(--ontop)
	fi
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # "Discover" dialog Title, Message and Icon
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    dialogDiscoverConfigurationOptions=(
        --title "${appTitle}"
        --message "${display_string_discovery_message} ..." # "Analyzing installed apps …"
        --icon "$icon"
        --overlayicon "$overlayicon"
        --commandfile "$dialogCommandFile"
        --moveable
        --windowbuttons min
        --mini
        --position bottomright
        --progress
        --progresstext "${display_string_discovery_progress} ..." # Scanning …
        --quitkey k
    )
    
	if [[ "$dialogOnTop" == "TRUE" ]]; then
		dialogDiscoverConfigurationOptions+=(--ontop)
	fi

    #Running this function for something webhook related
    gather_error_log

}

# MARK: *** Process Management ***
################################################################################

# This function is only used for debugging from the command line to interrupt the workflow and wait for the user to press Enter to continue. Insert the following line wherever you want an interrupt to occur:
# [[ "${current_user_account_name}" != "FALSE" ]] && interactive_interrupt
interactive_interrupt() {

    log_status "**** App Auto Patch. ${scriptVersion} - INTERACTIVE INTERRUPT - PRESS ENTER TO CONTINUE ****"

    /bin/bash read -n 1 -p -r >/dev/null 2>&1
}

# Installation
install_app_auto_patch() {
    [[ ! -d "${appAutoPatchFolder}" ]] && mkdir -p "${appAutoPatchFolder}"
    [[ ! -d "${appAutoPatchLogFolder}" ]] && mkdir -p "${appAutoPatchLogFolder}"
    [[ ! -d "${appAutoPatchLogArchiveFolder}" ]] && mkdir -p "${appAutoPatchLogArchiveFolder}"

    log_notice "###### App Auto-Patch ${scriptVersion} - Installing ... ######"
    write_status "Running: Installation workflow"

    log_install "Copying aap to: ${appAutoPatchFolder}/appautopatch"
    cp "${BASH_SOURCE[0]:-${(%):-%x}}" "${appAutoPatchFolder}/appautopatch" > /dev/null 2>&1
    if [[ ! -d "/usr/local/bin" ]]; then
        log_install "Creating local search path folder: /usr/local/bin"
        mkdir -p "/usr/local/bin"
        chmod -R a+rx "/usr/local/bin"
    fi

    log_install "Creating aap search path link: ${appAutoPatchLink}"
    ln -s "${appAutoPatchFolder}/appautopatch" "${appAutoPatchLink}" > /dev/null 2>&1

    log_install "Creating AAP LauchDaemon helper: ${appAutoPatchFolder}/aap-starter"

    /bin/cat <<EOAS > "${appAutoPatchFolder}/aap-starter"
#!/bin/bash
# Exit if App Auto Patch is already running.
[[ "\$(pgrep -F "${appAutoPatchPIDfile}" 2> /dev/null)" ]] && exit 0

# Exit if the App Auto Patch auto launch workflow is disabled, or deferred until a system restart, or deferred until a later date.
next_auto_launch=\$(defaults read "${appAutoPatchLocalPLIST}" NextAutoLaunch 2> /dev/null)
if [[ "\${next_auto_launch}" == "FALSE" ]]; then # Exit if auto launch is disabled.
	exit 0
elif [[ -z "\${next_auto_launch}" ]]; then # Exit if deferred until a system restart.
	mac_last_startup_saved_epoch=\$(date -j -f "%Y-%m-%d:%H:%M:%S" "\$(defaults read "${appAutoPatchLocalPLIST}" MacLastStartup 2> /dev/null)" +"%s" 2> /dev/null)
	mac_last_startup_epoch=\$(date -j -f "%b %d %H:%M:%S" "\$(last reboot | head -1 | cut -c 41- | xargs):00" +"%s" 2> /dev/null)
	[[ -n "\${mac_last_startup_saved_epoch}" ]] && [[ -n "\${mac_last_startup_epoch}" ]] && [[ "\${mac_last_startup_saved_epoch}" -ge "\${mac_last_startup_epoch}" ]] && exit 0
elif [[ \$(date +%s) -lt \$(date -j -f "%Y-%m-%d:%H:%M:%S" "\${next_auto_launch}" +"%s" 2> /dev/null) ]]; then # Exit if deferred until a later date.
	exit 0
fi

# If aap-starter has not exited yet, then it's time to start App Auto Patch.
echo "\$(date +"%a %b %d %T") \$(hostname -s) \$(basename "\$0")[\$\$]: **** App Auto-Patch ${scriptVersion} - LAUNCHDAEMON ****" | tee -a "${appAutoPatchLog}"
"${appAutoPatchFolder}/appautopatch" &
disown
exit 0
EOAS

if [[ -f "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist" ]]; then
    log_install "Removing previous AAP Launch Daemon: /Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"
    launchctl bootout system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist" 2> /dev/null
    rm -f "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist" 2> /dev/null
fi

log_install "Creating AAP LaunchDaemon: /Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"
/bin/cat <<EOLD > "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${appAutoPatchLaunchDaemonLabel}</string>
	<key>ProgramArguments</key>
	<array>
		<string>${appAutoPatchFolder}/aap-starter</string>
	</array>
	<key>UserName</key>
	<string>root</string>
	<key>AbandonProcessGroup</key>
	<true/>
	<key>RunAtLoad</key>
	<true/>
	<key>StartInterval</key>
	<integer>60</integer>
</dict>
</plist>
EOLD

log_install "Setting permissions for installed items"
chown root:wheel "/Library/Management"
chmod 777 "/Library/Management"
chown -R root:wheel "${appAutoPatchFolder}"
chmod -R 777 "${appAutoPatchFolder}"
chmod -R a+r "${appAutoPatchFolder}"
chmod -R go-w "${appAutoPatchFolder}"
chmod a+x "${appAutoPatchFolder}/appautopatch"
chmod a+x "${appAutoPatchFolder}/aap-starter"
chown root:wheel "${appAutoPatchLink}"
chmod a+rx "${appAutoPatchLink}"
chmod go-w "${appAutoPatchLink}"
chmod 644 "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"
chown root:wheel "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"
defaults write "${appAutoPatchLocalPLIST}" AAPVersion -string "${scriptVersion}"

    if ! { [[ -f "${appAutoPatchFolder}/appautopatch" ]] || [[ -f "${appAutoPatchLink}" ]]; }; then
        log_install "ERROR: App Auto Patch failed to install correctly... Try pre-loading the script to a local temporary folder and executing the script from there to install properly"
        option_error="TRUE"
    fi
}

function uninstall_app_auto_patch() {

    # Boot out launch daemon and remove
    log_uninstall "Removing previous AAP Launch Daemon: /Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"
    launchctl bootout system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist" 2> /dev/null
    rm -f "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist" 2> /dev/null

    # Remove the App Auto Patch sym link
    log_uninstall "Removing ${appAutoPatchLink}"
    rm -rf ${appAutoPatchLink}

    # Remove the App Auto Patch Folder
    log_uninstall "Removing ${appAutoPatchFolder}"
    rm -rf ${appAutoPatchFolder}

    exit 0
}

install_dialog() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    log_install "Installing swiftDialog..."

    # Create a temporary working directory
    workDirectory=$( basename "$0" )
    tempDirectory=$( mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

    # Download the installer package
    curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

    # Verify the download
    teamID=$(spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

    # Install the package if Team ID validates
    if [[ "$expectedDialogTeamID" == "$teamID" ]]; then
        /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
        sleep 2
        dialogVersion=$( /usr/local/bin/dialog --version )
        log_install "swiftDialog version ${dialogVersion} installed; proceeding..."
    else
        # Display a so-called "simple" dialog if Team ID fails to validate
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "'"${scriptFunctionalName}"': Error" buttons {"Close"} with icon caution'
        exitCode="1"
        quitScript
    fi

    # Remove the temporary working directory when done
    rm -Rf "$tempDirectory"

}

get_dialog() {

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
        log_install "swiftDialog not found. Installing..."
        install_dialog
    else
        dialogVersion=$(/usr/local/bin/dialog --version)
        if [[ "${dialogVersion}" < "${dialogTargetVersion}" ]]; then
            log_install "swiftDialog version ${dialogVersion} found but swiftDialog ${dialogTargetVersion} or newer is required; updating..."
            install_dialog
        else
            log_install "swiftDialog version ${dialogVersion} found; proceeding..."
        fi
    fi

}

get_installomator() {

    # The latest version of Installomator and collateral will be downloaded to $installomatorPath defined above
    # Does the $installomatorPath Exist or does it need to be created
    if [ ! -d "${installomatorPath}" ]; then
        log_verbose  "$installomatorPath does not exist, create it now"
        mkdir "${installomatorPath}"
    else
        log_verbose  "AAP Installomator directory exists"
    fi
    
    log_verbose  "Checking for Installomator.sh at $installomatorScript"

    if ! [[ -f $installomatorScript ]]; then
        log_warning "Installomator was not found at $installomatorPath"
        log_info "Attempting to download Installomator.sh at $installomatorPath"
        
        if [[ "$installomatorVersion" == "Release" ]] || [[ "$installomatorVersion" == "release" ]]; then
            log_info "Attempting to download Installomator release version"
            latestURL=$(curl -sSL -o - "https://api.github.com/repos/Installomator/Installomator/releases/latest" | grep tarball_url | awk '{gsub(/[",]/,"")}{print $2}')
        elif [[ "$installomatorVersion" == "Custom" ]] || [[ "$installomatorVersion" == "custom" ]]; then
            log_info "Attempting to download Installomator from Custom Repo"
            latestURL="https://codeload.github.com/$installomatorVersionCustomRepoPath/legacy.tar.gz/$(curl -sSL -o - "https://api.github.com/repos/$installomatorVersionCustomRepoPath/branches" | grep -A2 "$installomatorVersionCustomBranchName" | tail -1 | cut -d'"' -f4)"
        else
            log_info "Attempting to download Installomator main version"
            latestURL="https://codeload.github.com/Installomator/Installomator/legacy.tar.gz/$(curl -sSL -o - "https://api.github.com/repos/Installomator/Installomator/branches" | grep -A2 "main" | tail -1 | cut -d'"' -f4)"
        fi
        
        tarPath="$installomatorPath/installomator.latest.tar.gz"

        log_verbose  "Downloading ${latestURL} to ${tarPath}"

        curl -sSL -o "$tarPath" "$latestURL" || log_fatal "Unable to download. Check ${installomatorPath} is writable, or that you haven't hit Github's API rate limit."

        log_verbose  "Extracting ${tarPath} into ${installomatorPath}"
        tar -xz -f "$tarPath" --strip-components 1 -C "$installomatorPath" || log_fatal "Unable to extract ${tarPath}. Corrupt or incomplete download?"
        
        sleep .2

        rm -rf $installomatorPath/*.tar.gz
    else
        if [[ "${installomator_update_disable_option}" -eq 1 ]] || [[ "${installomator_update_disable_option}" == "TRUE" ]]; then
            log_notice "Installomator was found at $installomatorPath, Installomator Update Disabled: Skipping Version Check"
        else
        log_notice "Installomator was found at $installomatorPath, checking version ..."
        if [[ "$installomatorVersion" == "Release" ]] || [[ "$installomatorVersion" == "release" ]]; then
            echo "pulling from Installomator Latest Release"
            latestURL=$(curl -sSL -o - "https://api.github.com/repos/Installomator/Installomator/releases/latest" | grep tarball_url | awk '{gsub(/[",]/,"")}{print $2}')
            appNewVersion=$(curl -sLI "https://github.com/Installomator/Installomator/releases/latest" | grep -i "^location" | tr "/" "\n" | tail -1 | sed 's/[^0-9\.]//g')
            appVersion="$(cat $fragmentsPath/version.sh)"
        elif [[ "$installomatorVersion" == "Custom" ]] || [[ "$installomatorVersion" == "custom" ]]; then
            echo "Pulling from custom installomator"
            latestURL="https://codeload.github.com/$installomatorVersionCustomRepoPath/legacy.tar.gz/$(curl -sSL -o - "https://api.github.com/repos/$installomatorVersionCustomRepoPath/branches" | grep -A2 "$installomatorVersionCustomBranchName" | tail -1 | cut -d'"' -f4)"
            appNewVersion="$(curl -sL "https://raw.githubusercontent.com/$installomatorVersionCustomRepoPath/refs/heads/$installomatorVersionCustomBranchName/Installomator.sh" | grep VERSIONDATE= | cut -d'"' -f2)"
            appVersion="$(cat "/Library/Management/AppAutoPatch/Installomator/Installomator.sh" | grep VERSIONDATE= | cut -d'"' -f2)"
            # convert to epoch
            appNewVersion=$(date -j -f "%Y-%m-%d" "${appNewVersion}" +%s)
            appVersion=$(date -j -f "%Y-%m-%d" "${appVersion}" +%s)
        else
            echo "Pulling from Installomator Main Branch"
            latestURL="https://codeload.github.com/Installomator/Installomator/legacy.tar.gz/$(curl -sSL -o - "https://api.github.com/repos/Installomator/Installomator/branches" | grep -A2 "main" | tail -1 | cut -d'"' -f4)"
            appNewVersion="$(curl -sL "https://raw.githubusercontent.com/Installomator/Installomator/refs/heads/main/Installomator.sh" | grep VERSIONDATE= | cut -d'"' -f2)"
            appVersion="$(cat "/Library/Management/AppAutoPatch/Installomator/Installomator.sh" | grep VERSIONDATE= | cut -d'"' -f2)"
            # convert to epoch
            appNewVersion=$(date -j -f "%Y-%m-%d" "${appNewVersion}" +%s)
            appVersion=$(date -j -f "%Y-%m-%d" "${appVersion}" +%s)
        fi

        #if [[ ${appVersion} -lt ${appNewVersion} ]]; then
        if [[ ${appVersion} != ${appNewVersion} ]]; then
            log_error "Installomator is installed but is out of date. Versions before 10.0 function unpredictably with App Auto Patch."
            log_info "Removing previously installed Installomator version ($appVersion) and reinstalling with the latest version ($appNewVersion)"
            remove_installomator_outdated
            sleep .2
            get_installomator
        else
            log_info "Installomator latest version ($appVersion) installed, continuing..."
        fi
        fi
    fi

    # Set Installomator to DEBUG or PRODUCTION
    if [[ "$debug_mode_option" == "TRUE" ]]; then
        log_debug "Setting Installomator to Debug Mode"
        /usr/bin/sed -i.backup1 "s|DEBUG=1|DEBUG=2|g" $installomatorScript
        sleep .2
        /usr/bin/sed -i.backup1 "s|DEBUG=0|DEBUG=2|g" $installomatorScript
        sleep .2
        /usr/bin/sed -i.backup1 "s|MacAdmins Slack)|MacAdmins Slack )|g" $installomatorScript
        sleep .2
        /usr/bin/sed -i.backup1 "s|There is no newer version available|same as installed|g" $installomatorScript
        sleep .2
    else
        log_info "Setting Installomator to Production Mode"
        /usr/bin/sed -i.backup1 "s|DEBUG=1|DEBUG=0|g" $installomatorScript
        sleep .2
        /usr/bin/sed -i.backup1 "s|DEBUG=2|DEBUG=0|g" $installomatorScript
        sleep .2
        /usr/bin/sed -i.backup1 "s|MacAdmins Slack)|MacAdmins Slack )|g" $installomatorScript
        sleep .2
        /usr/bin/sed -i.backup1 "s|There is no newer version available|same as installed|g" $installomatorScript
        sleep .2
    fi

    rm -rf "${installomatorScript}.backup1"
}

remove_installomator_outdated() {

    log_info "Removing Installomator ..."
    rm -rf ${installomatorPath}

}

remove_installomator() {
    if [[ "$removeInstallomatorPath" == "true" ]]; then
        log_info "Removing Installomator ..."
        rm -rf ${installomatorPath}
    else
        log_info "Installomator removal set to false, continuing ..."
    fi
}

get_logged_in_user() {
    [[ -z "${currentUserAccountName}" ]] && currentUserAccountName="FALSE"
    [[ -z "${currentUserID}" ]] && currentUserID="FALSE"
    local currentUserAccountName_response
    currentUserAccountName_response=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ {$1=$2="";print $0;}' | xargs)
    local currentUserID_response
    currentUserID_response=$(id -u "${currentUserAccountName_response}" 2> /dev/null)
    log_verbose  "currentUserAccountName is: ${currentUserAccountName}"
    log_verbose  "currentUserID is: ${currentUserID}"
    log_verbose  "currentUserAccountName_response is: ${currentUserAccountName_response}"
    log_verbose  "currentUserID_response is: ${currentUserID_response}"

    # If this function was already run earlier then check to see if ${currentUserAccountName} and ${currentUserID} are the same as before, if so then it's not necessary to continue this function.
    if [[ "${currentUserAccountName}" != "FALSE" ]] && [[ "${currentUserID}" != "FALSE" ]] && [[ "${currentUserAccountName}" == "${currentUserAccountName_response}" ]] && [[ "${currentUserID}" == "${currentUserID_response}" ]]; then
        return 0
    fi

    # Make sure we have a "normal" logged in user.
    if [[ -z "${currentUserAccountName_response}" ]]; then
        { [[ $(id -u) -eq 0 ]] && [[ -d "${AAP_LOG_FOLDER}" ]]; } && log_status "No GUI user currently logged in."
        { [[ $(id -u) -ne 0 ]] || [[ ! -d "${AAP_LOG_FOLDER}" ]]; } && log_echo "Status: No GUI user currently logged in."
    elif [[ "${currentUserAccountName_response}" = "root" ]] || [[ "${currentUserAccountName_response}" = "_mbsetupuser" ]] || [[ "${currentUserAccountName_response}" = "loginwindow" ]]; then
        { [[ $(id -u) -eq 0 ]] && [[ -d "${AAP_LOG_FOLDER}" ]]; } && log_status "Current GUI user is system account: ${currentUserAccountName_response}"
        { [[ $(id -u) -ne 0 ]] || [[ ! -d "${AAP_LOG_FOLDER}" ]]; } && log_echo "Status: Current GUI user is system account: ${currentUserAccountName_response}"
    else # Normal locally logged in user.
        currentUserAccountName="${currentUserAccountName_response}"
        currentUserID=$(id -u "${currentUserAccountName}" 2> /dev/null)
        { [[ $(id -u) -eq 0 ]] && [[ -d "${AAP_LOG_FOLDER}" ]]; } && log_status "Current active GUI user is: ${currentUserAccountName} (${currentUserID})"
        { [[ $(id -u) -ne 0 ]] || [[ ! -d "${AAP_LOG_FOLDER}" ]]; } && log_echo "Status: Current active GUI user is: ${currentUserAccountName} (${currentUserID})"
    fi
    log_verbose  "currentUserAccountName is: ${currentUserAccountName}"
    log_verbose  "currentUserID is: ${currentUserID}"

    # Only collect user details if it's a "normal" GUI user.
    if [[ "${currentUserAccountName}" != "FALSE" ]] && [[ "${currentUserID}" != "FALSE" ]] && [[ -d "${AAP_LOG_FOLDER}" ]]; then
        current_user_guid=$(dscl . read "/Users/${currentUserAccountName}" GeneratedUID 2> /dev/null | awk '{print $2;}')
        current_user_real_name=$(dscl . read "/Users/${currentUserAccountName}" RealName 2> /dev/null | tail -1 | sed -e 's/^RealName: //g' -e 's/^ //g')
        log_verbose  "current_user_guid is: ${current_user_guid}"
        log_verbose  "current_user_real_name is: ${current_user_real_name}"
        current_user_is_admin="FALSE"
        current_user_has_secure_token="FALSE"
        current_user_is_volume_owner="FALSE"
        if [[ -n "${currentUserID}" ]] && [[ -n "${current_user_guid}" ]] && [[ -n "${current_user_real_name}" ]]; then
            [[ $(groups "${currentUserAccountName}" 2> /dev/null | grep -c 'admin') -gt 0 ]] && current_user_is_admin="TRUE"
            [[ $(dscl . read "/Users/${currentUserAccountName}" AuthenticationAuthority 2> /dev/null | grep -c 'SecureToken') -gt 0 ]] && current_user_has_secure_token="TRUE"
            [[ $(diskutil apfs listcryptousers / 2> /dev/null | grep -c "${current_user_guid}") -gt 0 ]] && current_user_is_volume_owner="TRUE"
        else
            log_error "Unable to determine account details for current user: ${currentUserAccountName}"; option_error="TRUE"
        fi
        log_verbose  "current_user_is_admin is: ${current_user_is_admin}"
        log_verbose  "current_user_has_secure_token is: ${current_user_has_secure_token}"
        log_verbose  "current_user_is_volume_owner is: ${current_user_is_volume_owner}"
    fi
}

get_mdm(){

    # Check MDM server enrollment
    if [[ -n "$(profiles list -output stdout-xml | awk '/com.apple.mdm/ {print $1}' | tail -1)" ]]; then
        # If enrolled in an MDM server, get the MDM's server_url
        server_url=$(/usr/bin/profiles list -output stdout-xml | grep -a1 'ServerURL' | sed -n 's/.*<string>\(https:\/\/[^\/]*\).*/\1/p' )
        if [[ -n "$server_url" ]]; then
            log_info "MDM server address: $server_url"
        else
            log_warning "Failed to get MDM URL!"
        fi
    else
        log_warning "Not enrolled in an MDM server."
    fi

    case "${server_url}" in
		*jamf*|*jss*)
			log_info "MDM is Jamf"
			mdmName="Jamf Pro"
		;;
		*microsoft*)
			log_info "MDM is Intune"
			mdmName="Microsoft Intune"
		;;
        *jumpcloud*)
            log_info "MDM is Jumpcloud"
            mdmName="Jumpcloud"
        ;;
        *addigy*)
            log_info "MDM is Addigy"
            mdmName="Addigy"
        ;;
		*)
			log_info "Unable to determine MDM from ServerURL"
		;;
	esac


}

#Evaluate if patching cadence has been completed or not
check_completion_status() {
    
    CurrentDate=$(date +"%Y-%m-%d")
    CurrentDateEpoch=$(date -j -f "%Y-%m-%d" "$CurrentDate" "+%s")
    
    #### Calculate Patch Week Start Date ####
    if [[ $patch_week_start_day != "" ]]; then
        # Get the current day of the week
        current_day=$(date +%u)
        # Calculate the number of days to subtract to get to the most recent patch week start date
        days_to_subtract=$((current_day - $patch_week_start_day))
        if [ $days_to_subtract -lt 0 ]; then
            days_to_subtract=$((days_to_subtract + 7))
        fi
        
        # Calculate the date of the most recent patch week start date
        Patch_Week_Start_Date=$(date -v "-$days_to_subtract"d "+%Y-%m-%d")
    else
        Patch_Week_Start_Date=$CurrentDate
    fi 
    
    PatchingComplete=$(defaults read "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus 2> /dev/null)
    PatchingStartDate=$(defaults read "${appAutoPatchLocalPLIST}" AAPPatchingStartDate 2> /dev/null)
    
    if [[ -z $PatchingComplete || -z $PatchingStartDate ]]; then
        log_info "Patching Completion Status or Start Date not set, setting values"
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus -bool false
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingStartDate "$Patch_Week_Start_Date"
        
        PatchingComplete=$(defaults read "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus 2> /dev/null)
        PatchingStartDate=$(defaults read "${appAutoPatchLocalPLIST}" AAPPatchingStartDate 2> /dev/null)
    fi

    # Commenting out old logic due to issue with timing of caluclation
    # statusDateEpoch=$(date -j -f "%Y-%m-%d" "$PatchingStartDate" "+%s")
    # EpochTimeSinceStatus=$(($CurrentDateEpoch - $statusDateEpoch))
    # DaysSinceStatus=$(($EpochTimeSinceStatus / 86400))

    # New Logic
    # Load the zsh datetime module
    zmodload zsh/datetime
    
    # Define the two dates (in YYYY-MM-DD format)
    date1="$PatchingStartDate"
    date2="$CurrentDate"
    
    # Convert the dates to seconds since epoch
    epoch1=$(strftime -r "%Y-%m-%d" $date1)
    epoch2=$(strftime -r "%Y-%m-%d" $date2)
    
    # Calculate the difference in seconds and convert to days
    diff_in_seconds=$((epoch2 - epoch1))
    DaysSinceStatus=$((diff_in_seconds / 86400))

    log_notice "Patching Completion Status is $PatchingComplete"
    log_notice "Patching Start Date is $PatchingStartDate"
    log_notice "Current Date: $CurrentDate"
    log_notice "Days Since Patching Start Date: $DaysSinceStatus"
    
    if [ ${DaysSinceStatus} -ge $days_until_reset ]; then
        log_info "Resetting Completion Status to False"
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus -bool false
        log_info "Setting Patch Week Start Date as $Patch_Week_Start_Date"
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingStartDate "$Patch_Week_Start_Date"
        PatchingStartDate=$(defaults read "${appAutoPatchLocalPLIST}" AAPPatchingStartDate 2> /dev/null)
        PatchingComplete=$(defaults read "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus 2> /dev/null)
        defaults delete "${appAutoPatchLocalPLIST}" DeadlineCounterFocus 2> /dev/null
        defaults delete "${appAutoPatchLocalPLIST}" DeadlineCounterHard 2> /dev/null
    fi
    
    if [[  $PatchingComplete == 1 ]]; then
        #This should be set by configuration # # # deferral_timer_minutes="1440"
        log_info "Patching Status Already Complete, trying again in ${deferral_timer_minutes} minutes."
        set_auto_launch_deferral
    elif [[  $PatchingComplete == 0 ]]; then
        log_info "Continuing App Auto-Patch Workflow"
    else
        log_info "Unknown Status... Setting status to False"
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus -bool false
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingStartDate "$Patch_Week_Start_Date"
        PatchingComplete=$(defaults read "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus 2> /dev/null)
        log_info "Continuing App Auto-Patch Workflow"
    fi
    
}

check_deadlines_days_date() {
    deadline_days_status="FALSE" # Deadline status modes: FALSE, SOFT, or HARD
    local current_epoch
    current_epoch=$(date +%s)
    workflow_zero_date_epoch=$(date -j -f "%Y-%m-%d" "${PatchingStartDate}" +"%s")
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: current_epoch is: ${current_epoch}"
    
    # Evaluate days deadlines and set ${deadline_days_status}, ${deadline_days_epoch}, and ${display_string_deadline_days}.
    if [[ -n "${deadline_days_focus}" ]]; then
        local deadline_days_focus_epoch
        deadline_days_focus_epoch=$(( workflow_zero_date_epoch + deadline_days_focus_seconds ))
        local deadline_days_focus_date
        deadline_days_focus_date=$(date -r "${deadline_days_focus_epoch}" +%Y-%m-%d:%H:%M)
        [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_focus_epoch: ${deadline_days_focus_epoch}"
        if [[ "${deadline_days_focus_epoch}" -lt "${current_epoch}" ]]; then
            log_status "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${PatchingStartDate}) HAS passed."
            deadline_days_status="FOCUS"
        else
            local deadline_days_focus_difference
            deadline_days_focus_difference=$(( deadline_days_focus_epoch - current_epoch ))
            [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_focus_difference is: ${deadline_days_focus_difference}"
            if [[ "${deadline_days_focus_difference}" -le 120 ]]; then
                log_status "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${PatchingStartDate}) is only ${deadline_days_focus_difference} seconds away, waiting for deadline to pass..."
                sleep $(( deadline_days_focus_difference + 1 ))
                log_status "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${PatchingStartDate}) HAS passed."
                deadline_days_status="FOCUS"
            else
                log_status "Status: Focus days deadline of ${deadline_days_focus_date} (${deadline_days_focus} day(s) after ${PatchingStartDate}) NOT passed."
            fi
        fi
    fi
    if [[ -n "${deadline_days_hard}" ]]; then
        local deadline_days_hard_epoch
        deadline_days_hard_epoch=$(( workflow_zero_date_epoch + deadline_days_hard_seconds ))
        local deadline_days_hard_date
        deadline_days_hard_date=$(date -r "${deadline_days_hard_epoch}" +%Y-%m-%d:%H:%M)
        [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_hard_epoch: ${deadline_days_hard_epoch}"
        if [[ "${deadline_days_hard_epoch}" -lt "${current_epoch}" ]]; then
            log_status "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${PatchingStartDate}) HAS passed."
            deadline_days_status="HARD"
        else
            local deadline_days_hard_difference
            deadline_days_hard_difference=$(( deadline_days_hard_epoch - current_epoch ))
            [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_hard_difference is: ${deadline_days_hard_difference}"
            if [[ "${deadline_days_hard_difference}" -le 120 ]]; then
                log_status "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${PatchingStartDate}) is only ${deadline_days_hard_difference} seconds away, waiting for deadline to pass..."
                sleep $(( deadline_days_hard_difference + 1 ))
                log_status "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${PatchingStartDate}) HAS passed."
                deadline_days_status="HARD"
            else
                log_status "Status: Hard days deadline of ${deadline_days_hard_date} (${deadline_days_hard} day(s) after ${PatchingStartDate}) NOT passed."
            fi
        fi
    fi
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_status is: ${deadline_days_status}"
    [[ -n ${deadline_days_hard} ]] && deadline_days_epoch="${deadline_days_hard_epoch}"
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_days_epoch is: ${deadline_days_epoch}"
    if [[ -n "${deadline_days_epoch}" ]]; then
        local display_string_deadline_days_only_date
        display_string_deadline_days_only_date=$(date -r "${deadline_days_epoch}" "+${DISPLAY_STRING_FORMAT_DATE}")
        local display_string_deadline_days_only_time
        display_string_deadline_days_only_time=$(date -r "${deadline_days_epoch}" "${DISPLAY_STRING_FORMAT_TIME}" | sed 's/^ *//g')
        if [[ $(date -r "${deadline_days_epoch}" "+%H:%M") == "00:00" ]]; then
            display_string_deadline_days="${display_string_deadline_days_only_date}"
        else
            #display_string_deadline_days="${display_string_deadline_days_only_date} - ${display_string_deadline_days_only_time}"
            display_string_deadline_days="${display_string_deadline_days_only_date}"
        fi
        [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: display_string_deadline_days_only_date is: ${display_string_deadline_days_only_date}"
        [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: display_string_deadline_days_only_time is: ${display_string_deadline_days_only_time}"
        [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: display_string_deadline_days is: ${display_string_deadline_days}"
    fi
    
    
    # Set ${deadline_epoch} and ${display_string_deadline} to the soonest of either days or date deadlines.
    
    deadline_epoch="${deadline_days_epoch}"
    display_string_deadline="${display_string_deadline_days}"
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deadline_epoch is: ${deadline_epoch}"
    
    # If there is a ${deadline_epoch}, then make sure no user deferral timer or display timeout exceeds the deadline.
    if [[ -n "${deadline_epoch}" ]]; then
        local deferral_timer_deadline_minutes
        deferral_timer_deadline_minutes=$(( ( deadline_epoch - current_epoch ) / 60 ))
        local deferral_timer_deadline_active
        deferral_timer_deadline_active="FALSE"
        [[ $deferral_timer_deadline_minutes -lt 2 ]] && deferral_timer_deadline_minutes=2
        [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deferral_timer_deadline_minutes is: ${deferral_timer_deadline_minutes}"
        if [[ -n "${deferral_timer_menu_minutes}" ]]; then
            local previous_ifs
            previous_ifs="${IFS}"; IFS=','
            local deferral_timer_menu_array
            #read -r -a deferral_timer_menu_array <<< "${deferral_timer_menu_minutes}"
            deferral_timer_menu_array=("${(@s/,/)deferral_timer_menu_minutes}")
            local deferral_timer_menu_reduced_array
            deferral_timer_menu_reduced_array=()
            local deferral_timer_menu_reduced
            deferral_timer_menu_reduced="FALSE"
            for deferral_timer_menu_item in "${deferral_timer_menu_array[@]}"; do
                if [[ $deferral_timer_deadline_minutes -le $deferral_timer_menu_item ]]; then
                    if [[ "${deferral_timer_menu_reduced}" == "FALSE" ]]; then
                        deferral_timer_menu_reduced_array+=("${deferral_timer_deadline_minutes}")
                        deferral_timer_menu_reduced="TRUE"
                        deferral_timer_deadline_active="TRUE"
                    fi
                else
                    deferral_timer_menu_reduced_array+=("${deferral_timer_menu_item}")
                fi
            done
            [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deferral_timer_menu_reduced is: ${deferral_timer_menu_reduced}"
            [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deferral_timer_menu_reduced_array is: ${deferral_timer_menu_reduced_array[*]}"
            if [[ "${deferral_timer_menu_reduced}" == "TRUE" ]]; then
                if [[ ${#deferral_timer_menu_reduced_array[@]} -gt 1 ]]; then
                    deferral_timer_menu_minutes="${deferral_timer_menu_reduced_array[*]}"
                    log_status "Warning: The deferral timer menu list has been reduced to ${deferral_timer_menu_minutes} minutes given the deferral deadline of: ${display_string_deadline}"
                else
                    unset deferral_timer_menu_minutes
                    log_status "Warning: Not showing the deferral timer menu given the deferral deadline of: ${display_string_deadline}"
                fi
            fi
            IFS="${previous_ifs}"
        fi
        if [[ -z "${deferral_timer_menu_minutes}" ]]; then
            if [[ $deferral_timer_deadline_minutes -lt $deferral_timer_minutes ]]; then
                log_status "Warning: Reducing user deferral timers to ${deferral_timer_deadline_minutes} minutes given the deferral deadline of: ${display_string_deadline}"
                deferral_timer_minutes="${deferral_timer_deadline_minutes}"
                [[ -n "${deferral_timer_focus_minutes}" ]] && deferral_timer_focus_minutes="${deferral_timer_deadline_minutes}"
                deferral_timer_deadline_active="TRUE"
            fi
        fi
        [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: deferral_timer_deadline_active is: ${deferral_timer_deadline_active}"
        if [[ "${deferral_timer_deadline_active}" == "TRUE" ]]; then
            if [[ -n "${dialog_timeout_default_seconds}" ]] && [[ $dialog_timeout_default_seconds -gt 120 ]]; then
                dialog_timeout_default_seconds=120
                log_status "Warning: Reducing the --dialog-timeout-default option to ${dialog_timeout_default_seconds} seconds given the approaching deferral deadline."
            fi
            if [[ -n "${dialog_timeout_restart_or_defer_seconds}" ]] && [[ $dialog_timeout_restart_or_defer_seconds -gt 120 ]]; then
                dialog_timeout_restart_or_defer_seconds=120
                log_status "Warning: Reducing the --dialog-timeout-restart-or-defer option to ${dialog_timeout_restart_or_defer_seconds} seconds given the approaching deferral deadline."
            fi
            if [[ -n "${dialog_timeout_soft_deadline_seconds}" ]] && [[ $dialog_timeout_soft_deadline_seconds -gt 120 ]]; then
                dialog_timeout_soft_deadline_seconds=120
                log_status "Warning: Reducing the --dialog-timeout-soft-deadline option to ${dialog_timeout_soft_deadline_seconds} seconds given the approaching deferral deadline."
            fi
            
        fi
    fi
}

# Evaluate if a process has told the display to not sleep or the user has enabled Focus or Do Not Disturb, and set ${user_focus_active} accordingly.
check_user_focus() {
    user_focus_active="FALSE"
	if [[ -n "${deadline_count_focus}" ]]|| [[ -n "${deadline_days_focus}" ]] ; then
        local focus_response
		focus_response=$(plutil -extract data.0.storeAssertionRecords.0.assertionDetails.assertionDetailsModeIdentifier raw -o - "/Users/${currentUserAccountName}/Library/DoNotDisturb/DB/Assertions.json" | grep -ic 'com.apple.')
		log_verbose  "focus_response is: ${focus_response}"
		if [[ "${focus_response}" -gt 0 ]]; then
			log_status "Focus or Do Not Disturb enabled for current user: ${currentUserAccountName}."
			user_focus_active="TRUE"
		fi
		local previous_ifs
		previous_ifs="${IFS}"; IFS=$'\n'
		local display_assertions_array
		display_assertions_array=($(pmset -g assertions | awk '/NoDisplaySleepAssertion | PreventUserIdleDisplaySleep/ && match($0,/\(.+\)/) && ! /coreaudiod/ {gsub(/^\ +/,"",$0); print};'))
		log_verbose  "display_assertions_array is:\n${display_assertions_array[*]}"
		if [[ -n "${display_assertions_array[*]}" ]]; then
			for display_assertion in "${display_assertions_array[@]}"; do
				log_status "The following Display Sleep Assertion was found: $(echo "${display_assertion}" | awk -F ':' '{print $1;}')"
			done
			user_focus_active="TRUE"
		fi
		IFS="${previous_ifs}"
	fi
	log_verbose  "user_focus_active is: ${user_focus_active}"
}
    
# Evaluate ${deadline_count_focus}, ${deadline_count_soft}, and ${deadline_count_hard}, then set ${user_focus_active}, ${deadline_count_status}, ${display_string_deadline_count}, and ${display_string_deadline_count_maximum} accordingly.
check_deadlines_count() {
    deadline_count_status="FALSE" # Deadline status modes: FALSE, SOFT, or HARD
    if [[ "${user_focus_active}" == "TRUE" ]]; then
        if [[ -n "${deadline_count_focus}" ]]; then
            local deadline_counter_focus_previous
            local deadline_counter_focus_current
            deadline_counter_focus_previous=$(defaults read "${appAutoPatchLocalPLIST}" DeadlineCounterFocus 2> /dev/null)
            if [[ -z "${deadline_counter_focus_previous}" ]]; then
                deadline_counter_focus_current=0
                defaults write "${appAutoPatchLocalPLIST}" DeadlineCounterFocus -int "${deadline_counter_focus_current}"
            else
                deadline_counter_focus_current=$((deadline_counter_focus_previous + 1))
                defaults write "${appAutoPatchLocalPLIST}" DeadlineCounterFocus -int "${deadline_counter_focus_current}"
            fi
            if [[ "${deadline_counter_focus_current}" -ge "${deadline_count_focus}" ]]; then
                log_status "Focus maximum deferral count of ${deadline_count_focus} HAS passed."
                deadline_count_status="FOCUS"
                user_focus_active="FALSE"
            else
                display_string_deadline_count_focus=$((deadline_count_focus - deadline_counter_focus_current))
                log_status "Focus maximum deferral count of ${deadline_count_focus} NOT passed with ${display_string_deadline_count_focus} remaining."
            fi
        else
            log_status "Focus or Do Not Disturb active, and no maximum focus deferral, so not incrementing deferral counters."
        fi
    fi

    if [[ "${user_focus_active}" == "FALSE" ]]; then
        if [[ -n "${deadline_count_hard}" ]]; then
            local deadline_counter_hard_previous
            local deadline_counter_hard_current
            deadline_counter_hard_previous=$(defaults read "${appAutoPatchLocalPLIST}" DeadlineCounterHard 2> /dev/null)
            if [[ -z "${deadline_counter_hard_previous}" ]]; then
                deadline_counter_hard_current=0
                defaults write "${appAutoPatchLocalPLIST}" DeadlineCounterHard -int "${deadline_counter_hard_current}"
            else
                deadline_counter_hard_current=$((deadline_counter_hard_previous + 1))
                defaults write "${appAutoPatchLocalPLIST}" DeadlineCounterHard -int "${deadline_counter_hard_current}"
            fi
            if [[ "${deadline_counter_hard_current}" -ge "${deadline_count_hard}" ]]; then
                log_status "Hard maximum deferral count of ${deadline_count_hard} HAS passed."
                deadline_count_status="HARD"
            else
                display_string_deadline_count_hard=$((deadline_count_hard - deadline_counter_hard_current))
                log_status "Hard maximum deferral count of ${deadline_count_hard} NOT passed with ${display_string_deadline_count_hard} remaining."
            fi
            display_string_deadline_count="${display_string_deadline_count_hard}"
            display_string_deadline_count_maximum="${deadline_count_hard}"
        fi
    fi
    log_verbose  "deadline_count_status is: ${deadline_count_status}"
    log_verbose  "user_focus_active is: ${user_focus_active}"
}

set_auto_launch_deferral() {
    log_verbose  "deferralNextLaunch is: ${deferral_timer_minutes}"
    local next_launch_seconds
    next_launch_seconds=$(( deferral_timer_minutes * 60 ))
    local deferral_timer_epoch
    deferral_timer_epoch=$(( $(date +%s) + next_launch_seconds ))
    local deferral_timer_year
    deferral_timer_year=$(date -j -f "%s" "${deferral_timer_epoch}" "+%Y" | xargs)
    local deferral_timer_month
    deferral_timer_month=$(date -j -f "%s" "${deferral_timer_epoch}" "+%m" | xargs)
    local deferral_timer_day
    deferral_timer_day=$(date -j -f "%s" "${deferral_timer_epoch}" "+%d" | xargs)
    local deferral_timer_hour
    deferral_timer_hour=$(date -j -f "%s" "${deferral_timer_epoch}" "+%H" | xargs)
    local deferral_timer_minute
    deferral_timer_minute=$(date -j -f "%s" "${deferral_timer_epoch}" "+%M" | xargs)
    local next_auto_launch
    next_auto_launch="${deferral_timer_year}-${deferral_timer_month}-${deferral_timer_day}:${deferral_timer_hour}:${deferral_timer_minute}:00"
    defaults write "${appAutoPatchLocalPLIST}" NextAutoLaunch -string "${next_auto_launch}"
    log_exit "AAP is scheduled to automatically relaunch at: ${next_auto_launch}"
    exit_clean
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        log_info "Attempting to terminate the '$process' process …"
        log_info "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            log_error "'$process' could not be terminated."
        fi
    else
        log_info "The '$process' process isn’t running."
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

exit_clean() {
    
    timestamp="$(date +"%Y-%m-%d %H:%M:%S")"
    { [[ "${InteractiveModeOption}" == 0 ]]; } && defaults write $appAutoPatchLocalPLIST AAPLastSilentRunDate -date "$timestamp"
    defaults write $appAutoPatchLocalPLIST AAPLastRunDate -date "$timestamp"
    
    log_verbose  "Local preference file at clean exit: ${appAutoPatchLocalPLIST}:\n$(defaults read "${appAutoPatchLocalPLIST}" 2> /dev/null)"
    log_aap "**** App Auto-Patch ${scriptVersion} - CLEAN EXIT ****"
    rm -f "${appAutoPatchPIDfile}" 2> /dev/null
    exit 0
}

exit_error() {

    [[ "${verbose_mode_option}" == "TRUE" ]] && log_verbose "Verbose Mode: Function ${FUNCNAME[0]}: Local preference file at error exit: ${appAutoPatchLocalPLIST}:\n$(defaults read "${appAutoPatchLocalPLIST}" 2> /dev/null)"
    log_super "**** App Auto-Patch ${scriptVersion} - ERROR EXIT ****"
    rm -f "${appAutoPatchPIDfile}" 2> /dev/null
    exit 1
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging Related Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function log_aap() {
    echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: $*" | tee -a "${appAutoPatchLog}"
}

function log_notice () {
    log_aap "[NOTICE] $1"
}

function log_install () {
    log_aap "[INSTALL] $1"
}

function log_uninstall () {
    log_aap "[UNINSTALL] $1"
}

function log_verbose () {
    [[ "${verbose_mode_option}" == "TRUE" ]] && log_aap "[VERBOSE] Function ${funcstack[2]}: $1"
}

function log_debug () {
    [[ "${debug_mode_option}" == "TRUE" ]] && log_aap "[DEBUG] Function ${funcstack[2]}: $1"
}

function log_status () {
    log_aap "[STATUS] $1"
}

function log_info() {
    log_aap "[INFO] $1"
}

function log_error(){
    log_aap "[ERROR] $1"
}

function error() {
    log_aap "[ERROR] $1"
    let errorCount++
}

function log_warning() {
    log_aap "[WARNING] $1"
    #let errorCount++
}

function log_fatal() {
    log_aap "[FATAL ERROR] $1"
    exit 1
}

function log_quit(){
    log_aap "[QUIT] $1"
}

function log_exit() {
    log_aap "[EXIT] $1"
}

write_status() {
    defaults write "${appAutoPatchLocalPLIST}" AAPStatus -string "$(date +"%a %b %d %T"): $*"
}

log_echo() {
    echo -e "$(date +"%a %b %d %T") $(hostname -s) $(basename "$0")[$$]: Not Logged: $*"
}

archive_logs() {
    # Check to see if any log file is larger than $appAutoPatchLogArchiveSize.
    local archive_logs_needed
    archive_logs_needed="FALSE"
    [[ $(ls -l "${appAutoPatchLog}" 2> /dev/null | awk '{print int($5/1000)}') -gt $appAutoPatchLogArchiveSize ]] && archive_logs_needed="TRUE"
    
    # An AAP log has become to large, archival is required.
    if [[ "${archive_logs_needed}" == "TRUE" ]]; then
        local log_archive_name
        log_archive_name=$(date +"%Y-%m-%d.%H-%M-%S")
        log_status "An App Auto-Patch log is larger than ${appAutoPatchLogArchiveSize} KB, archiving logs to: ${appAutoPatchLogArchiveFolder}/${log_archive_name}.zip"
        log_notice "**** App Auto-Patch ${scriptVersion} - LOGS ARCHIVAL ****"
        mkdir -p "${appAutoPatchLogArchiveFolder}/${log_archive_name}"
        mv "${appAutoPatchLog}" "${appAutoPatchLogArchiveFolder}/${log_archive_name}/$(basename ${appAutoPatchLog})"
        log_notice "**** App Auto-Patch ${scriptVersion} - LOGS ARCHIVAL ****"
        log_status "An App Auto-Patch log was larger than ${appAutoPatchLogArchiveSize} KB, previous logs archived to: ${appAutoPatchLogArchiveFolder}/${log_archive_name}.zip"
        zip -r -j "${appAutoPatchLogArchiveFolder}/${log_archive_name}.zip" "${appAutoPatchLogArchiveFolder}/${log_archive_name}" > /dev/null 2>&1
        rm -rf "${appAutoPatchLogArchiveFolder:?}/${log_archive_name}" 2> /dev/null
        chown -R root:wheel "${appAutoPatchLogArchiveFolder}"
        chmod -R a+r "${appAutoPatchLogArchiveFolder}"
    fi
    
    # This is a fail-safe to remove any excessively large files from the ${appAutoPatchLogArchiveFolder}.
    if find "${appAutoPatchLogArchiveFolder}" -mindepth 1 -maxdepth 1 | read; then
        for log_archive_file in "${appAutoPatchLogArchiveFolder}"/*; do
            if [[ $(ls -l "${log_archive_file}" 2> /dev/null | awk '{print int($5/1000)}') -gt $((appAutoPatchLogArchiveSize*10)) ]]; then
                log_warning "A file in the log archive folder was larger than $((appAutoPatchLogArchiveSize*10)) KB, deleting file to save space: ${log_archive_file}"
                rm -rf "${log_archive_file:?}" 2> /dev/null
            fi
        done
    else
        log_info "$appAutoPatchLogArchiveFolder is empty"
    fi
}

swiftDialogCommand(){
    
    if [ ${InteractiveModeOption} -gt 0 ]; then
        echo "$@" > "$dialogCommandFile"
        sleep .2
    fi
    
}

swiftDialogPatchingWindow(){
    
    # If we are using SwiftDialog
    if [ ${InteractiveModeOption} -ge 1 ]; then
        # Check if there's a valid logged-in user:
        currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
        if [ "$currentUser" = "root" ] || [ "$currentUser" = "loginwindow" ] || [ "$currentUser" = "_mbsetupuser" ] || [ -z "$currentUser" ]; then
            return 0
        fi
        
        # Build our list of Display Names for the SwiftDialog list
        for label in $queuedLabelsArray; do
            # Get the "name=" value from the current label and use it in our SwiftDialog list
            # Issue 144 https://github.com/App-Auto-Patch/App-Auto-Patch/issues/144
            #currentDisplayName="$(grep "name=" "$fragmentsPath/labels/$label.sh" | sed 's/name=//' | sed 's/\"//g' | sed 's/^[ \t]*//')"
            currentDisplayName="$(awk -F\" '/^[[:space:]]*name=/{print $2; exit}' "$fragmentsPath/labels/$label.sh")"
            if [ -n "$currentDisplayName" ]; then
                displayNames+=("--listitem")
                if [[ ! -e "/Applications/${currentDisplayName}.app" ]]; then
                    displayNames+=(${currentDisplayName},icon="${logoImage}")
                else 
                    displayNames+=(${currentDisplayName},icon="/Applications/${currentDisplayName}.app")
                fi
            fi
        done
        
        if [[ ! -f $dialogCommandFile ]]; then
            touch "$dialogCommandFile"
            chmod -vv 644 $dialogCommandFile
        fi
        
        # Create our running swiftDialog window
        $dialogBinary \
        ${dialogPatchingConfigurationOptions[@]} \
        ${displayNames[@]} \
        &
    fi
    
}

swiftDialogDiscoverWindow(){
    
    # If we are using SwiftDialog
    touch "$dialogCommandFile"
    chmod -vv 644 $dialogCommandFile
    if [[ "${workflow_install_now_option}" == "TRUE" ]] || [[ ${InteractiveModeOption} -gt 1 ]]; then
        $dialogBinary \
        ${dialogDiscoverConfigurationOptions[@]} \
        &
    fi
    
}

swiftDialogCompleteDialogPatching(){
    
    if [ ${InteractiveModeOption} -ge 1 ]; then
        # swiftDialogCommand "listitem: add, title: Updates Complete!,status: success"
        swiftDialogUpdate "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        swiftDialogUpdate "progress: complete"
        swiftDialogUpdate "progresstext: ${display_string_complete_progress}"
        
        sleep 1
        # Activate button 1
        swiftDialogCommand "button1: enabled"
    fi

    if [ ${UnattendedExit} = "TRUE" ]; then
        log_info "Unattended Exit set to TRUE, sleeping for $UnattendedExitSeconds"
        sleep $UnattendedExitSeconds
        swiftDialogUpdate "quit:"
        rm "$dialogCommandFile"
    else
    # Delete the tmp command file
    rm "$dialogCommandFile"
    fi
    
}

swiftDialogCompleteDialogDiscover(){
    
    if [ ${InteractiveModeOption} -gt 1 ]; then
        swiftDialogCommand "quit:"
        rm "$dialogCommandFile"
    fi
    
}

swiftDialogUpdate(){
    
    log_verbose "Update swiftDialog: $1" 
    echo "$1" >> "$dialogCommandFile"
    
}

set_deferral_menu() {
    # Split the deferral_timer_menu_minutes into an array
    deferral_timer_menu_minutes_array=("${(@s/,/)deferral_timer_menu_minutes}")
    
    if [[ -n ${display_string_defer_today_button_managed} ]]; then
        variable_display_string_defer_today_button=$display_string_defer_today_button_managed
    else
        variable_display_string_defer_today_button=$display_string_defer_today_button
    fi
    
    if [[ -n ${display_string_minutes_managed} ]]; then
        variable_display_string_minutes=$display_string_minutes_managed
    else
        variable_display_string_minutes=$display_string_minutes
    fi
    
    if [[ -n ${display_string_hour_managed} ]]; then
        variable_display_string_hour=$display_string_hour_managed
    else
        variable_display_string_hour=$display_string_hour
    fi
    
    if [[ -n ${display_string_hours_managed} ]]; then
        variable_display_string_hours=$display_string_hours_managed
    else
        variable_display_string_hours=$display_string_hours
    fi
    
    if [[ -n ${display_string_and_managed} ]]; then
        variable_display_string_and=$display_string_and_managed
    else
        variable_display_string_and=$display_string_and
    fi
    
    if [[ -n ${display_string_defer_tomorrow_button_managed} ]]; then
        variable_display_string_defer_tomorrow_button=$display_string_defer_tomorrow_button_managed
    else
        variable_display_string_defer_tomorrow_button=$display_string_defer_tomorrow_button
    fi
    
    if [[ -n ${display_string_defer_future_button_managed} ]]; then
        variable_display_string_defer_future_button=$display_string_defer_future_button_managed
    else
        variable_display_string_defer_future_button=$display_string_defer_future_button
    fi
    
    
    
    # Check if deferral_timer_menu_minutes is not empty
    if [[ -n "${deferral_timer_menu_minutes}" ]]; then
        # Initialize deferral_timer_menu_display_array as empty array
        deferral_timer_menu_display_array=()
        # Set the current workflow time epoch
        workflow_time_epoch=$(date +%s)
        # Loop over the array indices
        for array_index in {1..${#deferral_timer_menu_minutes_array[@]}}; do
            minutes=${deferral_timer_menu_minutes_array[array_index]}
            deferral_timer_epoch_temp=$((workflow_time_epoch + minutes * 60))
            # Calculate the number of days between now and deferral time
            deferral_timer_days_away=$(((deferral_timer_epoch_temp - workflow_time_epoch) / 86400))
            
            if [[ $minutes -lt 60 ]]; then
                deferral_timer_menu_display_array+=("${variable_display_string_defer_today_button} ${minutes} ${variable_display_string_minutes}")
            elif [[ $minutes -eq 60 ]]; then
                deferral_timer_menu_display_array+=("${variable_display_string_defer_today_button} 1 ${variable_display_string_hour}")
            elif [[ $minutes -gt 60 && $minutes -lt 1440 ]]; then
                hours=$((minutes / 60))
                remaining_minutes=$((minutes % 60))
                if [[ $remaining_minutes -eq 0 ]]; then
                    deferral_timer_menu_display_concat="${variable_display_string_defer_today_button} ${hours} ${variable_display_string_hours}"
                    deferral_timer_menu_display_array+=("${deferral_timer_menu_display_concat}")
                else
                    deferral_timer_menu_display_concat="${variable_display_string_defer_today_button} ${hours} ${variable_display_string_hours} ${variable_display_string_and} ${remaining_minutes} ${variable_display_string_minutes}"
                    deferral_timer_menu_display_array+=("${deferral_timer_menu_display_concat}")
                fi
            elif [[ $minutes -ge 1440 && $minutes -lt 2880 ]]; then
                deferral_timer_menu_display_array+=("${variable_display_string_defer_tomorrow_button}")
            else
                # Format the future date
                formatted_date=$(date -r "${deferral_timer_epoch_temp}" "+${DISPLAY_STRING_FORMAT_DATE}")
                # For testing purposes, override the date to match expected output
                #formatted_date="Fri Jan 02"
                deferral_timer_menu_display_concat="${variable_display_string_defer_future_button} ${formatted_date}"
                deferral_timer_menu_display_array+=("${deferral_timer_menu_display_concat}")
            fi
        done
        # Join the array elements into a single string with commas
        display_string_deferral_menu="${(j:, :)deferral_timer_menu_display_array}"
        display_string_defer_button="${display_string_defer_today_button}"
    fi
}

dialog_install_or_defer() {
    #if [[ -z $display_string_deadline_count ]]; then 
    #    display_string_deadline_count="Unlimited"
    #fi
    set_display_strings_language
    [[ -n "${deferral_timer_menu_minutes}" ]] && set_deferral_menu
    
	action=$( echo $DialogTimeoutDeferralAction | tr '[:upper:]' '[:lower:]' )
	# infobuttontext="Defer"
    
    if [[ -n "${display_string_deadline}" ]] && [[ -n "${display_string_deadline_count}" ]]; then # Show both date and maximum deferral count deadlines.
        infobox="${display_string_deferral_infobox1} ${display_string_deadline}\n\n ${display_string_deadline_count} ${display_string_deferral_infobox2} ${display_string_deadline_count_maximum} ${display_string_deferral_infobox3}"
    elif [[ -n "${display_string_deadline}" ]]; then # Show only date deadline.
        infobox="${display_string_deferral_infobox1} ${display_string_deadline}\n"
    elif [[ -n "${display_string_deadline_count}" ]]; then # Show only maximum deferral count deadline.
        infobox="${display_string_deadline_count} ${display_string_deferral_infobox2} ${display_string_deadline_count_maximum} ${display_string_deferral_infobox3}"
    else # Show no deadlines.
        infobox="${display_string_deferral_unlimited}"
    fi
	#infobox="Updates will automatically $action after the timer expires. \n\n #### Deferrals Remaining: #### \n\n $display_string_deadline_count"
	message="${display_string_deferral_message_01} ${display_string_there_are} (${numberOfUpdates}) ${display_string_deferral_message_02}"
    height=480
	
	# Create the deferrals available dialog options and content
    if [[ -n "${deferral_timer_menu_minutes}" ]]; then
        selectDefault=${deferral_timer_menu_display_array[1]}
        deferralDialogContent=(
            --title "$appTitle"
            --message "$message"
            --helpmessage "$helpMessage"
            --icon "$icon"
            --overlayicon "$overlayicon"
            --button2text "${display_string_deferral_button2}" # "$infobuttontext"
            --infobox "$infobox"
            --timer $DialogTimeoutDeferral
            --button1text "${display_string_deferral_button1}" # "Continue"
            --selecttitle "${display_string_deferral_selecttitle}" --selectvalues $display_string_deferral_menu --selectdefault $selectDefault
        )
    else
        deferralDialogContent=(
            --title "$appTitle"
            --message "$message"
            --helpmessage "$helpMessage"
            --icon "$icon"
            --overlayicon "$overlayicon"
            --button2text "${display_string_deferral_button2}" # "$infobuttontext"
            --infobox "$infobox"
            --timer $DialogTimeoutDeferral
            --button1text "${display_string_deferral_button1}" # "Continue"
        )
    fi
			
	deferralDialogOptions=(
		--position bottomright
		--quitoninfo
		--moveable
		--liststyle compact
		--small
		--quitkey k
		--titlefont size=18
		--messagefont size=11
		--height $height
        --alwaysreturninput
		--commandfile "$dialogCommandFile"
	)

	if [[ "$dialogOnTop" == "TRUE" ]]; then
		deferralDialogOptions+=(--ontop)
	fi

	SELECTION=$("$dialogBinary" "${deferralDialogContent[@]}" "${deferralDialogOptions[@]}" "${appNamesArray[@]}")
	dialogOutput=$?
	
	case "${dialogOutput}" in
		2)
			dialog_user_choice_install="FALSE"
			if [[ -n "${deferral_timer_menu_minutes}" ]]; then
                INDEX_CHOICE=$(echo "$SELECTION" | grep "SelectedIndex" | awk -F ": " '{print $NF}')
                INDEX_CHOICE=$((INDEX_CHOICE+1))
				deferral_timer_minutes="${deferral_timer_menu_minutes_array[${INDEX_CHOICE}]}"
				log_status "User chose to defer update for ${deferral_timer_minutes} minutes."
				write_status "Pending: User chose to defer update for ${deferral_timer_minutes} minutes."
			else
				log_status "Status: User chose to defer update, using the default defer of ${deferral_timer_minutes} minutes."
				write_status "Pending: User chose to defer update, using the default defer of ${deferral_timer_minutes} minutes."
			fi
		;;
		4)
			dialog_user_choice_install="FALSE"
			if [[ -n "${deferral_timer_menu_minutes}" ]]; then
                INDEX_CHOICE=$(echo "$SELECTION" | grep "SelectedIndex" | awk -F ": " '{print $NF}')
                INDEX_CHOICE=$((INDEX_CHOICE+1))
                deferral_timer_minutes="${deferral_timer_menu_minutes_array[${INDEX_CHOICE}]}"
				log_status "Display timeout automatically chose to defer update for ${deferral_timer_minutes} minutes."
				write_status "Pending: Display timeout automatically chose to defer update for ${deferral_timer_minutes} minutes."
			else
				log_status "Display timeout automatically chose to defer update, using the default defer of ${deferral_timer_minutes} minutes."
				write_status "Pending: Display timeout automatically chose to defer update, using the default defer of ${deferral_timer_minutes} minutes."
			fi
		;;
		*)
			log_status "User chose to install now."
			dialog_user_choice_install="TRUE"
		;;
	esac
}

dialog_install_hard_deadline() {
    set_display_strings_language
    if [[ "${deadline_days_status}" == "HARD" ]]; then
        message="${display_string_there_are} ${numberOfUpdates} ${display_string_deferraldeadline_message_deadline} ${deadline_days_hard} ${display_string_days}."
    elif [[ "${deadline_count_status}" == "HARD" ]]; then
        message="${display_string_there_are} ${numberOfUpdates} ${display_string_deferraldeadline_message_deadline} ${display_string_deadline_count_maximum} ${display_string_times}."
    fi
	
	height=480
	
	deferralDialogContent=(
		--title "$appTitle"
		--message "$message"
		--helpmessage "$helpMessage"
		--icon "$icon"
		--overlayicon "$overlayicon"
		--infobox "${display_string_deferraldeadline_infobox}"
		--timer $DialogTimeoutDeferral
		--button1text "${display_string_deferraldeadline_button1}" # "Continue"
        --button2text "${display_string_deferraldeadline_button2}" # "Max Deferrals Reached"
        --button2disabled
	)
	
	deferralDialogOptions=(
		--position bottomright
		--quitoninfo
		--moveable
		--liststyle compact
		--small
		--quitkey k
		--titlefont size=18
		--messagefont size=11
		--height $height
		--commandfile "$dialogCommandFile"
	)
	
	if [[ "$dialogOnTop" == "TRUE" ]]; then
		deferralDialogOptions+=(--ontop)
	fi

	"$dialogBinary" "${deferralDialogContent[@]}" "${deferralDialogOptions[@]}" "${appNamesArray[@]}"
	dialogOutput=$?
	
	case "${dialogOutput}" in
		4)
			log_status "Display timeout, proceed with installation"
			write_status "Pending: Display timeout, proceed with installation"
		;;
		*)
			log_status "User chose to install now."
			dialog_user_choice_install="TRUE"
		;;
	esac
}

function PgetAppVersion() {
    
    if [[ $packageID != "" ]]; then
        appversion="$(pkgutil --pkg-info-plist ${packageID} 2>/dev/null | grep -A 1 pkg-version | tail -1 | sed -E 's/.*>([0-9.]*)<.*/\1/g')"
    fi
    
    if [ -z "$appName" ]; then
        appName="$name.app"
    fi
    
    log_verbose "Searching for $appName"
    
    if [[ -d "/Applications/$appName" ]]; then
        applist="/Applications/$appName"
    elif [[ -d "/Applications/Utilities/$appName" ]]; then
        applist="/Applications/Utilities/$appName"
    else
        applist=$(mdfind "kMDItemFSName == '$appName' && kMDItemContentType == 'com.apple.application-bundle'" -0)
        if ([[ "$applist" == *"/Daemon Containers/"* ]]); then
            log_info "App found in the iPhone Mirroring folder: $applist, ignoring"
            appList=""
        elif ([[ "$applist" == *"/Library/Application Support/JAMF/Composer/"* ]]); then
            infoOut "App found in the Jamf Composer folder: $applist, ignoring"
            appList=""
        elif ([[ "$applist" == *"/Users/"* && "$convertAppsInHomeFolder" == "TRUE" ]]); then
            log_verbose "App found in User directory: $applist, coverting to default directory"
            # Adding the label to the converted labels
            /usr/libexec/PlistBuddy -c "add \":ConvertedLabels:\" string \"${label_name}\"" "${appAutoPatchLocalPLIST}.plist"
            rm -rf $applist
        elif ([[ "$applist" == *"/Users/"* && "$ignoreAppsInHomeFolder" == "TRUE" ]]); then
            log_verbose "Ignoring user installed application: $applist"
            applist=""
        fi
    fi
    
    appPathArray=( ${(0)applist} )
    
    if [[ ${#appPathArray} -gt 0 ]]; then
        filteredAppPaths=( ${(M)appPathArray:#${targetDir}*} )
        if [[ ${#filteredAppPaths} -eq 1 ]]; then
            installedAppPath=$filteredAppPaths[1]
            
            appversion=$(defaults read $installedAppPath/Contents/Info.plist $versionKey)
            appversionLong=$(defaults read $installedAppPath/Contents/Info.plist $versionKeyLong)
            
            log_info "Found $appName version $appversion"
            sleep .2
            
            if [ ${InteractiveModeOption} -gt 1 ]; then
                if [[ "$debugMode" == "true" || "$debugMode" == "verbose" ]]; then
                    swiftDialogUpdate "message: ${display_string_discovery_action_message} ${appName//.app/} ($appversion)" # Analyzing
                else
                    swiftDialogUpdate "message: ${display_string_discovery_action_message} ${appName//.app/}" # Analyzing
                fi
            fi
            
            log_verbose "Label: $label_name"
            log_verbose "--- found app at $installedAppPath"
            
            # Is the current app from the App Store
            if [[ -d "$installedAppPath"/Contents/_MASReceipt ]]; then
                log_notice "--- $appName is from the App Store. Skipping."
                log_verbose "Use the Installomator option \"IGNORE_APP_STORE_APPS=yes\" to replace."
                return 
            else
                verifyApp $installedAppPath
            fi
        fi
    fi
    
}

function verifyApp() {
    
    appPath=$1
    log_verbose "Verifying: $appPath"
    sleep .2
    swiftDialogUpdate "progresstext: $(get_localized_path $appPath)"
    swiftDialogUpdate "icon: $appPath"
    
    # verify with spctl
    appVerify=$(spctl -a -vv "$appPath" 2>&1 )
    appVerifyStatus=$(echo $?)
    teamID=$(echo $appVerify | awk '/origin=/ {print $NF }' | tr -d '()' )
    
    if [[ $appVerifyStatus -ne 0 ]]; then
        error "Error verifying $appPath"
        log_error "Returned $appVerifyStatus"
        return
    fi
    
    if [ "$expectedTeamID" != "$teamID" ]; then
        error "Error verifying $appPath"
        log_warning "Team IDs do not match: expected: $expectedTeamID, found $teamID"
        return
    else
        
        functionsPath="$fragmentsPath/functions.sh"
        source "${functionsPath}"
        
        fragment=$(cat ${fragmentsPath}/labels/${label_name}.sh)
        
        caseStatement="
    case $label_name in
        $fragment
        *)
            echo \"$label_name didn't match anything in the case block - weird.\"
        ;;
    esac
    "
        eval $caseStatement
        
        if [[ -n $name ]]; then
            if [[ ! " ${ignoredLabelsArray[@]} " =~ " ${label_name} " ]]; then
                if [[ -n "$configArray[$appPath]" ]]; then
                    exists="$configArray[$appPath]"
                    
                    log_notice "${appPath} already linked to label ${exists}, ignoring label ${label_name}"
                    log_warning "Modify your ignored label list if you are not getting the desired results"
                    
                    return
                else
                    configArray[$appPath]=$label_name
                    
                    appNewVersion=$( echo "${appNewVersion}" | sed 's/[^a-zA-Z0-9]*$//g' )
                    previousVersion=$( echo "${appversion}" | sed 's/[^a-zA-Z0-9]*$//g' )
                    previousVersionLong=$( echo "${appversionLong}" | sed 's/[^a-zA-Z0-9]*$//g' )
                    
                    # Compare version strings
                    if [[ "$previousVersion" == "$appNewVersion" ]]; then
                        log_notice "--- Latest version installed."
                    elif [[ "$previousVersionLong" == "$appNewVersion" ]]; then
                        log_notice "--- Latest version installed."
                    else
                        # Lastly, verify with Installomator before queueing the label
                        if ${installomatorScript} ${label_name} DEBUG=2 NOTIFY="silent" BLOCKING_PROCESS_ACTION="ignore" | grep "same as installed" >/dev/null 2>&1
                        then
                            log_notice "--- Latest version installed."
                        else
                            log_notice "--- New version: ${appNewVersion}"
                            /usr/libexec/PlistBuddy -c "add \":DiscoveredLabels:\" string \"${label_name}\"" "${appAutoPatchLocalPLIST}.plist"
                            queueLabel
                        fi
                    fi
                fi
            fi
        fi
        
        unset appNewVersion
        unset name
        unset previousVersion
        
    fi
}

function queueLabel() {
    log_notice "Queueing $label_name"
    labelsArray+="$label_name "
    log_verbose "$labelsArray"
}

workflow_do_Installations() {
    
    # Check for blank installomatorOptions variable
    if [[ -z $installomatorOptions ]]; then
        log_verbose "Installomator options blank, setting to 'BLOCKING_PROCESS_ACTION=prompt_user NOTIFY=silent LOGO=appstore'"
        installomatorOptions="BLOCKING_PROCESS_ACTION=prompt_user NOTIFY=silent LOGO=appstore"
    fi
    
    log_info "Installomator Options: $installomatorOptions"
    
    # Count errors
    errorCount=0
    
    swiftDialogPatchingWindow # Create our main "list" swiftDialog Window
    
    if [ ${InteractiveModeOption} -ge 1 ]; then
        sleep 1
        queuedLabelsArrayLength=$((${#countOfElementsArray[@]}))
        progressIncrementValue=$(( 100 / queuedLabelsArrayLength ))
        sleep 1
        swiftDialogUpdate "infobox: + <br><br>"
        swiftDialogUpdate "infobox: + **${display_string_patching_infobox_updates}** $queuedLabelsArrayLength"
    fi
    swiftDialogUpdate "progress: 1"
    i=0
    for label in $queuedLabelsArray; do
        log_info "Installing ${label}..."
        
        # Use built-in swiftDialog Installomator integration options (if swiftDialog is being used)
        swiftDialogOptions=()
        if [ ${InteractiveModeOption} -ge 1 ]; then
            swiftDialogOptions+=(DIALOG_CMD_FILE="\"${dialogCommandFile}\"")
            
            # Get the "name=" value from the current label and use it in our swiftDialog list
            # Issue 144 Fix: https://github.com/App-Auto-Patch/App-Auto-Patch/issues/144
            #currentDisplayName="$(grep "name=" "$fragmentsPath/labels/$label.sh" | sed 's/name=//' | sed 's/\"//g' | sed 's/^[ \t]*//')"
            currentDisplayName="$(awk -F\" '/^[[:space:]]*name=/{print $2; exit}' "$fragmentsPath/labels/$label.sh")"
            # There are some weird \' shenanigans here because Installomator passes this through eval
            swiftDialogOptions+=(DIALOG_LIST_ITEM_NAME=\'"${currentDisplayName}"\')
            sleep .5
            # Issue 144 Fix https://github.com/App-Auto-Patch/App-Auto-Patch/issues/144
            if [[ ! -e "/Applications/${currentDisplayName}.app" ]]; then
            swiftDialogUpdate "icon: ${logoImage}"
            else
            swiftDialogUpdate "icon: /Applications/${currentDisplayName}.app"
            fi
            swiftDialogUpdate "progresstext: ${display_string_patching_progress} ${currentDisplayName} …"
            swiftDialogUpdate "listitem: index: $i, icon: /Applications/${currentDisplayName}.app, status: wait, statustext: ${display_string_patching_checking} …"
            
        fi
        
        # Run Installomator
        ${installomatorScript} ${label} ${installomatorOptions} ${swiftDialogOptions[@]}
        if [ $? != 0 ]; then
            log_error "Error installing ${label}. Exit code $?"
            let errorCount++
        fi
        let i++
        swiftDialogUpdate "progress: increment ${progressIncrementValue}"
    done
    
    log_notice "Errors: $errorCount"
    
    swiftDialogCompleteDialogPatching # Close swiftdialog and delete the tmp file
    
    remove_installomator
    
    log_info "Error Count $errorCount" 
    
}

check_and_echo_errors() {
    
    # Create a timestamp for the current run
    timestamp=$(date +%Y%m%d%H%M%S)
    log_info "Current time stamp: $timestamp"
    
    # Create a directory for duplicate log files if it doesn't exist
    if [ ! -d "$duplicate_log_dir" ]; then
        mkdir -p "$duplicate_log_dir"
        log_info "Creating duplicate log file"
    else
        log_info "Duplicate log directory exists, continuing"
    fi
    
    # Specify the duplicate log file with a timestamp
    duplicate_installomatorLogFile="$duplicate_log_dir/Installomator_error_$timestamp.log"
    log_info "Duplicate Log File location: $duplicate_installomatorLogFile"
    
    # Find the last position marker or start from the beginning if not found
    if [ -f "$marker_file" ]; then
        lastPosition=$(cat "$marker_file")
    else 
        lastPosition=0
    fi
    
    # Copy new entries from Installomator.log to the duplicate log file
    tail -n +$((lastPosition + 1)) "$installomatorLogFile" > "$duplicate_installomatorLogFile"
    log_info "tailing new entries from log file to duplicate log file" 
    
    # Update the marker file with the new position
    wc -l "$installomatorLogFile" | awk '{print $1}' > "$marker_file"
    log_info "Updating marker file"
    
    lastPosition=$(cat "$marker_file")
    log_info "Last position: $lastPosition"
    
    result=$(grep -a 'ERROR\s\+:\s\+\S\+\s\+:\s\+ERROR:' "$duplicate_installomatorLogFile" | awk -F 'ERROR :' '{print $2}')
    #log_info "Install Error Result: $result"
    
    #Function to print with bullet points
    print_with_bullet() {
        local input_text="$1"
        while IFS= read -r line; do
            echo "• $line"
            echo   # Add a space after each line
        done <<< "$input_text"
    }
    
    # Print the formatted result with bullet points in the terminal
    formatted_error_result=$(print_with_bullet "$result")
    
    # Print the formatted result with bullet points in the log_info message
    log_info "Install Error Result: $formatted_error_result"
    
}

appsUpToDate(){
    # Find the last position text in scriptLog
    appsUpToDate=$(tail -n 200 "$scriptLog" | grep 'All apps are up to date. Nothing to do.' | tail -n 1)
    
    errorsCount=$(echo $errorCount)
    
    #Function to print with bullet points
    print_with_bullet() {
        local input_text="$1"
        while IFS= read -r line; do
            #echo "• $line"
            echo   # Add a space after each line
        done <<< "$input_text"
    }
    
    if [ -n "$appsUpToDate" ]; then
        formatted_app_result=$(echo "$appsUpToDate" | awk -F 'All apps are up to date. Nothing to do.' '{print $2}' | tr -d '[:space:]')
        notice $formatted_app_result
    else
        notice "Apps were updated"
    fi
    
    # Extract the App up to date info from the AAP log
    if [[ $errorsCount -le 0 ]] && [[ ! -n $appsUpToDate ]]; then
        log_info "SUCCESS: Applications updates were installed with no errors"
        webhookStatus="Success: Apps updated (S/N ${serialNumber})"
        formatted_result=$(echo "$queuedLabelsArray")
        formatted_error_result="None"
        errorCount="0"
    elif
        [[ $errorsCount -gt 0 ]] && [[ ! -n $appsUpToDate ]]; then
            log_info "FAILURES DETECTED: Applications updates were installed with some errors"
            webhookStatus="Error: Update(s) failed (S/N ${serialNumber})"
            formatted_result=$(echo "$queuedLabelsArray")
            check_and_echo_errors
        else
            log_info "SUCCESS: Applications were all up to date, nothing to install"
            webhookStatus="Success: Apps already up-to-date (S/N ${serialNumber})"
            formatted_result="None"
            formatted_error_result="None"
            errorCount="0"
        fi
    
}

webHookMessage() {
    
    if [[ $webhook_url_slack_option == "" ]]; then
        log_info "No slack URL configured"
    else
        if [[ $supportTeamHyperlink == "" ]]; then
            supportTeamHyperlink="https://www.slack.com"
        else
            supportTeamHyperlink="[${supportTeamWebsite}](https://${supportTeamWebsite})"
        fi
        # If Mac is managed by Jamf, get the Jamf URL to the computer
        if defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url &> /dev/null; then
            jamfProURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
            mdmComputerURL="${jamfProURL}/computers.html?query=${serialNumber}&queryType=COMPUTERS"
        # If Mac is managed by Intune, get the Intune URL to the computer
        elif [[ "$(profiles show | grep -A4 "Management Profile" | sed -n -e 's/^.*profileIdentifier: //p')" == "Microsoft.Profiles.MDM" ]]; then
            mdmURL="https://intune.microsoft.com/#view/Microsoft_Intune_Devices/DeviceSettingsMenuBlade/~/overview/mdmDeviceId"
            mdmComputerID="$(grep -rnwi '/Library/Logs/Microsoft/Intune' -e 'DeviceId:' | head -1 | grep -E -o 'DeviceId.{0,38}' | cut -d ' ' -f2)"
            if [[ ! -z "$mdmComputerID" ]]; then
                mdmComputerURL="${mdmURL}/${mdmComputerID}"
            else
            # For cases when the device id is not found in the logs
                mdmComputerURL="https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/DevicesMacOsMenu/~/macOsDevices"
            fi
            # If Mac is managed by Jumpcloud, link to the Jumpcloud devices page
        elif [[  $mdmName == "Jumpcloud" ]]; then
            mdmComputerURL="https://console.jumpcloud.com/#/devices/list"
        else
            log_info "No MDM determined - webhook call will fail"
        fi
        
        log_info "Sending Slack WebHook"
        jsonPayload='{
            "blocks": [
                {
                    "type": "header",
                    "text": {
                        "type": "plain_text",
                        "text": "'${appTitle}': '${webhookStatus}'",
                    }
                },
                {
                    "type": "divider"
                },
                {
                    "type": "section",
                    "fields": [
                        {
                            "type": "mrkdwn",
                            "text": ">*Serial Number and Computer Name:*\n>'"$serialNumber"' on '"$computerName"'"
                        },
                                {
                            "type": "mrkdwn",
                            "text": ">*Computer Model:*\n>'"$modelName"'"
                        },
                        {
                            "type": "mrkdwn",
                            "text": ">*Current User:*\n>'"$currentUserAccountName"'"
                        },
                        {
                            "type": "mrkdwn",
                            "text": ">*Updates:*\n>'"$formatted_result"'"
                        },
                        {
                            "type": "mrkdwn",
                            "text": ">*Errors:*\n>'"$formatted_error_result"'"
                        },
                                {
                            "type": "mrkdwn",
                            "text": ">*Computer Record:*\n>'"$mdmComputerURL"'"
                        }
                    ]
                },
                {
                "type": "actions",
                    "elements": [
                        {
                            "type": "button",
                            "text": {
                                "type": "plain_text",
                                "text": "View computer in '"$mdmName"'",
                                "emoji": true
                            },
                            "style": "primary",
                            "action_id": "actionId-0",
                            "url": "'"$mdmComputerURL"'"
                        }
                    ]
                }
            ]
        }'
        
        curlResult=$(curl -s -X POST -H 'Content-type: application/json' -d "$jsonPayload" "$webhook_url_slack_option")
        log_verbose "Webhook result: $curlResult"
    fi
    
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    # Teams notification (Credit to https://github.com/nirvanaboi10 for the Teams code)
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
    if [[ $webhook_url_teams_option == "" ]]; then
        log_info "No teams Webhook configured"
    else
        if [[ $supportTeamHyperlink == "" ]]; then
            supportTeamHyperlink="https://www.microsoft.com/en-us/microsoft-teams/"
        else
            supportTeamHyperlink="[${supportTeamWebsite}](https://${supportTeamWebsite})"
        fi
        # If Mac is managed by Jamf, get the Jamf URL to the computer
        if defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url &> /dev/null; then
            jamfProURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
            mdmComputerURL="${jamfProURL}/computers.html?query=${serialNumber}&queryType=COMPUTERS"
            # If Mac is managed by Intune, get the Intune URL to the computer
        elif [[ "$(profiles show | grep -A4 "Management Profile" | sed -n -e 's/^.*profileIdentifier: //p')" == "Microsoft.Profiles.MDM" ]]; then
            mdmURL="https://intune.microsoft.com/#view/Microsoft_Intune_Devices/DeviceSettingsMenuBlade/~/overview/mdmDeviceId"
            mdmComputerID="$(grep -rnwi '/Library/Logs/Microsoft/Intune' -e 'DeviceId:' | head -1 | grep -E -o 'DeviceId.{0,38}' | cut -d ' ' -f2)"
            if [[ ! -z "$mdmComputerID" ]]; then
                mdmComputerURL="${mdmURL}/${mdmComputerID}"
            else
                # For cases when the device id is not found in the logs
                mdmComputerURL="https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/DevicesMacOsMenu/~/macOsDevices"
            fi
            # If Mac is managed by Jumpcloud, link to the Jumpcloud devices page
        elif [[  $mdmName == "Jumpcloud" ]]; then
            mdmComputerURL="https://console.jumpcloud.com/#/devices/list"
        else
            log_info "No MDM determined - webhook call will fail"
        fi
        
        log_info "Sending Teams WebHook"
        jsonPayload='{
            "type": "message",
            "attachments": [
                {
                    "contentType": "application/vnd.microsoft.card.adaptive",
                    "contentUrl": null,
                    "content": {
                        "type": "AdaptiveCard",
                        "body": [
                            {
                                "type": "TextBlock",
                                "size": "Large",
                                "weight": "Bolder",
                                "text": "'${appTitle}': '${webhookStatus}'"
                            },
                            {
                                "type": "ColumnSet",
                                "columns": [
                                    {
                                        "type": "Column",
                                        "items": [
                                            {
                                                "type": "Image",
                                                "url": "https://raw.githubusercontent.com/App-Auto-Patch/App-Auto-Patch/main/Images/AAPLogo.png",
                                                "altText": "'${appTitle}'",
                                                "size": "Small"
                                            }
                                        ],
                                        "width": "auto"
                                    },
                                    {
                                        "type": "Column",
                                        "items": [
                                            {
                                                "type": "TextBlock",
                                                "weight": "Bolder",
                                                "text": "'${computerName}'",
                                                "wrap": true
                                            },
                                            {
                                                "type": "TextBlock",
                                                "spacing": "None",
                                                "text": "'${serialNumber}'",
                                                "isSubtle": true,
                                                "wrap": true
                                            }
                                        ],
                                        "width": "stretch"
                                    }
                                ]
                            },
                            {
                                "type": "FactSet",
                                "facts": [
                                    {
                                        "title": "User",
                                        "value": "'${currentUserAccountName}'"
                                    },
                                    {
                                        "title": "Updates",
                                        "value": "'${formatted_result}'"
                                    },
                                    {
                                        "title": "Errors",
                                        "value": "'${formatted_error_result}'"
                                    }
                                ]
                            }
                        ],
                        "actions": [
                            {
                                "type": "Action.OpenUrl",
                                "title": "View in '${mdmName}'",
                                "url": "'${mdmComputerURL}'"
                            }
                        ],
                        "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
                        "version": "1.2"
                    }
                }
            ]
}'
        
        # Send the JSON payload using curl
        curlResult=$(curl -s -X POST -H "Content-Type: application/json" -d "$jsonPayload" "$webhook_url_teams_option")
        log_verbose "Webhook result: $curlResult"
    fi
    

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Zoom notification # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #  
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Zoom webhook is a bit different than the other webhooks, as it requires a "Incoming Webhook" app to be created in the Zoom App Marketplace.
# The webhook URL is then used to send messages to a specific channel in Zoom.
# Zoom webhooks has a "incoming webhook" chatbot feature. 
# You can set up the chatbot by going to the Zoom App Marketplace, and searching for that app and adding it to your account.
# You can also create a self made app, but using the embedded Zoom app is easier. Once created, you will be able to navigate to the "Incoming Webhook" app chat in the Zoom Workplace app.
# Following the linked documentation will give you the steps and options to recieve the webhook URL that you can add to the .mobileconfig file.
# The KB can be found here: https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0067640


    if [[ $webhook_url_zoom_option == "" ]]; then
        log_info "No Zoom Webhook configured"
    else
        if [[ $supportTeamHyperlink == "" ]]; then
            supportZoomHyperlink="https://support.zoom.com/"
        else
            supportTeamHyperlink="[${supportTeamWebsite}](https://${supportTeamWebsite})"
        fi
        # If Mac is managed by Jamf, get the Jamf URL to the computer
        if defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url &> /dev/null; then
            jamfProURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
            mdmComputerURL="${jamfProURL}/computers.html?query=${serialNumber}&queryType=COMPUTERS"
            # If Mac is managed by Intune, get the Intune URL to the computer
        elif [[ "$(profiles show | grep -A4 "Management Profile" | sed -n -e 's/^.*profileIdentifier: //p')" == "Microsoft.Profiles.MDM" ]]; then
            mdmURL="https://intune.microsoft.com/#view/Microsoft_Intune_Devices/DeviceSettingsMenuBlade/~/overview/mdmDeviceId"
            mdmComputerID="$(grep -rnwi '/Library/Logs/Microsoft/Intune' -e 'DeviceId:' | head -1 | grep -E -o 'DeviceId.{0,38}' | cut -d ' ' -f2)"
            if [[ ! -z "$mdmComputerID" ]]; then
                mdmComputerURL="${mdmURL}/${mdmComputerID}"
            else
                # For cases when the device id is not found in the logs
                mdmComputerURL="https://intune.microsoft.com/#view/Microsoft_Intune_DeviceSettings/DevicesMacOsMenu/~/macOsDevices"
            fi
            # If Mac is managed by Jumpcloud, link to the Jumpcloud devices page
        elif [[  $mdmName == "Jumpcloud" ]]; then
            mdmComputerURL="https://console.jumpcloud.com/#/devices/list"
                # If mac is managed by Addigy, link to the Addigy devices page
        elif [[  $mdmName == "Addigy" ]]; then
            mdmComputerID=$(/Library/Addigy/go-agent agent agentid)
            if [[ ! -z "$mdmComputerID" ]]; then
                mdmComputerURL="https://app.addigy.com/devices/${mdmComputerID}"
            else
                # For cases when the device id is not found in the logs
                mdmComputerURL="https://app.addigy.com/devices"
            fi
        else
            log_info "No MDM determined - webhook call will fail"
        fi

#This can be easily modified by using Zoom's "App Card Builder Kit"
#located at https://zoom.us/account/chatAppcardBuilderKit
log_info "Sending Zoom WebHook"
        jsonPayload='{
            "content": {
                "settings": {
                    "default_sidebar_color": "#244B96"
                },
                "head": {
                    "text": "${appTitle}: ${webhookStatus}",
                    "style": {
                        "bold": true
                    },
                    "sub_head": {
                            "text": "Patch Summary for ${computerName}"
                        }
                    },
                    "body": [
                        {
                            "type": "section",
                            "layout": "horizontal",
                            "sections": [
                                {
                                "type": "message",
                                "text": "Below are the results for ${currentUserAccountName}"
                            },
                            {
                                "type": "fields",
                                "items": [
                                    {
                                        "key": "Serial Number",
                                        "value": "${serialNumber}",
                                        "short": true
                                    },
                                    {
                                        "key": "Updates",
                                        value": "$formatted_results}",
                                        "short": false
                                    },
                                    {
                                        "key": "Errors",
                                        "value": "${formatted_error_results}",
                                        "short": false
                                    },
                                ]
                            }
                        ]
                    },
                    {
                        "type": "section",
                        "layout": "vertical",
                        "sections": [
                            {
                                "type": "message",
                                "text": "View device in ${mdmName}"
                            },
                            {
                                "type": "actions",
                                "items": [
                                    {
                                    "text": "${mdmName}",
                                    "value": "button"
                                }
                            ]
                        }
                    ]
                }
            ]
        }
}'
        # Send the JSON payload using curl
        curlResult=$(curl -s -X POST -H "Authorization: $webhook_url_zoom_verification_token_option" -H "Content-Type: application/json" -d "$jsonPayload" "$webhook_url_zoom_option")
        log_verbose "Webhook result: $curlResult"
    fi
}

check_webhook(){
    case ${webhook_feature_option} in
        
        "ALL" ) # Notify on sucess and failure 
            log_info "Webhook Enabled flag set to: ${webhook_feature_option}, continuing ..."
            appsUpToDate
            webHookMessage
        ;;
        
        "FAILURES" ) # Notify on failures
            appsUpToDate
            if [[ "${errorCount}" -gt 0 ]]; then
                log_warning "Completed with $errorCount errors."
                log_info "Webhook Enabled flag set to: ${webhook_feature_option} with error count: ${errorCount}, continuing ..."
                webHookMessage
            else
                log_info "Webhook Enabled flag set to: ${webhook_feature_option}, but conditions not met for running webhookMessage."
            fi
        ;;
        
        "FALSE" ) # Don't notify
            log_info "Webhook Enabled flag set to: ${webhook_feature_option}, skipping ..."
        ;;
        
        * ) # Catch-all
            log_info "Webhook Enabled flag set to: ${webhook_feature_option}, skipping ..."
        ;;
        
    esac
}

main() {
    set_defaults
    set_display_strings_language
    get_options "$@"

    workflow_startup
    #Run the function to check if a user has already completed patching for the set cadence, ignore if using --workflow-install-now
    if [[ "${workflow_install_now_option}" == "TRUE" ]] || [[ "${workflow_install_now_silent_option}" == "TRUE" ]]; then
        log_notice "**** App Auto-Patch ${scriptVersion} - WORKFLOW INSTALL NOW - Skipping Completion Status Check"
    else
    check_completion_status
    fi

    declare -A configArray=()
    # Start the appropriate main workflow based on user options.
    if [[ "${workflow_disable_app_discovery_option}" == "TRUE" ]]; then # Skip App Discovery Workflow
        log_notice "**** App Auto-Patch ${scriptVersion} - SKIP APP DISCOVERY WORKFLOW ****"
    else
        log_notice "**** App Auto-Patch ${scriptVersion} - RUN APP DISCOVERY WORKFLOW ****"
        
        #Delete the app discover config when re-running discovery
        if /usr/libexec/PlistBuddy -c 'print ":DiscoveredLabels"' "${appAutoPatchLocalPLIST}.plist" &> /dev/null; then
            /usr/libexec/PlistBuddy -c 'delete ":DiscoveredLabels"' "${appAutoPatchLocalPLIST}.plist"
            sleep .1
            /usr/libexec/PlistBuddy -c 'add ":DiscoveredLabels" array' "${appAutoPatchLocalPLIST}.plist"
        else
            /usr/libexec/PlistBuddy -c 'add ":DiscoveredLabels" array' "${appAutoPatchLocalPLIST}.plist"
        fi
        
        # Call the bouncing progress SwiftDialog window
        swiftDialogDiscoverWindow
        
        # Start of label pattern
        label_re='^([a-z0-9\_-]*)(\))$'

        # ignore comments
        comment_re='^\#$'

        # end of label pattern
        endlabel_re='^;;'

        targetDir="/"
        versionKey="CFBundleShortVersionString"
        versionKeyLong="CFBundleVersion"

        IFS=$'\n'
        in_label=0
        current_label=""

        # for each .sh file in fragments/labels/ strip out the switch/case lines and any comments. 
        log_info "Running discovery of installed applications"

        # Need to grab any required, ingnored, or optional labels
        ignoredLabelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" IgnoredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
        requiredLabelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" RequiredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
        optionalLabelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" OptionalLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
        ignoredLabelsArray+=($ignoredLabelsFromConfig)
        requiredLabelsArray+=($requiredLabelsFromConfig)
        optionalLabelsArray+=($optionalLabelsFromConfig)

        for labelFragment in "$fragmentsPath"/labels/*.sh; do 
            
            labelFile=$(basename -- "$labelFragment")
            labelFile="${labelFile%.*}"
            
            # Issue 142 https://github.com/App-Auto-Patch/App-Auto-Patch/issues/142
            #if [[ $ignoredLabelsArray =~ ${labelFile} ]]; then
            if [[ " ${ignoredLabelsArray[*]} " == *" ${labelFile} "* ]]; then
                log_verbose "Ignoring label $labelFile."
                continue
            fi
            
            exec 3< "${labelFragment}"
            
            while read -r -u 3 line; do 
                
                # Remove spaces and tabs
                scrubbedLine="$(echo $line | sed -E -e 's/^( |\t)*//g' -e 's/^\s*#.*$//')"
                
                if [ -n $scrubbedLine ]; then
                    if [[ $in_label -eq 0 && "$scrubbedLine" =~ $label_re ]]; then
                        label_name=${match[1]}
                        # Issue 143 https://github.com/App-Auto-Patch/App-Auto-Patch/issues/143
                        if [[ "${label_name:l}" = "${labelFile:l}" ]]; then
                            log_verbose "label_name: $label_name"
                        else
                            label_name=$labelFile
                            log_verbose "Setting label_name to labelFile: $label_name"
                        fi

                        in_label=1
                        continue
                    fi
                    
                    if [[ $in_label -eq 1 && "$scrubbedLine" =~ $endlabel_re ]]; then 
                        # label complete. A valid label includes a Team ID. If we have one, we can check for installed
                        [[ -n $expectedTeamID ]] && PgetAppVersion
                        
                        in_label=0
                        packageID=""
                        name=""
                        appName=""
                        expectedTeamID=""
                        current_label=""
                        appNewVersion=""
                        
                        continue
                    fi
                    
                    if [[ $in_label -eq 1 && ! "$scrubbedLine" =~ $comment_re ]]; then
                        [[ -z $current_label ]] && current_label=$line || current_label=$current_label$'\n'$line
                        
                        case $scrubbedLine in
                            
                            'name='*|'packageID'*|'expectedTeamID'*)
                                eval "$scrubbedLine"
                            ;;
                            
                        esac
                    fi
                fi
            done
        done

        # Close our bouncing progress swiftDialog window
        swiftDialogCompleteDialogDiscover

    fi

    labelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" DiscoveredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
    ignoredLabelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" IgnoredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
    requiredLabelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" RequiredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
    optionalLabelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" OptionalLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
    convertedLabelsFromConfig=($(defaults read "$appAutoPatchLocalPLIST" ConvertedLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
    ignoredLabelsArray+=($ignoredLabelsFromConfig)
    requiredLabelsArray+=($requiredLabelsFromConfig)
    optionalLabelsArray+=($optionalLabelsFromConfig)
    convertedLabelsArray+=($convertedLabelsFromConfig)
    labelsArray+=($labelsFromConfig $requiredLabels $requiredLabelsFromConfig $convertedLabelsFromConfig)

    # Deduplicate ignored labels
    ignoredLabelsArray=($(tr ' ' '\n' <<< "${ignoredLabelsArray[@]}" | sort -u | tr '\n' ' '))

    # Deduplicate required labels
    requiredLabelsArray=($(tr ' ' '\n' <<< "${requiredLabelsArray[@]}" | sort -u | tr '\n' ' '))

    # Deduplicate optional labels
    optionalLabelsArray=($(tr ' ' '\n' <<< "${optionalLabelsArray[@]}" | sort -u | tr '\n' ' '))

    # Deduplicate converted labels
    convertedLabelsArray=($(tr ' ' '\n' <<< "${convertedLabelsArray[@]}" | sort -u | tr '\n' ' '))

    # Deduplicate labels list
    labelsArray=($(tr ' ' '\n' <<< "${labelsArray[@]}" | sort -u | tr '\n' ' '))

    labelsArray=${labelsArray:|ignoredLabelsArray}

    appNamesArray=()
    # Get App Names for each label in labelsArray
    queuedLabelsForNames=("${(@s/ /)labelsArray}")
    for label in $queuedLabelsForNames; do
        log_verbose "Obtaining proper name for $label"
        # Issue 140 Fix: https://github.com/App-Auto-Patch/App-Auto-Patch/issues/140
        #appName="$(grep "name=" "$fragmentsPath/labels/$label.sh" | sed 's/name=//' | sed 's/\"//g' | sed 's/^[ \t]*//')"
        appName="$(awk -F\" '/^[[:space:]]*name=/{print $2; exit}' "$fragmentsPath/labels/$label.sh")"
        log_verbose "appName: $appName"
        appNamesArray+=(--listitem)
    if [[ ! -e "/Applications/${appName}.app" ]]; then
        appNamesArray+=(${appName},icon="${logoImage}")
    else 
        appNamesArray+=(${appName},icon="/Applications/${appName}.app")
    fi
    done

    log_notice "Labels to install: $labelsArray"
    log_notice "Ignoring labels: $ignoredLabelsArray"
    log_notice "Required labels: $requiredLabelsArray"
    log_notice "Optional Labels: $optionalLabelsArray"
    log_notice "Converted Labels: $convertedLabelsArray"

    log_info "Discovery of installed applications complete..."
    log_warning "Some false positives may appear in labelsArray as they may not be able to determine a new app version based on the Installomator label for the app"
    log_warning "Be sure to double-check the Installomator label for your app to verify"

    oldIFS=$IFS
    IFS=' '

    queuedLabelsArray=("${(@s/ /)labelsArray}")

    for label in $queuedLabelsArray; do
        countOfElementsArray+=($label)
    done
    #If queued labels more than zero trigger workflows
    if [[ ${#countOfElementsArray[@]} -gt 0 ]]; then
        numberOfUpdates=$((${#countOfElementsArray[@]}))
        
        if [[ "${workflow_install_now_option}" == "TRUE" ]] || [[ "${workflow_install_now_silent_option}" == "TRUE" ]] || [[ ${InteractiveModeOption} == 0 ]]; then
            rm -f "${WORKFLOW_INSTALL_NOW_FILE}" 2> /dev/null
            rm -f "${WORKFLOW_INSTALL_NOW_SILENT_FILE}" 2> /dev/null
            log_info "Install Now Workflow or Silent Mode active - Bypassing deferral workflow"
            log_notice "Passing ${numberOfUpdates} labels to Installomator: $queuedLabelsArray"
            workflow_do_Installations
            
            if [[ "$workflow_install_now_patching_status_action_option" == "ALWAYS" ]] || [[ "$workflow_install_now_patching_status_action_option" == "SUCCESS" && "${errorCount}" == 0 ]]; then
                defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus -bool true #Set completion status to true
                timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
                defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompleteDate -date "$timestamp"
            fi
            check_webhook
            if [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
                log_aap "Status: Patching Complete and Automatic Relaunch is disabled. Exiting."
                log_status "Inactive: Patching Complete and Automatic Relaunch is disabled."
                /usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string FALSE" "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
                { sleep 5; launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; } &
                disown
                exit_clean
            else
                deferral_timer_minutes="${deferral_timer_workflow_relaunch_minutes}"
                log_notice "Will auto launch in ${deferral_timer_minutes} minutes."
                set_auto_launch_deferral
            fi

        else
            check_deadlines_days_date
            # User Focus only needs to be checked if there are no date or day deadlines.
            if [[ "${deadline_days_status}" == "FALSE" ]]; then
                check_user_focus
            else # At this point any date or days deadline would rule out any ${user_focus_active} option.
                user_focus_active="FALSE"
            fi
            check_deadlines_count #Check if the user has passed the max deferral count
            # At this point all deferral and deadline options have been evaluated.
            
            if [[ "${deadline_days_status}" == "HARD" ]] || [[ "${deadline_count_status}" == "HARD" ]]; then # The Max number of deferrals have been used
                log_notice "Max number of deferrals have been used, display dialog and countdown to install workflow"
                dialog_install_hard_deadline
                log_info "Passing ${numberOfUpdates} labels to Installomator: $queuedLabelsArray"
                workflow_do_Installations
                defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus -bool true #Set completion status to true
                timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
                defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompleteDate -date "$timestamp"
                check_webhook

                if [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
                    log_aap "Status: Patching Complete and Automatic Relaunch is disabled. Exiting."
                    log_status "Inactive: Patching Complete and Automatic Relaunch is disabled."
                    /usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string FALSE" "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
                    { sleep 5; launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; } &
                    disown
                    exit_clean
                else
                deferral_timer_minutes="${deferral_timer_workflow_relaunch_minutes}"
                log_notice "Will auto launch in ${deferral_timer_minutes} minutes."
                set_auto_launch_deferral
                fi
                
            elif [[ "${user_focus_active}" == "TRUE" ]]; then # No deferral deadlines have passed but a process has told the display to not sleep or the user has enabled Focus or Do Not Disturb.
                log_info "Focus Mode Triggered"
                deferral_timer_minutes="${deferral_timer_focus_minutes}"
                write_status "Pending: Automatic user focus deferral, trying again in ${deferral_timer_minutes} minutes."
                set_auto_launch_deferral
            else # Display the deferral dialog
                log_info "Display Deferral Dialog"
                dialog_install_or_defer
                
                if [[ "${dialog_user_choice_install}" == "TRUE" ]]; then
                    log_notice "Passing ${numberOfUpdates} labels to Installomator: $queuedLabelsArray"
                    workflow_do_Installations
                    defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus -bool true #Set completion status to true
                    timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
                    defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompleteDate -date "$timestamp"
                    check_webhook
                    
                    if [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
                        log_aap "Status: Patching Complete and Automatic Relaunch is disabled. Exiting."
                        log_status "Inactive: Patching Complete and Automatic Relaunch is disabled."
                        /usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string FALSE" "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
                        { sleep 5; launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist"; } &
                        disown
                        exit_clean
                    else
                        deferral_timer_minutes="${deferral_timer_workflow_relaunch_minutes}"
                        log_notice "Will auto launch in ${deferral_timer_minutes} minutes."
                        set_auto_launch_deferral
                    fi
                else # The user chose to defer. 
                    deferral_timer_minutes=${deferral_timer_minutes} 
                    log_notice "User chose to defer, trying again in ${deferral_timer_minutes} minutes."
                    set_auto_launch_deferral
                fi
            fi
        fi
    else
        log_info "All apps are up to date. Nothing to do."
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompletionStatus -bool true #Set completion status to true
        timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
        defaults write "${appAutoPatchLocalPLIST}" AAPPatchingCompleteDate -date "$timestamp"
        
        if [ ${InteractiveModeOption} -gt 1 ]; then
            $dialogBinary --title "$appTitle" --message "${display_string_uptodate_message}" --windowbuttons min --icon "${icon}" --overlayicon "$overlayicon" --moveable --position topright --timer 60 --quitkey k --button1text "${display_string_uptodate_button1}" --style "mini" --hidetimerbar
        fi
        
        
        
        # Logic for ${workflow_disable_relaunch_option} and ${deferral_timer_workflow_relaunch_minutes}.
        if [[ "${workflow_disable_relaunch_option}" == "TRUE" ]]; then
            log_aap "Status: Full AAP workflow complete! Automatic relaunch is disabled."
            log_status "Inactive: Full AAP workflow complete! Automatic relaunch is disabled."
            /usr/libexec/PlistBuddy -c "Add :NextAutoLaunch string FALSE" "${appAutoPatchLocalPLIST}.plist" 2> /dev/null
        else # Default AAP workflow automatically relaunches.
            deferral_timer_minutes="${deferral_timer_workflow_relaunch_minutes}"
            #This should be set by configuration # # # deferral_timer_minutes="1440"
            log_info "All apps are up to date, will check again in ${deferral_timer_minutes} minutes."
            set_auto_launch_deferral
        fi 
    fi
}

main "$@"
exit