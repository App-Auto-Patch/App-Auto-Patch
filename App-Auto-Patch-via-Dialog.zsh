#!/bin/zsh

####################################################################################################
#
# App Auto-Patch via swiftDialog
#
####################################################################################################
#
# HISTORY
#
#   Version 2.0.0, 12.19.2023 Robert Schroeder (@robjschroeder)
#   - **Breaking Change** for users of App Auto-Patch before `2.0.0`
#       - Removed the unattendExit variable out of Jamf Pro Script parameters, this is now under the ### Unattended Exit Options ###
#       - Moved the outdatedOsAction variable from Parameter 9 to Parameter 10 in Jamf Pro Script parameters
#   - Script cleanup and organization
#   - dialogInstall function called only if interactiveMode is greater than 0
#   - Added logic for AAP-Activator (thanks @TechTrekkie)
#   - Variable added for AAP-Activator logic under ### Deferral Options ###, please see documentation for more information
#   - Added optionalLabels array. Installomator labels listed in this array will first check to see if the app is installed. If installed, AAP will write the label to the required array. If the app is not installed, it will get skipped. 
#
#   Version 2.0.1, 12.20.2023 Robert Schroeder (@robjschroeder)
#   - **Breaking Change** for users of App Auto-Patch before `2.0.1`
#	    - Removed the scriptLog variable out of Jamf Pro Script parameters, this is now under the ### Script Log and General Behavior Options ###
#	    - Removed the debugMode variable out of Jamf Pro Script parameters, this is now under the ### Script Log and General Behavior Options ###
#	    - Removed the outdatedOSAction variable out of the Jamf Pro Script parameters, this is now under the ### Script Log and General Behavior Options ###
#	    - Removed the useOverlayIcon variable out of the Jamf Pro Script parameters, this is now under ### Overlay Icon ### in the Custom Branding, Overlay Icon, etc section
#   - Fixed issue with labels (#13), improving how regex handles app labels from Installomator
#   - Updated AAP Activator Flag to pull from config plist and automatically determine if being executed by AAP-Activator (thanks @TechTrekkie)
#   - Updated deferral reset logic to only update if maxDeferrals is not Disabled. Reset deferrals if remaining is higher than max (thanks @TechTrekkie)
#   - Updated deferral workflow to run removeInstallomator and quitScript triggers to mirror non-deferral workflow (thanks @TechTrekkie)
#   - Created installomatorOptions Parameter, which can be used to overwrite default installomator options
#   - Fixed Installomator appNewVersion curl URL
#   - Changed `removeInstallomator` default to false, this will keep AAP's Installomator folder present until Installomator has an update
#
#   Version 2.0.2, 01.02.2024 Robert Schroeder (@robjschroeder)
#   - **Breaking Change** for users of App Auto-Patch before `2.0.2`
#       - Check Jamf Pro Script Parameters before deploying version 2.0.1, we have re-organized them
#   - Replaced logic of checking app version for discovered apps
#   - Reduced output to logs outside of debug modes (thanks @dan-snelson)
#
#   Version 2.0.3, 01.02.2024 Robert Schroeder (@robjschroeder)
#   - App Auto-Patch will do an additional check with a debug version of Installomator to determine if an application that is installed needs an update
#
#   Version 2.0.4, 01.03.2024 Andrew Spokes (@TechTrekkie)
#   - Adjusting references of 'There is no newer version available' to 'same as installed' to fix debug check behavior for DMG/ZIP installomator labels
#
#   Version 2.0.5, 01.05.2024 Robert Schroeder (@robjschroeder)
#   - If `interactiveMode` is greater than 1 (set for Full Interactive), and AAP does not detect any app updates a dialog will be presented to the user letting them know. 
#
#   Version 2.0.6, 01.22.2024 Robert Schroeder (@robjschroeder)
#   - New feature, `convertAppsInHomeFolder`. If this variable is set to `true` and an app is found within the /Users/* directory, the app will be queued for installation into the default path and removed into from the /Users/* directory
#   - New feature, `ignoreAppsInHomeFolder`. If this variable is set to `true` apps found within the /Users/* directory will be ignored. If `false` an app discovered with an update will be queued and installed into the default directory. This may may lead to two version of the same app installed. (thanks @gilburns!) 
#
#   Version 2.0.7, 01.22.2024, Robert Schroeder (@robjschroeder)
#   - Added function to list application names needing to update to show users before updates are installed during the deferral window (thanks @AndrewMBarnett)
#   - Added text to explain the deferral timer during the deferall window
#   - Text displayed during the deferral period and no deferrals remaining changes depending on how many deferrals are left.
#   - Deferral window infobox text is now dynamic based on `deferralTimerAction`
#   - Adjusted size of deferral window based on deferrals remaining (thanks @TechTrekkie)
#
#   Version 2.0.8, 01.24.2024
#   - Fixed helpMessage variable for the deferral window so the helpmessage displays properly
#   - Added application list to deferral window when 0 deferrals remain to mirror behavior when deferrals greater than 0
#   - Updated infobox text to indicate "Updates will automatically install after the timer expires" when 0 deferrals remain
#
#   Version 2.8.1, 01.26.2024, Andrew Spokes (@TechTrekkie)
#   - Fixed the --moveable flags spelling so the dialog will be set to moveable properly
#
#   Version 2.9.0, 02.08.2024, Robert Schroeder (@robjschroeder)
#   - Updated minimum swiftDialog minimum to 2.4.0 (thanks @AndrewMBarnett)
#   - Added Teams and Slack webhook messaging functionality (thanks @AndrewMBarnett and @TechTrekkie)
#   - Use the `webhookEnabled` variable and webhook URLs to set this functionality
#   - Function for finding Jamf Pro URL for computer running AAP (thanks @AndrewMBarnett and @TechTrekkie)
#   - Added minimize windowbutton to let windows run and minimize to applicable dialogs
#   - Added script version number to help message (thanks @dan-snelson)
#
#   Version 2.9.1, 02.14.2024, Robert Schroeder (@robjschroeder)
#   - Fixed issue where compact list style was being used during update progress and increased font size
#   - Analyzing Apps window now shows app logos during discovery (thanks @dan-snelson)
#   - Removed all notes from script history previous to version 2.0.0, see changelog to reference any prior changes. 
#   - Updated jamfProComputerURL variable to a search by serial vs. running a recon to get JSS ID, an extra click but saves a recon (thanks @dan-snelson)
#   - Removed minimize windowbutton from the deferral dialog to avoid confusion from users mistakenly hiding the dialog (Thanks @TechTrekkie)
#   - Updated webhook JSON to utilize appTitle variable vs. direct App Auto-Patch name (thanks @Tech-Trekkie)
#
#   Version 2.9.2, 02.15.2024, Robert Schroeder (@robjschroeder)
#   - Fixed an issue that would cause a blank list to appear in the patching dialog if `runDiscovery` was set to `false`, a placeholder will be used for now
#   ** This issue was introduced in version 2.9.1 ** Issue #59
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

scriptVersion="2.9.2"
scriptFunctionalName="App Auto-Patch"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

interactiveMode="${4:="2"}"                                                     # Parameter 4: Interactive Mode [ 0 (Completely Silent) | 1 (Silent Discovery, Interactive Patching) | 2 (Full Interactive) (default) ]
ignoredLabels="${5:=""}"                                                        # Parameter 5: A space-separated list of Installomator labels to ignore (i.e., "microsoft* googlechrome* jamfconnect zoom* 1password* firefox* swiftdialog")
requiredLabels="${6:=""}"                                                       # Parameter 6: A space-separated list of required Installomator labels (i.e., "firefoxpkg_intl")
optionalLabels="${7:=""}"                                                       # Parameter 7: A space-separated list of optional Installomator labels (i.e., "renew") ** Does not support wildcards **
installomatorOptions="${8:-""}"    				                # Parameter 8: A space-separated list of options to override default Installomator options (i.e., BLOCKING_PROCESS_ACTION=prompt_user NOTIFY=silent LOGO=appstore)
maxDeferrals="${9:-"Disabled"}"                                                 # Parameter 9: Number of times a user is allowed to defer before being forced to install updates. A value of "Disabled" will not display the deferral prompt. [ `integer` | Disabled (default) ]

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Various Feature Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

### Script Log and General Behavior Options ###

scriptLog="/var/log/com.company.log"			                        # Script Log Location [ /var/log/com.company.log ] (i.e., Your organization's default location for client-side logs)
debugMode="false"				                                # Debug Mode [ true | false (default) | verbose ] Verbose adds additional logging, debug turns Installomator script to DEBUG 2, false for production
outdatedOsAction="/System/Library/CoreServices/Software Update.app"             # Outdated OS Action [ /System/Library/CoreServices/Software Update.app (default) | jamfselfservice://content?entity=policy&id=117&action=view ] (i.e., Jamf Pro Self Service policy ID for operating system upgrades)

### swiftDialog Options ###

swiftDialogMinimumRequiredVersion="2.4.0"					# Minimum version of swiftDialog required to use workflow

### Deferral Options ###

deferralTimer=300                                                               # Time given to the user to respond to deferral prompt if enabled
deferralTimerAction="Defer"                                                     # What happens when the deferral timer expires [ Defer | Continue ]
aapAutoPatchDeferralFile="/Library/Application Support/AppAutoPatch/AppAutoPatchDeferrals.plist"
AAPActivatorFlag=$(defaults read $aapAutoPatchDeferralFile AAPActivatorFlag)    # Flag to indicate if using AAPActivator to launch App Auto-Patch. AAP Activator will set this value to True prior to launching AAP

### Unattended Exit Options ###

unattendedExit="false"                              				# Unattended Exit [ true | false (default) ]
unattendedExitSeconds="60"							# Number of seconds to wait until a kill Dialog command is sent

### App Auto-Patch Path Variables ###

aapPath="/Library/Application Support/AppAutoPatch"
appAutoPatchConfigFile="/Library/Application Support/AppAutoPatch/AppAutoPatch.plist"
appAutoPatchStatusConfigFile="/Library/Application Support/AppAutoPatch/AppAutoPatchStatus.plist"
installomatorPath="/Library/Application Support/AppAutoPatch/Installomator"
installomatorScript="$installomatorPath/Installomator.sh"
fragmentsPath="$installomatorPath/fragments"

### App Auto-Patch Other Behavior Options ###

runDiscovery="true"                                                             # Re-run discovery of installed applications [ true (default) | false ]
removeInstallomatorPath="false"                                                 # Remove Installomator after App Auto-Patch is completed [ true | false (default) ]
convertAppsInHomeFolder="true"                                                  # Remove apps in /Users/* and install them to do default path [ true (default) | false ]
ignoreAppsInHomeFolder="false"                                                  # Ignore apps found in '/Users/*'. If an update is found in '/Users/*' and variable is set to `false`, the app will be updated into the application's default path [ true | false (default) ]

### Webhook Options ###

webhookEnabled="false"                                                          # Enables the webhook feature [ all | failures | false (default) ]
teamsURL=""                                                                     # Teams webhook URL                         
slackURL=""                                                                     # Slack webhook URL

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Custom Branding, Overlay Icon, etc
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

### App Title ###

# If you desire to customize `App Auto-Patch` to be named something else

appTitle="App Auto-Patch"

### Desktop/Laptop Icon ###

# Set icon based on whether the Mac is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
    icon="SF=laptopcomputer.and.arrow.down,weight=regular,colour1=gray,colour2=red"
else
    icon="SF=desktopcomputer.and.arrow.down,weight=regular,colour1=gray,colour2=red"
fi

### Overlay Icon ###

useOverlayIcon="true"								# Toggles swiftDialog to use an overlay icon [ true (default) | false ]

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
serialNumber=$( ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}' )
modelName=$( /usr/libexec/PlistBuddy -c 'Print :0:_items:0:machine_name' /dev/stdin <<< "$(system_profiler -xml SPHardwareDataType)" )

timestamp="$( date '+%Y-%m-%d-%H%M%S' )"
dialogVersion=$( /usr/local/bin/dialog --version )
exitCode="0"

jamfProURL=$(/usr/bin/defaults read /Library/Preferences/com.jamfsoftware.jamf.plist jss_url)
jamfProComputerURL="${jamfProURL}/computers.html?query=${serialNumber}&queryType=COMPUTERS"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# IT Support Variable (thanks, @AndrewMBarnett)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

### Support Team Details ###

supportTeamName="Add IT Support"
supportTeamPhone="Add IT Phone Number"
supportTeamEmail="Add email"
supportTeamWebsite="Add IT Help site"
supportTeamHyperlink="[${supportTeamWebsite}](https://${supportTeamWebsite})"

# Create the help message based on Support Team variables
helpMessage="If you need assistance, please contact ${supportTeamName}:  \n- **Telephone:** ${supportTeamPhone}  \n- **Email:** ${supportTeamEmail}  \n- **Help Website:** ${supportTeamHyperlink}  \n\n**Computer Information:**  \n- **Operating System:**  $osVersion ($osBuild)  \n- **Serial Number:** $serialNumber  \n- **Dialog:** $dialogVersion  \n- **Started:** $timestamp  \n- **Script Version:** $scriptVersion"

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
    
# Since swiftDialog and App Auto-Patch require at least macOS 12 Monterey, first confirm the major OS version
if [[ "${osMajorVersion}" -ge 12 ]] ; then
    preFlight "macOS ${osMajorVersion} installed; proceeding ..."
else
    # The Mac is running an operating system older than macOS 12 Monterey; exit with an error
    preFlight "swiftDialog and ${appTitle} require at least macOS 12 Monterey and this Mac is running ${osVersion} (${osBuild}), exiting with an error."
    osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Monterey (or newer), but found macOS '"${osVersion}"' ('"${osBuild}"').\r\r" with title "'"${scriptFunctionalName}"': Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
    preFlight "Executing /usr/bin/open '${outdatedOsAction}' …"
    su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
    exit 1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Ensure the computer does not go to sleep during AAP (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

aapPID="$$"
preFlight "Caffeinating this script (PID: $aapPID)"
caffeinate -dimsu -w $aapPID &

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate/install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #



function dialogInstall() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/swiftDialog/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    preFlight "Installing swiftDialog..."

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

if [ ${interactiveMode} -gt 0 ]; then
    notice "Interactive mode is greater than 0, checking for dialog"
    dialogCheck
else
    notice "Interactive mode is 0, no need to check for dialog, continuing ... "
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Declare configArray
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

preFlight "Declaring configArray and setting ignoredLabelsArray and requiredLabelsArray"

declare -A configArray=()
ignoredLabelsArray=($(echo ${ignoredLabels}))
requiredLabelsArray=($(echo ${requiredLabels}))
optionalLabelsArray=($(echo ${optionalLabels}))
convertedLabelsArray=($(echo ${convertedLabels}))

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Gather Error Log
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

installomatorLogFile="/var/log/Installomator.log"
duplicate_log_dir=$( mktemp -d /var/tmp/InstallomatorErrors.XXXXXX )
marker_file="/var/tmp/Installomator_marker.txt"

chmod 655 "$duplicate_log_dir" 

function createMarkerFile(){

if [ ! -f "$marker_file" ]; then
        preFlight "Marker file not found, creating temp marker file"
        touch "$marker_file"
        else
        preFlight "marker file exist, continuing"
     fi
}

function createLastErrorPosition() {
    
  # Create a timestamp for the current run
    timestamp=$(date +%Y%m%d%H%M%S)
    preFlight "Current time stamp: $timestamp"

    # Create a directory for duplicate log files if it doesn't exist
     if [ ! -d "$duplicate_log_dir" ]; then
        mkdir -p "$duplicate_log_dir"
        preFlight "Creating duplicate log file"
        else
        preFlight "Duplicate log directory exists, continuing"
     fi

     # Create a directory for duplicate log files if it doesn't exist
     if [ ! -f "$marker_file" ]; then
        preFlight "Marker file not found, creating temp marker file"
        touch "$marker_file"
        else
        preFlight "marker file exist, continuing"
     fi

    # Specify the duplicate log file with a timestamp
    duplicate_installomatorLogFile="$duplicate_log_dir/Installomator_error_$timestamp.log"
    preFlight "Duplicate Log File location: $duplicate_installomatorLogFile"

    # Find the last position marker or start from the beginning if not found
    if [ -f "$marker_file" && -f $installomatorLogFile ]; then
        lastPosition=$(cat "$marker_file")
    else 
        preFlight "Creating Installomator log file and setting error position as zero"
        touch "$installomatorLogFile"
        chmod 755 "$installomatorLogFile"
        lastPosition=0
    fi

    # Copy new entries from Installomator.log to the duplicate log file
    if [ -f "$installomatorLogFile" ]; then
        tail -n +$((lastPosition + 1)) "$installomatorLogFile" > "$duplicate_installomatorLogFile"
        preFlight "Installomator log file exists. Tailing new entries from log file to duplicate log file" 
    else 
        preFlight "Installomator log file not found. Creating now"
        checkInstallomator
    fi

    # Update the marker file with the new position
    wc -l "$installomatorLogFile" | awk '{print $1}' > "$marker_file"
    preFlight "Updating marker file"

    lastPosition=$(cat "$marker_file")
    preFlight "Last position: $lastPosition"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Checking Last Error Position
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function verifyLastPosition(){
 # Find the last position text in scriptLog
   lastPosition_line=$(tail -n 400 "$scriptLog" | grep 'Last position:' | tail -n 1)

    if [ -n "$lastPosition_line" ]; then
        # Extract the last position from the line
        lastPosition=$(echo "$lastPosition_line" | awk -F 'Last position:' '{print $2}' | tr -d '[:space:]')

        echo "$lastPosition" > "$marker_file"

        # Check if last position is less than or equal to zero
        if [[ ! -f "{$installomatorLogFile}" ]] || [[ "${lastPosition}" -le 0 ]]; then
            preFlight "Last position is less than one or Installomator log doesn't exist. Creating position."
            createLastErrorPosition
        else
            preFlight "Last position is greater than zero and Installomator log file exists. Continuing."
            lastPositionUpdated=$(cat "$marker_file")
            preFlight "Last position: $lastPositionUpdated"
        fi
    else
        preFlight "Last position not found. Setting it to zero and continuing."
        createLastErrorPosition
    fi
}

preFlight "Creating Marker file and checking if last error position exists"
createMarkerFile
verifyLastPosition


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

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reflect Debug Mode in `infotext` (i.e., bottom, left-hand corner of each dialog)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${debugMode} in
    "true"      ) infoTextScriptVersion="DEBUG MODE | Dialog: v${dialogVersion} • ${scriptFunctionalName}: v${scriptVersion}" ;;
    "verbose"   ) infoTextScriptVersion="VERBOSE DEBUG MODE | Dialog: v${dialogVersion} • ${scripFunctionalName}: v${scriptVersion}" ;;
    "false"     ) infoTextScriptVersion="${scriptVersion}" ;;
esac

####################################################################################################
#
# List dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "list" dialog Title, Message, and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogListConfigurationOptions=(
    --title "${appTitle}"
    --message "Updating the following apps …"
    --commandfile "$dialogCommandFile"
    --moveable
    --button1text "Done"
    --button1disabled
    --height 600
    --width 650
    --position bottomright
    --progress
    --helpmessage "$helpMessage"
    --infobox "#### Computer Name: #### \n\n $computerName \n\n #### macOS Version: #### \n\n $osVersion \n\n #### macOS Build: #### \n\n $osBuild \n\n "
    --infotext "${infoTextScriptVersion}"
    --windowbuttons min
    --titlefont size=18
    --messagefont size=14
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
    --title "${appTitle}"
    --message "Analyzing installed apps …"
    --icon "$icon"
    --overlayicon "$overlayicon"
    --commandfile "$dialogCommandFile"
    --moveable
    --windowbuttons min
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

function check_and_echo_errors() {


    # Create a timestamp for the current run
    timestamp=$(date +%Y%m%d%H%M%S)
    infoOut "Current time stamp: $timestamp"

     # Create a directory for duplicate log files if it doesn't exist
     if [ ! -d "$duplicate_log_dir" ]; then
        mkdir -p "$duplicate_log_dir"
        infoOut "Creating duplicate log file"
        else
        infoOut "Duplicate log directory exists, continuing"
     fi

    # Specify the duplicate log file with a timestamp
    duplicate_installomatorLogFile="$duplicate_log_dir/Installomator_error_$timestamp.log"
    infoOut "Duplicate Log File location: $duplicate_installomatorLogFile"

    # Find the last position marker or start from the beginning if not found
     if [ -f "$marker_file" ]; then
        lastPosition=$(cat "$marker_file")
    else 
        lastPosition=0
    fi

    # Copy new entries from Installomator.log to the duplicate log file
    tail -n +$((lastPosition + 1)) "$installomatorLogFile" > "$duplicate_installomatorLogFile"
    infoOut "tailing new entries from log file to duplicate log file" 

    # Update the marker file with the new position
    wc -l "$installomatorLogFile" | awk '{print $1}' > "$marker_file"
    infoOut "Updating marker file"

    lastPosition=$(cat "$marker_file")
    infoOut "Last position: $lastPosition"

    result=$(grep -a 'ERROR\s\+:\s\+\S\+\s\+:\s\+ERROR:' "$duplicate_installomatorLogFile" | awk -F 'ERROR :' '{print $2}')
    #infoOut "Install Error Result: $result"

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
    
    # Print the formatted result with bullet points in the infoOut message
    infoOut "Install Error Result: $formatted_error_result"

}

function appsUpToDate(){
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
    if [[ $errorsCount -le 0 && ! -n $appsUpToDate ]]; then
        infoOut "SUCCESS: Applications updates were installed with no errors"
        webhookStatus="Success, All Apps Up to Date"
        formatted_result=$(echo "$queuedLabelsArray")
        formatted_error_result="None"
    elif
        [[ $errorsCount -gt 0 && ! -n $appsUpToDate ]]; then
        infoOut "FAILURES DETECTED: Applications updates were installed with some errors"
        webhookStatus="Errors detected, some application patches failed with errors"
        formatted_result=$(echo "$queuedLabelsArray")
        check_and_echo_errors
    else
        infoOut "SUCCESS: Applications were all up to date, nothing to install"
        webhookStatus="Success, All Apps Up to Date and Nothing Installed"
        formatted_result="None"
        formatted_error_result="None"
    fi

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Remove Installomator
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function removeInstallomator() {

    if [[ "$removeInstallomatorPath" == "true" ]]; then
        infoOut "Removing Installomator..."
        rm -rf ${installomatorPath}
    else
        infoOut "Installomator removal set to false, continuing"
    fi

}

removeInstallomatorOutDated() {

    infoOut "Removing Installomator..."
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

function rm_if_exists()
{
    if [ -n "${1}" ] && [ -e "${1}" ];then
        /bin/rm -r "${1}"
    fi
}

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

    # Remove duplicate log file
    if [[ -d "${duplicate_log_dir}" ]]; then
        quitOut "Removing "${duplicate_log_dir}" …"
        rm_if_exists "${duplicate_log_dir}"
        else
        quitOut "Could not delete "${duplicate_log_dir}""

    fi

     # Remove Marker File
    if [[ -e ${marker_file} ]]; then
        quitOut "Removing ${marker_file} …"
        rm "${marker_file}"
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
        # Check if there's a valid logged-in user:
        currentUser=$(/usr/sbin/scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
        if [ "$currentUser" = "root" ] || [ "$currentUser" = "loginwindow" ] || [ "$currentUser" = "_mbsetupuser" ] || [ -z "$currentUser" ]; then
            return 0
        fi

        # Build our list of Display Names for the SwiftDialog list
        for label in $queuedLabelsArray; do
            # Get the "name=" value from the current label and use it in our SwiftDialog list
            currentDisplayName=$(sed -n '/# label descriptions/,$p' ${installomatorScript} | grep -i -A 50 "${label})" | grep -m 1 "name=" | sed 's/.*=//' | sed 's/"//g')
            if [ -n "$currentDisplayName" ]; then
                displayNames+=("--listitem")
                displayNames+=(${currentDisplayName},icon=SF=slowmo)
            fi
        done

        if [[ ! -f $dialogCommandFile ]]; then
            touch "$dialogCommandFile"
        fi

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

    debugVerbose "Update swiftDialog: $1" 
    echo "$1" >> "$dialogCommandFile"

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Create an AppAutoPatch folder, if it doesn't exist
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

infoOut "Checking for $aapPath"

if [ ! -d "${aapPath}" ]; then
	debugVerbose "$aapPath does not exist, create it now"
    mkdir "${aapPath}"
else
	debugVerbose "$aapPath already exists, continuing..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Installomator (thanks, @option8)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function checkInstallomator() {

    # The latest version of Installomator and collateral will be downloaded to $installomatorPath defined above
    # Does the $installomatorPath Exist or does it need to be created
    if [ ! -d "${installomatorPath}" ]; then
        debugVerbose "$installomatorPath does not exist, create it now"
        mkdir "${installomatorPath}"
    else
        debugVerbose "AAP Installomator directory exists"
    fi

    debugVerbose "Checking for Installomator.sh at $installomatorScript"
    
    if ! [[ -f $installomatorScript ]]; then
        warning "Installomator was not found at $installomatorScript"
        
        infoOut "Attempting to download Installomator.sh at $installomatorScript"

        latestURL=$(curl -sSL -o - "https://api.github.com/repos/Installomator/Installomator/releases/latest" | grep tarball_url | awk '{gsub(/[",]/,"")}{print $2}')

        tarPath="$installomatorPath/installomator.latest.tar.gz"

        debugVerbose "Downloading ${latestURL} to ${tarPath}"

        curl -sSL -o "$tarPath" "$latestURL" || fatal "Unable to download. Check ${installomatorPath} is writable, or that you haven't hit Github's API rate limit."

        debugVerbose "Extracting ${tarPath} into ${installomatorPath}"
        tar -xz -f "$tarPath" --strip-components 1 -C "$installomatorPath" || fatal "Unable to extract ${tarPath}. Corrupt or incomplete download?"
        
        sleep .2

        rm -rf $installomatorPath/*.tar.gz
    else
        notice "Installomator was found at $installomatorScript, checking version..."
        appNewVersion=$(curl -sLI "https://github.com/Installomator/Installomator/releases/latest" | grep -i "^location" | tr "/" "\n" | tail -1 | sed 's/[^0-9\.]//g')
        appVersion="$(cat $fragmentsPath/version.sh)"
        if [[ ${appVersion} -lt ${appNewVersion} ]]; then
            errorOut "Installomator is installed but is out of date. Versions before 10.0 function unpredictably with App Auto Patch."
            infoOut "Removing previously installed Installomator version ($appVersion) and reinstalling with the latest version ($appNewVersion)"
            removeInstallomatorOutDated
            sleep .2
            checkInstallomator
        else
            infoOut "Installomator latest version ($appVersion) installed, continuing..."
        fi
    fi

}

infoOut "Checking for Installomator Pre-Requisite"

checkInstallomator

# Set Installomator script to production
if [[ "$debugMode" == "true" ]]; then
    debug "Setting Installomator to Debug Mode"
    /usr/bin/sed -i.backup1 "s|DEBUG=1|DEBUG=2|g" $installomatorScript
    sleep .2
    /usr/bin/sed -i.backup1 "s|MacAdmins Slack)|MacAdmins Slack )|g" $installomatorScript
    sleep .2
    /usr/bin/sed -i.backup1 "s|There is no newer version available|same as installed|g" $installomatorScript
    sleep .2
else
    infoOut "Setting Installomator to Production Mode"
    /usr/bin/sed -i.backup1 "s|DEBUG=1|DEBUG=0|g" $installomatorScript
    sleep .2
    /usr/bin/sed -i.backup1 "s|MacAdmins Slack)|MacAdmins Slack )|g" $installomatorScript
    sleep .2
    /usr/bin/sed -i.backup1 "s|There is no newer version available|same as installed|g" $installomatorScript
    sleep .2
fi

infoOut "Installomator Pre-Requisite Complete"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Discovery of installed applications (thanks, @option8)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function PgetAppVersion() {

    if [[ $packageID != "" ]]; then
        
        appversion="$(pkgutil --pkg-info-plist ${packageID} 2>/dev/null | grep -A 1 pkg-version | tail -1 | sed -E 's/.*>([0-9.]*)<.*/\1/g')"
        
    fi
    
    if [ -z "$appName" ]; then
        appName="$name.app"
    fi
    
    debugVerbose "Searching for $appName"
    
    if [[ -d "/Applications/$appName" ]]; then
        applist="/Applications/$appName"
    elif [[ -d "/Applications/Utilities/$appName" ]]; then
        applist="/Applications/Utilities/$appName"
    else
        applist=$(mdfind "kMDItemFSName == '$appName' && kMDItemContentType == 'com.apple.application-bundle'" -0)
            if ([[ "$applist" == *"/Users/"* && "$convertAppsInHomeFolder" == "true" ]]); then
                debugVerbose "App found in User directory: $applist, coverting to default directory"
                # Adding the label to the converted labels
                /usr/libexec/PlistBuddy -c "add \":ConvertedLabels:\" string \"${label_name}\"" "${appAutoPatchConfigFile}"
                rm -rf $applist
            elif ([[ "$applist" == *"/Users/"* && "$ignoreAppsInHomeFolder" == "true" ]]); then
 		        debugVerbose "Ignoring user installed application: $applist"
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
            
            infoOut "Found $appName version $appversion"
            sleep .2
            
            if [ ${interactiveMode} -gt 1 ]; then
                if [[ "$debugMode" == "true" || "$debugMode" == "verbose" ]]; then
                    swiftDialogUpdate "message: Analyzing ${appName//.app/} ($appversion)"
                else
                    swiftDialogUpdate "message: Analyzing ${appName//.app/}"
                fi
            fi
            
            debugVerbose "Label: $label_name"
            debugVerbose "--- found app at $installedAppPath"
            
            # Is the current app from the App Store
            if [[ -d "$installedAppPath"/Contents/_MASReceipt ]]; then
                notice "--- $appName is from the App Store. Skipping."
                debugVerbose "Use the Installomator option \"IGNORE_APP_STORE_APPS=no\" to replace."
                return 
            else
                verifyApp $installedAppPath
            fi
        fi
    fi

}

function verifyApp() {
	
	appPath=$1
	debugVerbose "Verifying: $appPath"
    sleep .2
	swiftDialogUpdate "progresstext: $appPath"
    swiftDialogUpdate "icon: $appPath"
	
	# verify with spctl
	appVerify=$(spctl -a -vv "$appPath" 2>&1 )
	appVerifyStatus=$(echo $?)
	teamID=$(echo $appVerify | awk '/origin=/ {print $NF }' | tr -d '()' )
	
	if [[ $appVerifyStatus -ne 0 ]]; then
		error "Error verifying $appPath"
        error "Returned $appVerifyStatus"
		return
	fi
	
	if [ "$expectedTeamID" != "$teamID" ]; then
		error "Error verifying $appPath"
		warning "Team IDs do not match: expected: $expectedTeamID, found $teamID"
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

                notice "${appPath} already linked to label ${exists}, ignoring label ${label_name}"
                warning "Modify your ignored label list if you are not getting the desired results"

                return
            else
                configArray[$appPath]=$label_name

                appNewVersion=$( echo "${appNewVersion}" | sed 's/[^a-zA-Z0-9]*$//g' )
                previousVersion=$( echo "${appversion}" | sed 's/[^a-zA-Z0-9]*$//g' )
                previousVersionLong=$( echo "${appversionLong}" | sed 's/[^a-zA-Z0-9]*$//g' )

                # Compare version strings
                if [[ "$previousVersion" == "$appNewVersion" ]]; then
                    notice "--- Latest version installed."
                elif [[ "$previousVersionLong" == "$appNewVersion" ]]; then
                    notice "--- Latest version installed."
                else
                    # Lastly, verify with Installomator before queueing the label
                    if ${installomatorScript} ${label_name} DEBUG=2 NOTIFY="silent" BLOCKING_PROCESS_ACTION="ignore" | grep "same as installed" >/dev/null 2>&1
                    then
                        notice "--- Latest version installed."
                    else
                        notice "--- New version: ${appNewVersion}"
                        /usr/libexec/PlistBuddy -c "add \":${appPath}\" string ${label_name}" "$appAutoPatchConfigFile"
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
    
    notice "Queueing $label_name"

    labelsArray+="$label_name "
    debugVerbose "$labelsArray"
    
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# PLIST creation and population
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

infoOut "Checking for $appAutoPatchStatusConfigFile"

if [[ ! -f $appAutoPatchStatusConfigFile ]]; then
    debugVerbose "AAP Status configuration profile does not exist, creating now..."
    timestamp="$(date +"%Y-%m-%d %l:%M:%S +0000")"
    defaults write $appAutoPatchStatusConfigFile AAPVersion -string "$scriptVersion"
    defaults write $appAutoPatchStatusConfigFile AAPLastRun -date "$timestamp"
else
    debugVerbose "AAP Status configuration already exists, continuing..."
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
    /usr/libexec/PlistBuddy -c 'add ":OptionalLabels" array' "${appAutoPatchConfigFile}"
    /usr/libexec/PlistBuddy -c 'add ":ConvertedLabels" array' "${appAutoPatchConfigFile}"

    # Populate Ignored Labels
        infoOut "Attempting to populate ignored labels"
        for ignoredLabel in "${ignoredLabelsArray[@]}"; do
            if [[ -f "${fragmentsPath}/labels/${ignoredLabel}.sh" ]]; then
                debugVerbose "Writing ignored label $ignoredLabel to configuration plist"
                /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"${ignoredLabel}\"" "${appAutoPatchConfigFile}"
            else
                if [[ "${ignoredLabel}" == *"*"* ]]; then
                    debugVerbose "Ignoring all labels with $ignoredLabel"
                    wildIgnored=( $(find $fragmentsPath/labels -name "$ignoredLabel") )
                    for i in "${wildIgnored[@]}"; do
                        ignored=$( echo $i | cut -d'.' -f1 | sed 's@.*/@@' )
                        if [[ ! "$ignored" == "Application" ]]; then
                            debugVerbose "Writing ignored label $ignored to configuration plist"
                            /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"${ignored}\"" "${appAutoPatchConfigFile}"
                            ignoredLabelsArray+=($ignored)
                        else
                            sleep .1
                        fi
                    done 
                else
                    debugVerbose "No such label ${ignoredLabel}"
                fi
            fi
        done

        # Populate Required Labels
        infoOut "Attempting to populate required labels"
        for requiredLabel in "${requiredLabelsArray[@]}"; do
            if [[ -f "${fragmentsPath}/labels/${requiredLabel}.sh" ]]; then
                debugVerbose "Writing required label ${requiredLabel} to configuration plist"
                /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${requiredLabel}\"" "${appAutoPatchConfigFile}"
            else
                if [[ "${requiredLabel}" == *"*"* ]]; then
                    debugVerbose "Requiring all labels with $requiredLabel"
                    wildRequired=( $(find $fragmentsPath/labels -name "$requiredLabel") )
                    for i in "${wildRequired[@]}"; do
                        required=$( echo $i | cut -d'.' -f1 | sed 's@.*/@@' )
                        if [[ ! "$required" == "Application" ]]; then
                            debugVerbose "Writing required label $required to configuration plist"
                            /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${required}\"" "${appAutoPatchConfigFile}"
                            requiredLabelsArray+=($required)
                        else
                            sleep .1
                        fi
                    done
                else
                    debugVerbose "No such label ${requiredLabel}"
                fi
            fi
        done

        # Populate Optional Labels
        infoOut "Attempting to populate optional labels into labels array"
        for optionalLabel in "${optionalLabelsArray[@]}"; do
            if [[ -f "${fragmentsPath}/labels/${optionalLabel}.sh" ]]; then
                /usr/libexec/PlistBuddy -c "add \":OptionalLabels:\" string \"${optionalLabel}\"" "${appAutoPatchConfigFile}"
                if ${installomatorScript} ${optionalLabel} DEBUG=2 NOTIFY="silent" | grep "No previous app found" >/dev/null 2>&1
                then
                    notice "$optionalLabel is not installed, skipping ..."
                else
                    debugVerbose "Writing optional label ${optionalLabel} to required configuration plist"
                    /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${optionalLabel}\"" "${appAutoPatchConfigFile}"
                fi
            else
                debugVerbose "No such label ${optionalLabel}"
            fi
        done

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

    # Ignore swiftDialog as it should already be installed. This is to reduce issues re-downloading swiftDialog
    /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"swiftdialog\"" "${appAutoPatchConfigFile}"
    ignoredLabelsArray+=("swiftdialog")

    # for each .sh file in fragments/labels/ strip out the switch/case lines and any comments. 
    infoOut "Running discovery of installed applications"

    for labelFragment in "$fragmentsPath"/labels/*.sh; do 
        
        labelFile=$(basename -- "$labelFragment")
        labelFile="${labelFile%.*}"
        
        if [[ $ignoredLabelsArray =~ ${labelFile} ]]; then
            debugVerbose "Ignoring label $labelFile."
            continue
        fi
        
        exec 3< "${labelFragment}"
        
        while read -r -u 3 line; do 
            
            # Remove spaces and tabs
            scrubbedLine="$(echo $line | sed -E -e 's/^( |\t)*//g' -e 's/^\s*#.*$//')"
            
            if [ -n $scrubbedLine ]; then
                if [[ $in_label -eq 0 && "$scrubbedLine" =~ $label_re ]]; then
                    label_name=${match[1]}
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
    completeSwiftDialogWrite

fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set variables for various labels
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

labelsFromConfig=($(defaults read "$appAutoPatchConfigFile" | grep -e ';$' | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
ignoredLabelsFromConfig=($(defaults read "$appAutoPatchConfigFile" IgnoredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
requiredLabelsFromConfig=($(defaults read "$appAutoPatchConfigFile" RequiredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
optionalLabelsFromConfig=($(defaults read "$appAutoPatchConfigFile" OptionalLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
convertedLabelsFromConfig=($(defaults read "$appAutoPatchConfigFile" ConvertedLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:][\-_]" | tr -s "[:space:]"))
ignoredLabelsArray+=($ignoredLabelsFromConfig)
requiredLabelsArray+=($requiredLabelsFromConfig)
optionalLabelsArray+=($optionalLabelsFromConfig)
convertedLabelsArray+=($convertedLabelsFromConfig)
labelsArray+=($labelsFromConfig $requiredLabels $requiredLabelsFromConfig $convertedLabelsFromConfig)

# Deduplicate ignored labels
ignoredLabelsArray=($(tr ' ' '\n' <<< "${ignoredLabelsArray[@]}" | sort -u | tr '\n' ' '))

# Deduplicate required labels
requiredLabelsArray=($(tr ' ' '\n' <<< "${requiredLabelsArray[@]}" | sort -u | tr '\n' ' '))

# Deduplicate required labels
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
    debugVerbose "Obtaining proper name for $label"
    appName="$(grep "name=" "$fragmentsPath/labels/$label.sh" | sed 's/name=//' | sed 's/\"//g')"
    appName=$(echo $appName | sed -e 's/^[ \t]*//' )
    appNamesArray+=(--listitem "$appName")
done

notice "Labels to install: $labelsArray"
notice "Ignoring labels: $ignoredLabelsArray"
notice "Required labels: $requiredLabelsArray"
notice "Optional Labels: $optionalLabelsArray"
notice "Converted Labels: $convertedLabelsArray"

infoOut "Discovery of installed applications complete..."
warning "Some false positives may appear in labelsArray as they may not be able to determine a new app version based on the Installomator label for the app"
warning "Be sure to double-check the Installomator label for your app to verify"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete Installation Of Discovered Applications
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function doInstallations() {
    
    # Check for blank installomatorOptions variable
    if [[ -z $installomatorOptions ]]; then
        infoOut "Installomator options blank, setting to 'BLOCKING_PROCESS_ACTION=prompt_user NOTIFY=silent LOGO=appstore'"
        installomatorOptions="BLOCKING_PROCESS_ACTION=prompt_user NOTIFY=silent LOGO=appstore"
    fi

    infoOut "Installomator Options: $installomatorOptions"
    
    # Count errors
    errorCount=0

    # Create our main "list" swiftDialog Window
    swiftDialogListWindow
    
    if [ ${interactiveMode} -ge 1 ]; then
        sleep 1
        queuedLabelsArrayLength=$((${#countOfElementsArray[@]}))
        progressIncrementValue=$(( 100 / queuedLabelsArrayLength ))
	sleep 1
        swiftDialogUpdate "infobox: + **Updates:** $queuedLabelsArrayLength"
    fi

    i=0
    for label in $queuedLabelsArray; do
        infoOut "Installing ${label}..."
        
        # Use built-in swiftDialog Installomator integration options (if swiftDialog is being used)
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
            swiftDialogUpdate "listitem: index: $i, icon: /Applications/${currentDisplayName}.app, status: wait, statustext: Checking …"

        fi

        # Run Installomator
        ${installomatorScript} ${label} ${installomatorOptions} ${swiftDialogOptions[@]}
        if [ $? != 0 ]; then
            error "Error installing ${label}. Exit code $?"
            let errorCount++
        fi
        let i++
    done
    
    notice "Errors: $errorCount"
    
    # Close swiftdialog and delete the tmp file
    completeSwiftDialogList
    
    # Remove Installomator
    removeInstallomator
    
    infoOut "Error Count $errorCount" 

}

function checkDeferral() {
    
    if [[ $maxDeferrals == "Disabled" || $maxDeferrals == "disabled" ]]; then
        notice "Deferral workflow disabled, moving on to Installs"
    else
        if [[ ! -f $aapAutoPatchDeferralFile ]]; then
            echo "AAP Status configuration profile does  not exist, creating now..."
            defaults write $aapAutoPatchDeferralFile AAPDefaultDeferrals "$maxDeferrals"
        else
            echo "AAP Status configuration already exists, continuing..."
            defaults write $aapAutoPatchDeferralFile AAPDefaultDeferrals "$maxDeferrals"
        fi
    
        notice "Max Deferrals set to $maxDeferrals"
    
        ##Calculate remaining deferrals
        ##Check the Plist and find remaining deferrals from prior executions
        remainingDeferrals=$(defaults read $aapAutoPatchDeferralFile remainingDeferrals)
        ##Check that remainingDeferrals isn't empty (aka pulled back an empty value), if so set it to $maxDeferrals
        if [ -z $remainingDeferrals ]; then
            defaults write $aapAutoPatchDeferralFile remainingDeferrals $maxDeferrals
            remainingDeferrals=$maxDeferrals
            notice "Deferral has not yet been set. Setting to Max Deferral count."
        elif [[ $remainingDeferrals == "Disabled" || $remainingDeferrals == "disabled" || $remainingDeferrals -gt $maxDeferrals ]]; then
            defaults write $aapAutoPatchDeferralFile remainingDeferrals $maxDeferrals
            remainingDeferrals=$maxDeferrals
            notice "Deferral previously disabled or set to a higher value. Resetting to Max Deferral count"
        fi
        
        if [[ $remainingDeferrals -gt 0 ]]; then
            action=$( echo $deferralTimerAction | tr '[:upper:]' '[:lower:]' )
            infobuttontext="Defer"
            infobox="Updates will automatically $action after the timer expires. \n\n #### Deferrals Remaining: #### \n\n $remainingDeferrals"
            message="You can **Defer** the updates or **Continue** to close the applications and apply updates.  \n\n There are ($numberOfUpdates) application(s) that require updates: "
            height=480

            # Create the deferrals available dialog options and content
            deferralDialogContent=(
                --title "$appTitle"
                --message "$message"
                --helpmessage "$helpMessage"
                --icon "$icon"
                --overlayicon "$overlayicon"
                --infobuttontext "$infobuttontext"
                --infobox "$infobox"
                --timer $deferralTimer
                --button1text "Continue"
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


        else
            infobuttontext="Max Deferrals Reached"
            infobox="Updates will automatically install after the timer expires. \n\n #### No Deferrals Remaining ####"
            message="There are $numberOfUpdates application(s) that require updates\n\n You have $remainingDeferrals deferral(s) remaining."
            height=480

            # Create the deferrals available dialog options and content

            deferralDialogContent=(
                --title "$appTitle"
                --message "$message"
                --helpmessage "$helpMessage"
                --icon "$icon"
                --overlayicon "$overlayicon"
                --infotext "$infobuttontext"
                --infobox "$infobox"
                --timer $deferralTimer
                --button1text "Continue"
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

        fi
        
        
        notice "There are $remainingDeferrals deferrals left"

        
        
        "$dialogBinary" "${deferralDialogContent[@]}" "${deferralDialogOptions[@]}" "${appNamesArray[@]}"
        
        
        dialogOutput=$?
            
        if [[ $dialogOutput == 3 && $remainingDeferrals -gt 0 ]] ; then
            remainingDeferrals=$(( $remainingDeferrals - 1 ))
            defaults write $aapAutoPatchDeferralFile remainingDeferrals $remainingDeferrals
            notice "There are $remainingDeferrals deferrals left"
            if [[ "$AAPActivatorFlag" == 1 ]]; then
                infoOut "Setting AAPActivatorFlag to False"
                defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool false
            fi
            removeInstallomator
            quitScript
            exit 0
        elif [[ $dialogOutput == 4 && $remainingDeferrals -gt 0 ]] ; then
            if [[ $deferralTimerAction == "Defer" ]]; then
                notice "Timer expired and action set to Defer... Adjusting remaining deferrals"
                remainingDeferrals=$(( $remainingDeferrals - 1 ))
                defaults write $aapAutoPatchDeferralFile remainingDeferrals $remainingDeferrals
                notice "There are $remainingDeferrals deferrals left"
                if [[ "$AAPActivatorFlag" == 1 ]]; then
                    infoOut "Setting AAPActivatorFlag to False"
                    defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool false
                fi
                removeInstallomator
                quitScript
                exit 0
            else
                notice "Timer Expired and Action not set to Defer... Moving to the Installation step"
            fi 
        else
            notice "Moving to Installation step"
        fi

    fi

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Webhook Message (Microsoft Teams or Slack) 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function webHookMessage() {

if [[ $slackURL == "" ]]; then
    updateScriptLog "No slack URL configured"
else
    if [[ $supportTeamHyperlink == "" ]]; then
        supportTeamHyperlink="https://www.slack.com"
    fi
    updateScriptLog "Sending Slack WebHook"
    curl -s -X POST -H 'Content-type: application/json' \
        -d \
        '{
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
					"text": ">*Current User:*\n>'"$loggedInUser"'"
				},
				{
					"type": "mrkdwn",
					"text": ">*Application Install Labels:*\n>'"$formatted_result"'"
				},
				{
					"type": "mrkdwn",
					"text": ">*Application Install Errors:*\n>'"$formatted_error_result"'"
				},
                		{
					"type": "mrkdwn",
					"text": ">*Computer Record:*\n>'"$jamfProComputerURL"'"
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
						"text": "View computer in Jamf Pro",
						"emoji": true
					},
					"style": "primary",
					"action_id": "actionId-0",
					"url": "'"$jamfProComputerURL"'"
				}
			]
		}
	]
}' \
        $slackURL
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Teams notification (Credit to https://github.com/nirvanaboi10 for the Teams code)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $teamsURL == "" ]]; then
    updateScriptLog "No teams Webhook configured"
else
    if [[ $supportTeamHyperlink == "" ]]; then
        supportTeamHyperlink="https://www.microsoft.com/en-us/microsoft-teams/"
    fi
    updateScriptLog "Sending Teams WebHook"
    jsonPayload='{
	"@type": "MessageCard",
	"@context": "http://schema.org/extensions",
	"themeColor": "0076D7",
	"summary": "'${appTitle}': '${webhookStatus}'",
	"sections": [{
		"activityTitle": "'${appTitle}': '${webhookStatus}'",
		"activityImage": "https://usw2.ics.services.jamfcloud.com/icon/hash_2927020b3ba74fa8cf07c3304770a6276c6b1e95a2b87e8c4e8cb49c010763ed",
		"facts": [{
			"name": "Serial Number and Computer Name:",
			"value": "'"$serialNumber"' on '"$computerName"'"
		}, {
			"name": "Computer Model:",
			"value": "'"$modelName"'"
		}, {
			"name": "Current User:",
			"value": "'"$loggedInUser"'"
		}, {
			"name": "Application Install Labels:",
			"value": "'"$formatted_result"'"
        }, {
			"name": "Application Install Errors:",
			"value": "'"$formatted_error_result"'"
        }, {
			"name": "Computer Record:",
			"value": "'"$jamfProComputerURL"'"
		}],
		"markdown": true
	}],
	"potentialAction": [{
		"@type": "OpenUri",
		"name": "View Computer in Jamf Pro",
		"targets": [{
			"os": "default",
			"uri":
			"'"$jamfProComputerURL"'"
		}]
	}]
}'

    # Send the JSON payload using curl
    curl -s -X POST -H "Content-Type: application/json" -d "$jsonPayload" "$teamsURL"

fi

}


oldIFS=$IFS
IFS=' '

queuedLabelsArray=("${(@s/ /)labelsArray}")

for label in $queuedLabelsArray; do
countOfElementsArray+=($label)
done

if [[ ${#countOfElementsArray[@]} -gt 0 ]]; then
    numberOfUpdates=$((${#countOfElementsArray[@]}))
    checkDeferral
    updateScriptLog "----"
    notice "Passing ${numberOfUpdates} labels to Installomator: $queuedLabelsArray"
    updateScriptLog "----"
    doInstallations
    if [[ $maxDeferrals == "Disabled" || $maxDeferrals == "disabled" ]]; then
        infoOut "Installs Complete"
    else
        infoOut "Installs Complete... Resetting Deferrals"
        defaults write $aapAutoPatchDeferralFile remainingDeferrals $maxDeferrals
    fi

    #AAP-Activator - Setting weekly patching status to True
    if [[ "$AAPActivatorFlag" == 1 ]]; then
    infoOut "Setting Weekly Completion Status to True"
    defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool true
    defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool false
    fi
else
    infoOut "All apps are up to date. Nothing to do."

    # Send a dialog out if all apps are updated and interactiveMode is set
    if [ ${interactiveMode} -gt 1 ]; then
        $dialogBinary --title "$appTitle" --message "All apps are up to date." --windowbuttons min --icon "$icon" --overlayicon "$overlayIcon" --moveable --position topright --timer 60 --quitkey k --button1text "Close" --style "mini" --hidetimerbar
    fi


    #AAP-Activator - Setting weekly patching status to True
    if [[ "$AAPActivatorFlag" == 1 ]]; then
        infoOut "Setting Weekly Completion Status to True"
        defaults write $aapAutoPatchDeferralFile AAPWeeklyPatching -bool true
        defaults write $aapAutoPatchDeferralFile AAPActivatorFlag -bool false
    fi

    removeInstallomator 
fi

IFS=$oldIFS

if [ "$errorCount" -gt 0 ]; then
    warning "Completed with $errorCount errors."
    appsUpToDate
    if [[ ${webhookEnabled} == "false" ]]; then
        infoOut "Webhook Enabled flag set to: ${webhookEnabled}, skipping ..."
    elif [[ ${webhookEnabled} == "all" ]]; then
        infoOut "Webhook Enabled flag set to: ${webhookEnabled}, continuing ..."
        webHookMessage
    elif [[ ${webhookEnabled} == "failures" && ${errorCount} -gt 0 ]]; then
        infoOut "Webhook Enabled flag set to: ${webhookEnabled} with error count: ${errorCount}, continuing ..."
        webHookMessage
    else
        infoOut "Webhook Enabled flag set to: ${webhookEnabled}, but conditions not met for running webhookMessage."
    fi
    removeInstallomator
else
    infoOut "Done."
    appsUpToDate
    if [[ ${webhookEnabled} == "false" ]]; then
        infoOut "Webhook Enabled flag set to: ${webhookEnabled}, skipping ..."
    elif [[ ${webhookEnabled} == "all" ]]; then
        infoOut "Webhook Enabled flag set to: ${webhookEnabled}, continuing ..."
        webHookMessage
    elif [[ ${webhookEnabled} == "failures" && ${errorCount} -gt 0 ]]; then
        infoOut "Webhook Enabled flag set to: ${webhookEnabled} with error count: ${errorCount}, continuing ..."
        webHookMessage
    else
        infoOut "Webhook Enabled flag set to: ${webhookEnabled}, but conditions not met for running webhookMessage."
    fi
    removeInstallomator
fi

quitScript