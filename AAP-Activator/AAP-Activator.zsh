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

scriptVersion="0.0.3"
scriptFunctionalName="App Auto-Patch Activator"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

scriptLog="${4:-"/var/log/com.company.aap-activator.log"}"                                    # Parameter 4: Script Log Location [ /var/log/com.company.log ] (i.e., Your organization's default location for client-side logs)
aapPolicyTrigger="${5:-"AppAutoPatch"}"                                                       # Parameter 5: The trigger used to call the App Auto-Patch Jamf Policy [ex: AppAutoPatch ]
daysUntilReset="${6:-7}"								      # Parameter 6: The number of days until the activator resets the patching status to False

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Various Feature Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

CurrentDate=$(date +"%Y-%m-%d")
CurrentDateEpoch=$(date -j -f "%Y-%m-%d" "$CurrentDate" "+%s")

### Configuration PLIST variables ###

aapAutoPatchDeferralFile="/Library/Application Support/AppAutoPatch/AppAutoPatchDeferrals.plist"

function makePath() {
	mkdir -p "$(sed 's/\(.*\)\/.*/\1/' <<< $1)" # && touch $1

}




if [[ ! -f $aapAutoPatchDeferralFile ]]; then
	echo "AAP Status configuration profile does  not exist, creating now and setting weekly patching to false"
	makePath "$aapAutoPatchDeferralFile"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
fi



weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)


if [ -z $weeklyPatchingComplete ]; then
	echo "Weekly Patching Completion Status not set, setting to False"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
else
	echo "Weekly Patching Completion Status is $weeklyPatchingComplete"
fi

weeklyPatchingStatusDate=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate)
statusDateEpoch=$(date -j -f "%Y-%m-%d" "$weeklyPatchingStatusDate" "+%s")
EpochTimeSinceStatus=$(($CurrentDateEpoch - $statusDateEpoch))
DaysSinceStatus=$(($EpochTimeSinceStatus / 86400))

echo "Weekly Patching Status Date: $weeklyPatchingStatusDate"
echo "Current Date: $CurrentDate"
echo "Days Since Status Date: $DaysSinceStatus"

if [ ${DaysSinceStatus} -ge $daysUntilReset ]; then
	echo "Resetting Weekly Completion Status to False"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
fi
	

if [[  $weeklyPatchingComplete == 0 ]]; then
	echo "Executing App Auto-Patch"
	/usr/local/bin/jamf policy -trigger $aapPolicyTrigger
elif [[  $weeklyPatchingComplete == 1 ]]; then
	echo "Weekly Patching Complete... Exiting"
	exit 0
else
	echo "Unknown Status... Setting status to False and executing App Auto-Patch"
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool false
	defaults write $aapAutoPatchDeferralFile AAPWeeklyPatchingStatusDate "$CurrentDate"
	weeklyPatchingComplete=$(defaults read $aapAutoPatchDeferralFile AAPWeeklyPatching)
	/usr/local/bin/jamf policy -trigger $aapPolicyTrigger
fi
	
