#!/bin/zsh

####################################################################################################
#
# App Auto-Patch Activator
#
####################################################################################################
#
# HISTORY
#
#   Version 0.0.1, 12.07.2023, Andrew Spokes (@TechTrekkie)
#   - Initial Script
#
#   Version 0.0.2, 12.14.2023, Andrew Spokes (@TechTrekkie)
#   - Added makePath function to correct config file/folder permissions (Thanks @robjschroeder !)
#
#   Version 0.0.3, 12.19.2023, Andrew Spokes (@TechTrekkie)
#   - Changed AAP Jamf Policy trigger to use variable populated by Jamf Pro Script parameter #5, added parameter #6 for days until status reset
#
#   Version 1.0.0, 12.20.2023, Andrew Spokes (@TechTrekkie)
#	- Updated versioning
#	- Updated logic to populate Weekly Patching Start Date if it does not exist in the config file
#	- Updated logic to populate AAPActivatorFlag to populate variable in AAP script so a single script can be used for both Automated and Self Service workflows
#	- Added logging including debugging
#
#   Version 1.1.0, 02.12.2024, Andrew Spokes (@TechTrekkie)
#	- Added parameter to calculate the start date of the patch week to a specific day of the week. ex: Weekly patching starts on Tuesday but a Mac doesn't check in until Wednesday, the date will still be set to that Tuesdays date
#	- Added Display Assertion function in addition to maxDisplayAssertionCount variable to set the max amount of times to defer for active disply assertion
#	- Added AAPDisplayAssertionCount to PLIST to use for Extension Attribute/Smart Group to identify Macs with active display assertion deferrals (scope or a more frequent AAP Trigger)
#
####################################################################################################
#
# The purpose of this script is to run as a precursor to the App Auto-Patch scripts in order to
# determine if weekly patching has been completed successfully or not
#
####################################################################################################

####################################################################################################
#
# Global Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.1.0"
scriptFunctionalName="App Auto-Patch Activator"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

scriptLog="${4:-"/var/log/com.company.aap-activator.log"}"                              # Parameter 4: Script Log Location [ /var/log/com.company.log ] (i.e., Your organization's default location for client-side logs)
aapPolicyTrigger="${5:-"AppAutoPatch"}"                                                 # Parameter 5: The trigger used to call the App Auto-Patch Jamf Policy [ex: AppAutoPatch ]
daysUntilReset="${6:-7}"																# Parameter 6: The number of days until the activator resets the patching status to False
debugMode="${11:-"false"}"                                                      		# Parameter 11: Debug Mode [ true | false (default) | verbose ] Verbose adds additional logging, debug turns Installomator script to DEBUG 2, false for production


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Various Feature Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

patch_week_start_day=""																	# Patch Week Start Day of Week (1-7, blank to disable): The day of week to set the start date for weekly patching: (1=Mon 2=Tue...7=Sun)
maxDisplayAssertionCount=""																# The maximum number of deferred attempts from Display Assertions (Integer, blank to disable)

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

### Configuration PLIST variables ###

aapAutoPatchDeferralFile="/Library/Application Support/AppAutoPatch/AppAutoPatchDeferrals.plist"

####################################################################################################
#
# Pre-flight Checks (thanks, @dan-snelson)
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
	touch "${scriptLog}"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
	echo "${scriptFunctionalName}: $( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Path Related Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function makePath() {
	mkdir -p "$(sed 's/\(.*\)\/.*/\1/' <<< $1)"
	updateScriptLog "Path made: $1"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Logging Related Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function preFlight() {
	updateScriptLog "[PRE-FLIGHT] $1"
}

function notice() {
	updateScriptLog "[NOTICE] $1"
}

function debugVerbose() {
	if [[ "$debugMode" == "verbose" ]]; then
		updateScriptLog "[DEBUG VERBOSE] $1"
	fi
}

function debug() {
	if [[ "$debugMode" == "true" ]]; then
		updateScriptLog "[DEBUG] $1"
	fi
}

function infoOut() {
	updateScriptLog "[INFO] $1"
}

function errorOut(){
	updateScriptLog "[ERROR] $1"
}

function error() {
	updateScriptLog "[ERROR] $1"
	let errorCount++
}

function warning() {
	updateScriptLog "[WARNING] $1"
	let errorCount++
}

function fatal() {
	updateScriptLog "[FATAL ERROR] $1"
	exit 1
}

function quitOut(){
	updateScriptLog "[QUIT] $1"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# ${scriptFunctionalName} (${scriptVersion})\n###\n"
preFlight "Initiating …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
	preFlight "This script must be run as root; exiting."
	exit 1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Complete"


hasDisplaySleepAssertion() {
	# Get the names of all apps with active display sleep assertions
	local apps="$(/usr/bin/pmset -g assertions | /usr/bin/awk '/NoDisplaySleepAssertion | PreventUserIdleDisplaySleep/ && match($0,/\(.+\)/) && ! /coreaudiod/ {gsub(/^.*\(/,"",$0); gsub(/\).*$/,"",$0); print};')"
	
	if [[ ! "${apps}" ]]; then
		# No display sleep assertions detected
		return 1
	fi
	
	# Create an array of apps that need to be ignored
	local ignore_array=("${(@s/,/)IGNORE_DND_APPS}")
	
	for app in ${(f)apps}; do
		if (( ! ${ignore_array[(Ie)${app}]} )); then
			# Relevant app with display sleep assertion detected
			#printlog "Display sleep assertion detected by ${app}."
			infoOut  "Display sleep assertion detected by ${app}."
			return 0
		fi
	done
	
	# No relevant display sleep assertion detected
	return 1
}


if [[ ! -f $aapAutoPatchDeferralFile ]]; then
	debug "AAP Status configuration profile does not exist, creating now and setting patching to false"
	makePath "$aapAutoPatchDeferralFile"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$Patch_Week_Start_Date"
	debug "Setting AAPActivatorFlag to True"
	defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool true
	defaults write $aapAutoPatchDeferralFile AAPDisplayAssertionCount 0
else
	debug "Setting AAPActivatorFlag to True"
	defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool true
fi



weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
weeklyPatchingStatusDate=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate)
DisplayAssertionCount=$(defaults read $aapAutoPatchDeferralFile AAPDisplayAssertionCount)


if [[ -z $weeklyPatchingComplete || -z $weeklyPatchingStatusDate ]]; then
	debug "Patching Completion Status or Start Date not set, setting values"
	makePath "$aapAutoPatchDeferralFile"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$Patch_Week_Start_Date"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
	weeklyPatchingStatusDate=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate)
fi


statusDateEpoch=$(date -j -f "%Y-%m-%d" "$weeklyPatchingStatusDate" "+%s")
EpochTimeSinceStatus=$(($CurrentDateEpoch - $statusDateEpoch))
DaysSinceStatus=$(($EpochTimeSinceStatus / 86400))

infoOut "Patching Completion Status is $weeklyPatchingComplete"
infoOut "Patching Start Date is $weeklyPatchingStatusDate"
infoOut "Current Date: $CurrentDate"
infoOut "Days Since Patching Start Date: $DaysSinceStatus"

if [ ${DaysSinceStatus} -ge $daysUntilReset ]; then
	infoOut "Resetting Completion Status to False"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	infoOut "Setting Patch Week Start Date as $Patch_Week_Start_Date"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$Patch_Week_Start_Date"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
	defaults write $aapAutoPatchDeferralFile AAPDisplayAssertionCount 0
fi

if hasDisplaySleepAssertion; then
	infoOut  "active display sleep assertion detected"
	DisplayAssertionCount=$((DisplayAssertionCount+1))
	defaults write $aapAutoPatchDeferralFile AAPDisplayAssertionCount $DisplayAssertionCount
	infoOut "Display Assertion Count: $DisplayAssertionCount"
	DisplayAssertionCount=$(defaults read $aapAutoPatchDeferralFile AAPDisplayAssertionCount)
else
	infoOut  "No Assertions Detected"
	defaults write $aapAutoPatchDeferralFile AAPDisplayAssertionCount 0
	DisplayAssertionCount=$(defaults read $aapAutoPatchDeferralFile AAPDisplayAssertionCount)
fi


if [[  $weeklyPatchingComplete == 1 ]]; then
	infoOut "Patching Status already Complete... Exiting"
	defaults write $aapAutoPatchDeferralFile AAPDisplayAssertionCount 0
	exit 0
elif [[ ${DisplayAssertionCount} -ge 1 && ${DisplayAssertionCount} -le $maxDisplayAssertionCount ]]; then
	infoOut "Display Assertions Detected. Assertion Count $DisplayAssertionCount .... Exiting"
	exit 0
elif [[  $weeklyPatchingComplete == 0 ]]; then
	infoOut "Executing App Auto-Patch"
	/usr/local/bin/jamf policy -trigger $aapPolicyTrigger
else
	debug "Unknown Status... Setting status to False"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$Patch_Week_Start_Date"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
	infoOut "Executing App Auto-Patch"
	/usr/local/bin/jamf policy -trigger $aapPolicyTrigger
fi
