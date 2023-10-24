#!/bin/zsh

####################################################################################################
#
# App Auto-Patch via swiftDialog
#
####################################################################################################
#
# HISTORY
#
#   Version 1.0.5, 05.15.2023, Robert Schroeder (@robjschroeder)
#   - Trying to rewrite script for better readability
#   - Adding direct support to deploy within Jamf Pro
#
#   Version 1.0.6, 16-May-2023 Dan K. Snelson (@dan-snelson)
#   - Reduced size of main dialog
#   - Added `progress` and `progresstext`
#
#   Version 1.0.7, 05.16.2023, Robert Schroeder (@robjschroeder)
#   - Additional cleanup
#
#   Version 1.0.8, 17-May-2023 Dan K. Snelson (@dan-snelson)
#   - Changed extension to `.zsh` (to quiet Shellcheck)
#   - More dialog tweaks
#
#   Version 1.0.9, 05.18.2023 Robert Schroeder (@robjschroeder)
#   - Removed debugMode (was not being utilized throughout script)
#   - Changed `useswiftdialog` variable to `interactiveMode`
#   - Added variable `useOverlayIcon`
#   - Moved scriptVersion to infotext on swiftDialog windows
#   - Changed icon used for desktop computers to match platform (would like to grab model name and match accordingly: MacBook, Mac, Mac Mini, etc.)
#   - Changed `discovery` variable to `runDiscovery`
#   - Changed repository to App-Auto-Patch and script name to App-Auto-Patch-via-Dialog.zsh
#
#   Version 1.0.10, 05.23.2023 Robert Schroeder (@robjschroeder)
#   - Moved the creation of the overlay icon in the IF statement if useOverlayIcon is set to true
#
#   Version 1.0.11, 06.21.2023 Robert Schroeder (@robjschroeder)
#   - Added more options for running silently (Issue #3, thanks @beatlemike)
#   - Commented out the update count in List dialog infobox until accurate count can be used
#
#   Version 1.0.12, 06.29.2023 Robert Schroeder (@robjschroeder)
#   - Added variables for computer name and macOS version (Issue #6, thanks @AndrewMBarnett)
#   - Added computer variables to infobox of dialog
#
#   Version 1.0.13, 09.16.2023 Robert Schroeder (@robjschroeder)
#   - Fixed repo URL for swiftDialog
#
#   Version 1.0.14, 10.16.2023 Robert Schroeder (@robjschroeder)
#   - Made file path changes
#   - App Auto Patch version checking is now more accurate than before, if an app has an update available, it 
#   will be written to the plist at /Library/Application Support/AppAutoPatch/
#   - Some `Latest Versions` of apps cannot be identified during discovery. These apps will be added to the 
#   plist and will be caught when Installomator goes to install the update. These will show that the latest version
#   is already installed. 
#
#   Version 2.0-beta2, 10.18.2023 Robert Schroeder (@robjschroeder)
#   - Reworked workflow
#   - Added an unattended exit of Dialog parameter. If set to `true` and `unattendedExitSeconds` is defined, the Dialog process will be killed after the duration. 
#   - Added ability to add wildcards to ignoredLabels and requiredLabels (thanks, @jako)
#   - Added a swiftDialogMinimumRequiredVersion variable
#   - Updated minimum required OS for swiftDialog installation
#   - Updated logging functions
#   
#   Version 2.0-beta3, 10.19.2023 Robert Schroeder (@robjschroeder)
#   - Added plist created in /Library/Application Support/AppAutoPatch, this additional plist can be used to pull data from or build extension
#   attributes for Jamf Pro
#
#   Version 2.0.0b4, 10.20.2023 Robert Schroeder (@robjschroeder)
#   - Changed versioning schema from `0.0-beta0` to `0.0.0b0` (thanks, @dan-snelson)
#   - Modified --infotext box, removed $scriptFunctionalName and `Version:` (thanks, @dan-snelson)
#   - Removed app version number from discovery dialog (to be added later as a verboseMode)
#   - Various typo fixes
#
#   Version 2.0.0b5, 10.20.2023 Robert Schroeder (@robjschroeder)
#   - AAP now uses it own directory in `/Library/Application Support` to store Installomator. This directory gets removed after processing (thanks for the suggestion @dan-snelson!)
#   - Had to update some of the hardcoded Installomator paths. 
#
#   Version 2.0.0b6, 10.23.2023 Robert Schroeder (@robjschroeder)
#   - Added a function to create the App Auto-Patch directory, if it doesn't already exist. ( /Library/Application Support/AppAutoPatch )
#
#   Version 2.0.0b7, 10.23.2023 Robert Schroeder (@robjschroeder)
#   - Fixed some logic during discovery that prevented some apps from being queued. (Issue #14, thanks @Apfelpom)
#   - Added more checks when determining available version vs installed version. Some Installomator app labels do not report an 
#   accurate appNewVersion variable, those will be found in the logs as "[WARNING] --- Latest version could not be determined from Installomator app label"
#   These apps will be queued regardless of having a properly updated app. [Line No. ~851-870]
#   - With the added checks for versioning, if an app with a higher version is installed vs available version from Installomator, the app will not be queued. (thanks, @dan-snelson)
#  
#   Version 2.0.0b8, 10.24.2023 Robert Schroeder (@robjschroeder)
#   - Removed the extra checks for versioning, this became more of a hinderance and caused issues. Better to queue the label and not need it than to not queue an app that needs an update. 
#   Addresses issue #20 (thanks @Apfelpom)
#   - If a wildcard is used for `IgnoredLabels` you can override an individual label by placing it in the required labels. 
#   - Addressed issue where wildcards wrote additional plist entry 'Application'
#   - Merged PR #21, Added a help message with variables for the update window. (thanks, @AndrewMBarnett)
#   - Issue #13, `Discovering firefoxpkg_intl but installing firefoxpkgintl`, fixed.
#
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

scriptVersion="2.0.0b8"
scriptFunctionalName="App Auto-Patch"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

scriptLog="${4:-"/var/log/com.company.log"}"                                    # Parameter 4: Script Log Location [ /var/log/com.company.log ] (i.e., Your organization's default location for client-side logs)
useOverlayIcon="${5:="true"}"                                                   # Parameter 5: Toggles swiftDialog to use an overlay icon [ true (default) | false ]
interactiveMode="${6:="2"}"                                                     # Parameter 6: Interactive Mode [ 0 (Completely Silent) | 1 (Silent Discovery, Interactive Patching) | 2 (Full Interactive) ]
ignoredLabels="${7:=""}"                                                        # Parameter 7: A space-separated list of Installomator labels to ignore (i.e., "firefox* zoomgov googlechromeenterprise nudge microsoft*")
requiredLabels="${8:=""}"                                                       # Parameter 8: A space-separated list of required Installomator labels (i.e., "firefoxpkg_intl")
outdatedOsAction="${9:-"/System/Library/CoreServices/Software Update.app"}"     # Parameter 9: Outdated OS Action [ /System/Library/CoreServices/Software Update.app (default) | jamfselfservice://content?entity=policy&id=117&action=view ] (i.e., Jamf Pro Self Service policy ID for operating system upgrades)
unattendedExit="${10:-"false"}"                                                 # Parameter 10: Unattended Exit [ true | false (default) ]
# debugMode="${11:-"false"}"                                                    # Parameter 11: Reserving Parameter 11 for debug modes....
unattendedExitSeconds="60"							# Number of seconds to wait until a kill Dialog command is sent
swiftDialogMinimumRequiredVersion="2.3.2.4726"					# Minimum version of swiftDialog required to use workflow


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Various Feature Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

### Path variables ###

aapPath="/Library/Application Support/AppAutoPatch"
installomatorPath="/Library/Application Support/AppAutoPatch/Installomator"
installomatorScript="$installomatorPath/Installomator.sh"

fragmentsPath="$installomatorPath/fragments"

### Configuration PLIST variables ###

runDiscovery="true"
appAutoPatchConfigFile="/Library/Application Support/AppAutoPatch/AppAutoPatch.plist"
appAutoPatchStatusConfigFile="/Library/Application Support/AppAutoPatch/AppAutoPatchStatus.plist"
declare -A configArray=()
ignoredLabelsArray=($(echo ${ignoredLabels}))
requiredLabelsArray=($(echo ${requiredLabels}))

### Installomator Options ###

BLOCKING_PROCESS_ACTION="prompt_user"
NOTIFY="silent"
LOGO="appstore"

### Other variables ###

# Set icon based on whether the Mac is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
    icon="SF=laptopcomputer.and.arrow.down,weight=regular,colour1=gray,colour2=red"
else
    icon="SF=desktopcomputer.and.arrow.down,weight=regular,colour1=gray,colour2=red"
fi

# Create `overlayicon` from Self Service's custom icon (thanks, @meschwartz!)
if [[ "$useOverlayIcon" == "true" ]]; then
    xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
    overlayicon="/var/tmp/overlayicon.icns"
else
    overlayicon=""
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Operating System, Computer Model Name, etc.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

computerName=$( scutil --get ComputerName )
osVersion=$( sw_vers -productVersion )
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
macOSproductVersion="$( sw_vers -productVersion )"
macOSbuildVersion="$( sw_vers -buildVersion )"
serialNumber=$( ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}' )
timestamp="$( date '+%Y-%m-%d-%H%M%S' )"
dialogVersion=$( /usr/local/bin/dialog --version )
exitCode="0"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# IT Support Variable (thanks, @AndrewMBarnett)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

supportTeamName="Add IT Support"
supportTeamPhone="Add IT Phone Number"
supportTeamEmail="Add email"
supportWebsite="Add IT Help site"
#supportKB=""
#supportTeamErrorKB=", and mention [${supportKB}](https://servicenow.company.com/support?id=kb_article_view&sysparm_article=${supportKB}#Failures)"
#supportTeamHelpKB="\n- **Knowledge Base Article:** ${supportKB}"

helpMessage="If you need assistance, please contact ${supportTeamName}:  \n- **Telephone:** ${supportTeamPhone}  \n- **Email:** ${supportTeamEmail}  \n- **Help Website:** ${supportWebsite}  \n\n**Computer Information:**  \n- **Operating System:**  $macOSproductVersion ($macOSbuildVersion)  \n- **Serial Number:** $serialNumber  \n- **Dialog:** $dialogVersion  \n- **Started:** $timestamp"

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
# Logging Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function makePath() {
    mkdir -p "$(sed 's/\(.*\)\/.*/\1/' <<< $1)" # && touch $1
    updateScriptLog "Path made: $1"
}

function preFlight() {
        updateScriptLog "[PRE-FLIGHT] $1"
}

function notice() {
        updateScriptLog "[NOTICE] $1"
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
# Pre-flight Check: Current Logged-in User Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function currentLoggedInUser() {
    loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
    preFlight "Current Logged-in User: ${loggedInUser}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# ${scriptFunctionalName} (${scriptVersion})\n# https://techitout.xyz/app-auto-patch\n###\n"
preFlight "Initiating …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    preFlight "This script must be run as root; exiting."
    exit 1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm Dock is running / user is at Desktop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
    preFlight "Finder & Dock are NOT running; pausing for 1 second"
    sleep 1
done

preFlight "Finder & Dock are running; proceeding …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Logged-in System Accounts
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Check for Logged-in System Accounts …"
currentLoggedInUser

counter="1"

until { [[ "${loggedInUser}" != "_mbsetupuser" ]] || [[ "${counter}" -gt "180" ]]; } && { [[ "${loggedInUser}" != "loginwindow" ]] || [[ "${counter}" -gt "30" ]]; } ; do

    preFlight "Logged-in User Counter: ${counter}"
    currentLoggedInUser
    sleep 2
    ((counter++))

done

loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | sed 's/\(.\{25\}\).*/\1…/' | awk '{print ( $0 == toupper($0) ? toupper(substr($0,1,1))substr(tolower($0),2) : toupper(substr($0,1,1))substr($0,2) )}' )
loggedInUserID=$( id -u "${loggedInUser}" )
preFlight "Current Logged-in User First Name: ${loggedInUserFirstname}"
preFlight "Current Logged-in User ID: ${loggedInUserID}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Operating System Version Monterey or later
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
# Since swiftDialog requires at least macOS 12 Monterey, first confirm the major OS version
if [[ "${osMajorVersion}" -ge 12 ]] ; then
    
    preFlight "macOS ${osMajorVersion} installed; proceeding ..."
    
else
    
    # The Mac is running an operating system older than macOS 11 Big Sur; exit with error
    preFlight "swiftDialog requires at least macOS 12 Monterey and this Mac is running ${osVersion} (${osBuild}), exiting with error."
    osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Monterey (or newer), but found macOS '"${osVersion}"' ('"${osBuild}"').\r\r" with title "'"${scriptFunctionalName}"': Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
    preFlight "Executing /usr/bin/open '${outdatedOsAction}' …"
    su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
    exit 1

fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Ensure computer does not go to sleep during AAP (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

aapPID="$$"
preFlight "Caffeinating this script (PID: $aapPID)"
caffeinate -dimsu -w $aapPID &

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogInstall() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    preFlight "Installing swiftDialog..."

    # Create temporary working directory
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
        preFlight "swiftDialog version ${dialogVersion} installed; proceeding..."

    else

        # Display a so-called "simple" dialog if Team ID fails to validate
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "'"${scriptFunctionalName}"': Error" buttons {"Close"} with icon caution'
        exitCode="1"
        quitScript

    fi

    # Remove the temporary working directory when done
    rm -Rf "$tempDirectory"

}

function dialogCheck() {

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        preFlight "swiftDialog not found. Installing..."
        dialogInstall

    else

        dialogVersion=$(/usr/local/bin/dialog --version)
        if [[ "${dialogVersion}" < "${swiftDialogMinimumRequiredVersion}" ]]; then
            
            preFlight "swiftDialog version ${dialogVersion} found but swiftDialog ${swiftDialogMinimumRequiredVersion} or newer is required; updating..."
            dialogInstall
            
        else

        preFlight "swiftDialog version ${dialogVersion} found; proceeding..."

        fi
    
    fi

}

dialogCheck

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Complete"

####################################################################################################
#
# Dialog Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dialog path and Command Files
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogBinary="/usr/local/bin/dialog"
dialogCommandFile=$( mktemp /var/tmp/dialog.appAutoPatch.XXXXX )

####################################################################################################
#
# List dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "list" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogListConfigurationOptions=(
    --title "${scriptFunctionalName}"
    --message "Updating the following apps …"
    --commandfile "$dialogCommandFile"
    --moveable
    --button1text "Done"
    --button1disabled
    --height 500
    --width 650
    --position bottomright
    --progress
    --helpmessage "$helpMessage"
    --infobox "#### Computer Name: #### \n\n $computerName \n\n #### macOS Version: #### \n\n $osVersion \n\n #### macOS Build: #### \n\n $osBuild "
    --infotext "${scriptVersion}"
    --liststyle compact
    --titlefont size=18
    --messagefont size=11
    --quitkey k
    --icon "$icon"
    --overlayicon "$overlayicon"
)

####################################################################################################
#
# Write dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Write" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogWriteConfigurationOptions=(
    --title "${scriptFunctionalName}"
    --message "Analyzing installed apps …"
    --icon "$icon"
    --overlayicon "$overlayicon"
    --commandfile "$dialogCommandFile"
    --moveable
    --mini
    --position bottomright
    --progress
    --progresstext "Scanning …"
    --quitkey k
)

####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        infoOut "Attempting to terminate the '$process' process …"
        infoOut "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            errorOut "'$process' could not be terminated."
        fi
    else
        infoOut "The '$process' process isn't running."
    fi
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Installomator
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function removeInstallomator() {
    notice "Removing Installomator..."
    rm -rf ${installomatorPath}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit the caffeinated script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function caffeinateExit() {
    infoOut "De-caffeinate $aapPID..."
    killProcess "caffeinate"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Exit the Dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogExit() {

    if [[ "$unattendedExit" == "true" ]]; then
        infoOut "Unattended exit set to 'true', waiting $unattendedExitSeconds seconds then sending kill to Dialog"
        sleep $unattendedExitSeconds
        infoOut "Killing the dialog"
        killProcess "Dialog"
    else
        infoOut "Unattended exit set to 'false', leaving dialog on screen"
    fi

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {
    quitOut "Exiting …"
    
    # Stop `caffeinate` process
    caffeinateExit

    # Stop the `Dialog` process
    dialogExit &
    
    # Remove overlayicon
    if [[ -e ${overlayicon} ]]; then
        quitOut "Removing ${overlayicon} …"
        rm "${overlayicon}"
    fi
    
    # Remove welcomeCommandFile
    if [[ -e ${dialogCommandFile} ]]; then
        quitOut "Removing ${dialogCommandFile} …"
        rm "${dialogCommandFile}"
    fi
    
    exit $exitCode
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# swiftDialog Functions (thanks, @BigMacAdmin)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function swiftDialogCommand(){
    if [ ${interactiveMode} -gt 0 ]; then
        echo "$@" > "$dialogCommandFile"
        sleep .2
    fi
}

function swiftDialogListWindow(){
    # If we are using SwiftDialog
    if [ ${interactiveMode} -ge 1 ]; then
        # Check if there's a valid logged in user:
        currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
        if [ "$currentUser" = "root" ] \
            || [ "$currentUser" = "loginwindow" ] \
            || [ "$currentUser" = "_mbsetupuser" ] \
            || [ -z "$currentUser" ] 
        then
            return 0
        fi
        
        # Build our list of Display Names for SwiftDialog list
        for label in $queuedLabelsArray
        do
            # Get the "name=" value from the current label and use it in our SwiftDialog list
            currentDisplayName=$(sed -n '/# label descriptions/,$p' ${installomatorScript} | grep -i -A 50 "${label})" | grep -m 1 "name=" | sed 's/.*=//' | sed 's/"//g')
            if [ -n "$currentDisplayName" ]
            then
                displayNames+=("--listitem")
                displayNames+=(${currentDisplayName})
            fi
        done
        touch "$dialogCommandFile"
        # Create our running swiftDialog window
        $dialogBinary \
        ${dialogListConfigurationOptions[@]} \
        ${displayNames[@]} \
        &
    fi
}

function completeSwiftDialogList(){
    if [ ${interactiveMode} -ge 1 ]; then
        # swiftDialogCommand "listitem: add, title: Updates Complete!,status: success"
        swiftDialogUpdate "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        swiftDialogUpdate "progress: complete"
        swiftDialogUpdate "progresstext: Updates Complete!"
        
        sleep 1
        # Activate button 1
        swiftDialogCommand "button1: enabled"
    fi
    # Delete the tmp command file
    rm "$dialogCommandFile"
}

function swiftDialogWriteWindow(){
    # If we are using SwiftDialog
    touch "$dialogCommandFile"
    if [ ${interactiveMode} -gt 1 ]; then
        $dialogBinary \
        ${dialogWriteConfigurationOptions[@]} \
        &
    fi
}

function completeSwiftDialogWrite(){
    if [ ${interactiveMode} -gt 1 ]; then
        swiftDialogCommand "quit:"
        rm "$dialogCommandFile"
    fi
}

function swiftDialogUpdate(){
    infoOut "Update swiftDialog: $1" 
    echo "$1" >> "$dialogCommandFile"
    # sleep 0.4
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create AppAutoPatch folder, if it doesn't exist
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ ! -d "${aapPath}" ]; then
	notice "$aapPath does not exist, create it now"
        mkdir "${aapPath}"
else
	infoOut "AAP path already exists, continuing..."
fi


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Installomator (thanks, @option8)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function checkInstallomator() {
    # Latest version of Installomator and collateral will be downloaded to $installomatorPath defined above

    # Does the $installomatorPath Exist or does it need to get created
    if [ ! -d "${installomatorPath}" ]; then
        notice "$installomatorPath does not exist, create it now"
        mkdir "${installomatorPath}"
    else
        infoOut "AAP Installomator directory exists"
    fi

    notice "Checking for Installomator.sh at $installomatorScript"
    
    if ! [[ -f $installomatorScript ]]; then
        warning "Installomator was not found at $installomatorScript"
        
        infoOut "Attempting to download Installomator.sh at $installomatorScript"

        latestURL=$(curl -sSL -o - "https://api.github.com/repos/Installomator/Installomator/releases/latest" | grep tarball_url | awk '{gsub(/[",]/,"")}{print $2}')

        tarPath="$installomatorPath/installomator.latest.tar.gz"

        notice "Downloading ${latestURL} to ${tarPath}"

        curl -sSL -o "$tarPath" "$latestURL" || fatal "Unable to download. Check ${installomatorPath} is writable."

        notice "Extracting ${tarPath} into ${installomatorPath}"
        tar -xz -f "$tarPath" --strip-components 1 -C "$installomatorPath" || fatal "Unable to extract ${tarPath}. Corrupt or incomplete download?"
    else
        notice "Installomator was found at $installomatorScript, checking version..."
        appNewVersion=$(curl -sLI "https://github.com/Installomator/Installomator/releases/latest" | grep -i "^location" | tr "/" "\n" | tail -1 | sed 's/[^0-9\.]//g')
        appVersion="$(cat $fragmentsPath/version.sh)"
        if [[ ${appVersion} -lt ${appNewVersion} ]]; then
            errorOut "Installomator is installed, but is out of date. Versions prior to 10.0 function unpredictably with App Auto Patch."
            infoOut "Removing previously installed Installomator version ($appVersion) and reinstalling with latest version ($appNewVersion)"
            removeInstallomator
            sleep .2
            checkInstallomator
        else
            infoOut "Installomator latest version ($appVersion) installed, continuing..."
        fi
    fi

    # Set Installomator script to production
    notice "Setting Installomator script to production"
    /usr/bin/sed -i.backup1 "s|DEBUG=1|DEBUG=0|g" $installomatorScript
    sleep .2

}

checkInstallomator

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Discovery of installed applications (thanks, @option8)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function PgetAppVersion() {

    if [[ $packageID != "" ]]; then
        
        appversion="$(pkgutil --pkg-info-plist ${packageID} 2>/dev/null | grep -A 1 pkg-version | tail -1 | sed -E 's/.*>([0-9.]*)<.*/\1/g')"
        
    fi
    
    if [ -z "$appName" ]; then
        # when not given derive from name
        appName="$name.app"
    fi
    
    notice "Searching for $appName"
    
    if [[ -d "/Applications/$appName" ]]; then
        applist="/Applications/$appName"
    elif [[ -d "/Applications/Utilities/$appName" ]]; then
        applist="/Applications/Utilities/$appName"
    else
        #        applist=$(mdfind "kind:application $appName" -0 )
        applist=$(mdfind "kMDItemFSName == '$appName' && kMDItemContentType == 'com.apple.application-bundle'" -0 )
        # random files named *.app were potentially coming up in the list. Now it has to be an actual app bundle
    fi
    
    appPathArray=( ${(0)applist} )
    
    if [[ ${#appPathArray} -gt 0 ]]; then
        
        filteredAppPaths=( ${(M)appPathArray:#${targetDir}*} )
        
        if [[ ${#filteredAppPaths} -eq 1 ]]; then
            installedAppPath=$filteredAppPaths[1]
            
            appversion=$(defaults read $installedAppPath/Contents/Info.plist $versionKey)
            
            infoOut "Found $appName version $appversion"
            sleep .2
            
            if [ ${interactiveMode} -gt 1 ]; then
                # swiftDialogUpdate "message: Analyzing ${appName//.app/} ($appversion)"
                swiftDialogUpdate "message: Analyzing ${appName//.app/}"
            fi
            
            notice "Label: $label_name"
            notice "--- found app at $installedAppPath"
            
            # Is current app from App Store
            if [[ -d "$installedAppPath"/Contents/_MASReceipt ]]; then
                notice "--- $appName is from App Store. Skipping."
                notice "Use the Installomator option \"IGNORE_APP_STORE_APPS=no\" to replace."
                return
                
            else
                verifyApp $installedAppPath
            fi
        fi
    fi
}

#
# Commenting out function convertAppVersion (saving for later maybe)
# function convertAppVersion() {
#     echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
#}
#

function verifyApp() {
	
	appPath=$1
	notice "Verifying: $appPath"
    sleep .2
	swiftDialogUpdate "progresstext: Verifying $appPath"
	
	# verify with spctl
	appVerify=$(spctl -a -vv "$appPath" 2>&1 )
	appVerifyStatus=$(echo $?)
	teamID=$(echo $appVerify | awk '/origin=/ {print $NF }' | tr -d '()' )
	
	if [[ $appVerifyStatus -ne 0 ]]
	then
		error "Error verifying $appPath"
        error "Returned $appVerifyStatus"
		return
	fi
	
	if [ "$expectedTeamID" != "$teamID" ]
	then
		error "Error verifying $appPath"
		notice "Team IDs do not match: expected: $expectedTeamID, found $teamID"
		return
	else
		
		
		# run the commands in current_label to check for the new version string
		newversion=$(zsh << SCRIPT_EOF
declare -A levels=(DEBUG 0 INFO 1 WARN 2 ERROR 3 REQ 4)
currentUser=$currentUser
source "$fragmentsPath/functions.sh"
${current_label}
echo "\$appNewVersion" 
SCRIPT_EOF
)
	fi
	
	# build array of labels for the config and/or installation
	
	# push label to array
	# if in write config mode, writes to plist. Otherwise to an array.
	# Test if label name in ignored labels
	if [[ ! " ${ignoredLabelsArray[@]} " =~ " ${label_name} " ]]; then
		if [[ -n "$configArray[$appPath]" ]]; then
			exists="$configArray[$appPath]"
		
			infoOut "${appPath} already linked to label ${exists}."
			if [[ ${#noninteractive} -eq 1 ]]; then
				echo "Skipping."
				return
			else
				notice "Replacing label ${exists} with $label_name?"
			
				configArray[$appPath]=$label_name
				
				/usr/libexec/PlistBuddy -c "set \":${appPath}\" ${label_name}" "$appAutoPatchConfigFile"
			fi
		else
			
			configArray[$appPath]=$label_name
            notice "--- Installed version: ${appversion}"


            newversion1=$( echo "${newversion}" | sed 's/[^a-zA-Z0-9]*$//g' )
            appversion1=$( echo "${appversion}" | sed 's/[^a-zA-Z0-9]*$//g' )

            [[ -n "$newversion" ]] && notice "--- Newest version: ${newversion}"

            # installedVer=$(convertAppVersion $appversion1)
            # availableVer=$(convertAppVersion $newversion1)

            # This is the math verison of the if, saving here to figure out later
            # if [[ "$appversion1" == "$newversion1" ]]; then
            #     notice "--- Latest version installed."
            # elif [[ "$availableVer" == "0000000000" ]]; then
            #     warning "--- Latest version could not be determined from Installomator app label"
            #     /usr/libexec/PlistBuddy -c "add \":${appPath}\" string ${label_name}" "$appAutoPatchConfigFile"
            #     queueLabel
            # elif [[ "$installedVer" -ge "$availableVer" ]]; then
            #     notice "--- Latest version installed"
            # else
            #     notice "--- Newer version available"
            #     /usr/libexec/PlistBuddy -c "add \":${appPath}\" string ${label_name}" "$appAutoPatchConfigFile"
            #     queueLabel
            # fi

            if [[ "$appversion1" == "$newversion1" ]]; then
                notice "--- Latest version installed."
            else
                /usr/libexec/PlistBuddy -c "add \":${appPath}\" string ${label_name}" "$appAutoPatchConfigFile"
                queueLabel
            fi
		fi
	fi
}

function queueLabel() {
    
    notice "Queueing $label_name"

    labelsArray+="$label_name "
    infoOut "$labelsArray"
    
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# PLIST creation and population
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# AAPVersion
# AAPLastRun
# AAPDiscovery

if [[ ! -f $appAutoPatchStatusConfigFile ]]; then
    notice "Status configuration profile does  not exist, creating now..."
    timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
    defaults write $appAutoPatchStatusConfigFile AAPVersion -string "$scriptVersion"
    defaults write $appAutoPatchStatusConfigFile AAPLastRun -date "$timestamp"
else
    notice "Status configuration already exists, continuing..."
    timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
    defaults write $appAutoPatchStatusConfigFile AAPVersion -string "$scriptVersion"
    defaults write $appAutoPatchStatusConfigFile AAPLastRun -date "$timestamp"
fi


if [[ "${runDiscovery}" == "true" ]]; then
    timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
    notice "Last Discovery Run: $timestamp"
    defaults write $appAutoPatchStatusConfigFile AAPDiscovery -date "$timestamp"
    
    notice "Re-run discovery of installed applications at $appAutoPatchConfigFile"
    if [[ -f $appAutoPatchConfigFile ]]; then
        rm -f $appAutoPatchConfigFile
    fi

    notice "No config file at $appAutoPatchConfigFile. Running discovery."
    # Call the bouncing progress SwiftDialog window
    swiftDialogWriteWindow

    notice "Writing Config"

    infoOut "No config file at $appAutoPatchConfigFile. Creating one now."
    makePath "$appAutoPatchConfigFile"


    /usr/libexec/PlistBuddy -c "clear dict" "${appAutoPatchConfigFile}"
    /usr/libexec/PlistBuddy -c 'add ":IgnoredLabels" array' "${appAutoPatchConfigFile}"
    /usr/libexec/PlistBuddy -c 'add ":RequiredLabels" array' "${appAutoPatchConfigFile}"

    # Populate Ignored Labels
        notice "Attempting to populate ignored labels"
        for ignoredLabel in "${ignoredLabelsArray[@]}"; do
            if [[ -f "${fragmentsPath}/labels/${ignoredLabel}.sh" ]]; then
                infoOut "Writing ignored label $ignoredLabel to configuration plist"
                /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"${ignoredLabel}\"" "${appAutoPatchConfigFile}"
            else
                if [[ "${ignoredLabel}" == *"*"* ]]; then
                    notice "Ignoring all lables with $ignoredLabel"
                    wildIgnored=( $(find $fragmentsPath/labels -name "$ignoredLabel") )
                    for i in "${wildIgnored[@]}"; do
                        ignored=$( echo $i | cut -d'.' -f1 | sed 's@.*/@@' )
                        if [[ ! "$ignored" == "Application" ]]; then
                            infoOut "Writing ignored label $ignored to configuration plist"
                            /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"${ignored}\"" "${appAutoPatchConfigFile}"
                            ignoredLabelsArray+=($ignored)
                        else
                            sleep .1
                        fi
                    done 
                else
                    notice "No such label ${ignoredLabel}"
                fi
            fi
        done

        # Populate Required Labels
        notice "Attempting to populate required labels"
        for requiredLabel in "${requiredLabelsArray[@]}"; do
            if [[ -f "${fragmentsPath}/labels/${requiredLabel}.sh" ]]; then
                infoOut "Writing required label ${requiredLabel} to configuration plist"
                /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${requiredLabel}\"" "${appAutoPatchConfigFile}"
            else
                if [[ "${requiredLabel}" == *"*"* ]]; then
                    notice "Requiring all labels with $requiredLabel"
                    wildRequired=( $(find $fragmentsPath/labels -name "$requiredLabel") )
                    for i in "${wildRequired[@]}"; do
                        required=$( echo $i | cut -d'.' -f1 | sed 's@.*/@@' )
                        if [[ ! "$required" == "Application" ]]; then
                            infoOut "Writing required label $required to configuration plist"
                            /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${required}\"" "${appAutoPatchConfigFile}"
                            requiredLabelsArray+=($required)
                        else
                            sleep .1
                        fi
                    done
                else
                    notice "No such label ${requiredLabel}"
                fi
            fi
        done

    # start of label pattern
    label_re='^([a-z0-9\_-]*)(\))$'
    #label_re='^([a-z0-9\_-]*)(\)|\|\\)$' 

    # ignore comments
    comment_re='^\#$'

    # end of label pattern
    endlabel_re='^;;'

    targetDir="/"
    versionKey="CFBundleShortVersionString"

    IFS=$'\n'
    in_label=0
    current_label=""

    # for each .sh file in fragments/labels/ strip out the switch/case lines and any comments. 

    for labelFragment in "$fragmentsPath"/labels/*.sh; do 
        
        labelFile=$(basename -- "$labelFragment")
        labelFile="${labelFile%.*}"
        
        if [[ $ignoredLabelsArray =~ ${labelFile} ]]; then
            notice "Ignoring label $labelFile."
            continue # we're done here. Move along.
        fi
        
        exec 3< "${labelFragment}"
        
        while read -r -u 3 line; do 
            
            # strip spaces and tabs 
            scrubbedLine="$(echo $line | sed -E 's/^( |\t)*//g')"
            
            if [ -n $scrubbedLine ]; then
                
                if [[ $in_label -eq 0 && "$scrubbedLine" =~ $label_re ]]; then
                    label_name=${match[1]}
                    in_label=1
                    continue # skips to the next iteration
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
                    
                    continue # skips to the next iteration
                fi
                
                if [[ $in_label -eq 1 && ! "$scrubbedLine" =~ $comment_re ]]; then
                    # add the label lines to create a "subscript" to check versions and whatnot
                    # if empty, add the first line. Otherwise, you'll get a null line
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
    completeSwiftDialogWrite

fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set variables for various labels
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

labelsFromConfig=($(defaults read "$appAutoPatchConfigFile" | grep -e ';$' | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:]" | tr -s "[:space:]"))

ignoredLabelsFromConfig=($(defaults read "$appAutoPatchConfigFile" IgnoredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:]" | tr -s "[:space:]"))

requiredLabelsFromConfig=($(defaults read "$appAutoPatchConfigFile" RequiredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:]" | tr -s "[:space:]"))

ignoredLabelsArray+=($ignoredLabelsFromConfig)
requiredLabelsArray+=($requiredLabelsFromConfig)

labelsArray+=($labelsFromConfig $requiredLabels $requiredLabelsFromConfig)

#     # deduplicate ignored labels
ignoredLabelsArray=($(tr ' ' '\n' <<< "${ignoredLabelsArray[@]}" | sort -u | tr '\n' ' '))

#     # deduplicate required labels
requiredLabelsArray=($(tr ' ' '\n' <<< "${requiredLabelsArray[@]}" | sort -u | tr '\n' ' '))

#     # deduplicate labels list
labelsArray=($(tr ' ' '\n' <<< "${labelsArray[@]}" | sort -u | tr '\n' ' '))

labelsArray=${labelsArray:|ignoredLabelsArray}

notice "Labels to install: $labelsArray"
notice "Ignoring labels: $ignoredLabelsArray"
notice "Required labels: $requiredLabelsArray"

infoOut "Discovery of installed applications complete..."
warning "Some false positives may appear in labelsArray as they may not be able to determine a new app version based on the Installomator label for the app"
warning "Be sure to double check the Installomator label for your app to verify"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete Installation Of Discovered Applications
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function doInstallations() {
    
    if [ "$BLOCKING_PROCESS_ACTION" ]; then
        InstallomatorOptions+="BLOCKING_PROCESS_ACTION=$BLOCKING_PROCESS_ACTION"
        InstallomatorOptions+=" "
    fi
    
    if [ "$NOTIFY" ]; then
        InstallomatorOptions+="NOTIFY=$NOTIFY"
        InstallomatorOptions+=" "
    fi
    
    if [ "$LOGO" ]; then
        InstallomatorOptions+="LOGO=$LOGO"
        InstallomatorOptions+=" "
    fi
    
    InstallomatorOptions=$InstallomatorOptions
    
    infoOut "Installomator Options: $InstallomatorOptions"
    
    # Count errors
    errorCount=0
    
    # Create our main "list" swiftDialog Window
    swiftDialogListWindow
    
    if [ ${interactiveMode} -ge 1 ]; then
        queuedLabelsArrayLength="${#queuedLabelsArray[@]}"
        progressIncrementValue=$(( 100 / queuedLabelsArrayLength ))
        infoOut "Number of Updates: $queuedLabelsArrayLength"
        swiftDialogUpdate "infobox: **Updates:** $queuedLabelsArrayLength"
    fi

    i=0
    for label in $queuedLabelsArray
    do
        infoOut "Installing ${label}..."
        swiftDialogUpdate "progress: increment ${progressIncrementValue}"
        
        # Use built in swiftDialog Installomator integration options (if swiftDialog is being used)
        swiftDialogOptions=()
        if [ ${interactiveMode} -ge 1 ]; then
            swiftDialogOptions+=(DIALOG_CMD_FILE="\"${dialogCommandFile}\"")
            
            # Get the "name=" value from the current label and use it in our swiftDialog list
            currentDisplayName=$(sed -n '/# label descriptions/,$p' ${installomatorScript} | grep -i -A 50 "${label})" | grep -m 1 "name=" | sed 's/.*=//' | sed 's/"//g')
            # There are some weird \' shenanigans here because Installomator passes this through eval
            swiftDialogOptions+=(DIALOG_LIST_ITEM_NAME=\'"${currentDisplayName}"\')
            sleep .5

            swiftDialogUpdate "icon: /Applications/${currentDisplayName}.app"
            swiftDialogUpdate "progresstext: Checking ${currentDisplayName} …"
            swiftDialogUpdate "listitem: index: $i, status: wait, statustext: Checking …"

        fi
        
        # Run Installomator
        ${installomatorScript} ${label} ${InstallomatorOptions} ${swiftDialogOptions[@]}
        if [ $? != 0 ]; then
            error "Error installing ${label}. Exit code $?"
            let errorCount++
        fi
        let i++
    done
    
    notice "Errors: $errorCount"
    
    # Close swiftdialog and delete tmp file
    completeSwiftDialogList
    
    # Remove Installomator
    removeInstallomator
    
    infoOut "Error Count $errorCount" 

}

oldIFS=$IFS
IFS=' '

queuedLabelsArray=("${(@s/ /)labelsArray}")    

if [[ ${#queuedLabelsArray[@]} -gt 0 ]]; then
    infoOut "Passing ${#queuedLabelsArray[@]} labels to Installomator: $queuedLabelsArray"
    doInstallations
else
    infoOut "All apps up to date. Nothing to do." # inbox zero
    removeInstallomator 
fi

IFS=$oldIFS

if [ "$errorCount" -gt 0 ]; then
    warning "Completed with $errorCount errors."
    removeInstallomator
else
    infoOut "Done."
    removeInstallomator
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# This is the end
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
quitScript
