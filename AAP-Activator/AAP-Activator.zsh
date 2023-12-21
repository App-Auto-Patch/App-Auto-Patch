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

scriptVersion="1.0.0"
scriptFunctionalName="App Auto-Patch Activator"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

scriptLog="${4:-"/var/log/com.company.aap-activator.log"}"                                    	# Parameter 4: Script Log Location [ /var/log/com.company.log ] (i.e., Your organization's default location for client-side logs)
aapPolicyTrigger="${5:-"AppAutoPatch"}"                                                       	# Parameter 5: The trigger used to call the App Auto-Patch Jamf Policy [ex: AppAutoPatch ]
daysUntilReset="${6:-7}"									# Parameter 6: The number of days until the activator resets the patching status to False
debugMode="${11:-"false"}"                                                      		# Parameter 11: Debug Mode [ true | false (default) | verbose ] Verbose adds additional logging, debug turns Installomator script to DEBUG 2, false for production

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Various Feature Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

CurrentDate=$(date +"%Y-%m-%d")
CurrentDateEpoch=$(date -j -f "%Y-%m-%d" "$CurrentDate" "+%s")

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



if [[ ! -f $aapAutoPatchDeferralFile ]]; then
	debug "AAP Status configuration profile does not exist, creating now and setting patching to false"
	makePath "$aapAutoPatchDeferralFile"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
	debug "Setting AAPActivatorFlag to True"
	defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool true
else
	debug "Setting AAPActivatorFlag to True"
	defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool true
fi



weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
weeklyPatchingStatusDate=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate)


if [[ -z $weeklyPatchingComplete || -z $weeklyPatchingStatusDate ]]; then
	debug "Patching Completion Status or Start Date not set, setting values"
	makePath "$aapAutoPatchDeferralFile"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
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
	debug "Resetting Completion Status to False"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
fi
	

if [[  $weeklyPatchingComplete == 0 ]]; then
	infoOut "Executing App Auto-Patch"
	/usr/local/bin/jamf policy -trigger $aapPolicyTrigger
elif [[  $weeklyPatchingComplete == 1 ]]; then
	infoOut "Patching Status already Complete... Exiting"
	exit 0
else
	debug "Unknown Status... Setting status to False"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
	infoOut "Executing App Auto-Patch"
	/usr/local/bin/jamf policy -trigger $aapPolicyTrigger
fi
