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
#   - Changed icon used for desktop computers to match platform (would like to grab model name and match accordingly: MacBook, Mac, Mac Mini, etc)
#   - Changed `discovery` variable to `runDiscovery`
#   - Changed repository to App-Auto-Patch and script name to App-Auto-Patch-via-Dialog.zsh
#
#   Version 1.0.10, 05.23.2023 Robert Schroeder (@robjschroeder)
#   - Moved the creation of the overlay icon in the IF statement if useoverlayicon is set to true
#
#   Version 1.0.11, 06.21.2023 Robert Schroeder (@robjschroeder)
#   - Added more options for running siliently (Issue #3, thanks @beatlemike)
#   - Commented out the Update count in List dialog infobox until accurate count can be used
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

scriptVersion="1.0.10"
scriptFunctionalName="App Auto-Patch"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

scriptLog="${4:-"/var/log/com.company.log"}"                                    # Parameter 4: Script Log Location [ /var/log/com.company.log ] (i.e., Your organization's default location for client-side logs)
useOverlayIcon="${5:="true"}"                                                   # Parameter 5: Toggles swiftDialog to use an overlay icon [ true (default) | false ]
interactiveMode="${6:="2"}"                                                     # Parameter 6: Interactive Mode [ 0 (Completely Silent) | 1 (Silent Discovery, Interactive Patching) | 2 (Full Interactive) ]
ignoredLabels="${7:=""}"                                                        # Parameter 7: A space-separated list of Installomator labels to ignore (i.e., "microsoftonedrive-rollingout zoomgov googlechromeenterprise nudge")
requiredLabels="${8:=""}"                                                       # Parameter 8: A space-separated list of required Installomator labels (i.e., "microsoftteams")
outdatedOsAction="${9:-"/System/Library/CoreServices/Software Update.app"}"     # Parameter 9: Outdated OS Action [ /System/Library/CoreServices/Software Update.app (default) | jamfselfservice://content?entity=policy&id=117&action=view ] (i.e., Jamf Pro Self Service policy ID for operating system ugprades)


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Various Feature Variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #


### Path variables ###

installomatorPath=("/usr/local/Installomator/Installomator.sh")
patchomatorPath="/usr/local/Installomator"
fragmentsPath=("$patchomatorPath/fragments")
dialogPath="/usr/local/bin/dialog"
dialogCommandFile=$(mktemp /var/tmp/dialog.patchomator.XXXXX)


### Configuration PLIST variables ###

runDiscovery="true"
patchomatorconfigFile=("/Library/Application Support/Patchomator/patchomator.plist")
declare -A configArray=()
ignoredLabelsArray=($(echo ${ignoredLabels}))
requiredLabelsArray=($(echo ${requiredLabels}))


### Installomator Options ###

BLOCKING_PROCESS_ACTION="prompt_user"
NOTIFY="silent"
LOGO="appstore"


### Set SwiftDialog Options. Quote your strings. Don't escape line breaks ###

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

dialogListConfigurationOptions=(
    --title "${scriptFunctionalName}"
    --message "Updating the following apps …"
    --commandfile "$dialogCommandFile"
    --moveable
    --button1text "Done"
    --button1disabled
    --height 450
    --width 650
    --position bottomright
    --progress
    --infotext "${scriptFunctionalName}: Version $scriptVersion"
    --liststyle compact
    --titlefont size=18
    --messagefont size=11
    --quitkey k
    --icon "$icon"
    --overlayicon "$overlayicon"
)

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



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Operating System, Computer Model Name, etc.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

osVersion=$( sw_vers -productVersion )
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
modelName=$( /usr/libexec/PlistBuddy -c 'Print :0:_items:0:machine_name' /dev/stdin <<< "$(system_profiler -xml SPHardwareDataType)" )
exitCode="0"


####################################################################################################
#
# Pre-flight Checks
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
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Current Logged-in User Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function currentLoggedInUser() {
    loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
    updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User: ${loggedInUser}"
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# ${scriptFunctionalName} (${scriptVersion})\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: This script must be run as root; exiting."
    exit 1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm Dock is running / user is at Desktop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
    updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are NOT running; pausing for 1 second"
    sleep 1
done

updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are running; proceeding …"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Operating System Version Big Sur or later
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    
# Since swiftDialog requires at least macOS 11 Big Sur, first confirm the major OS version
if [[ "${osMajorVersion}" -ge 11 ]] ; then
    
    updateScriptLog "PRE-FLIGHT CHECK: macOS ${osMajorVersion} installed; proceeding ..."
    
else
    
    # The Mac is running an operating system older than macOS 11 Big Sur; exit with error
    updateScriptLog "PRE-FLIGHT CHECK: swiftDialog requires at least macOS 11 Big Sur and this Mac is running ${osVersion} (${osBuild}), exiting with error."
    osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Big Sur (or newer), but found macOS '"${osVersion}"' ('"${osBuild}"').\r\r" with title "'${scriptFunctionalName}': Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
    updateScriptLog "PRE-FLIGHT CHECK: Executing /usr/bin/open '${outdatedOsAction}' …"
    su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
    exit 1

fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Ensure computer does not go to sleep (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Caffeinating this script (PID: $$)"
caffeinate -dimsu -w $$ &
scriptPID="$$"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Logged-in System Accounts
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Check for Logged-in System Accounts …"
currentLoggedInUser

counter="1"

until { [[ "${loggedInUser}" != "_mbsetupuser" ]] || [[ "${counter}" -gt "180" ]]; } && { [[ "${loggedInUser}" != "loginwindow" ]] || [[ "${counter}" -gt "30" ]]; } ; do
    
    updateScriptLog "PRE-FLIGHT CHECK: Logged-in User Counter: ${counter}"
    currentLoggedInUser
    sleep 2
    ((counter++))
    
done

loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | sed -E 's/^.*, // ; s/([^ ]*).*/\1/' | sed 's/\(.\{25\}\).*/\1…/' | awk '{print toupper(substr($0,1,1))substr($0,2)}' )
loggedInUserID=$( id -u "${loggedInUser}" )
updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User First Name: ${loggedInUserFirstname}"
updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User ID: ${loggedInUserID}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
    
    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"
    
    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
        
        updateScriptLog "PRE-FLIGHT CHECK: Dialog not found. Installing..."
        
        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )
        
        # Download the installer package
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"
        
        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
        
        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then
            
            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            dialogVersion=$( /usr/local/bin/dialog --version )
            updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version ${dialogVersion} installed; proceeding..."
            
        else
            
            # Display a so-called "simple" dialog if Team ID fails to validate
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "'${scriptFunctionalName}': Error" buttons {"Close"} with icon caution'
            exitCode="1"
            quitScript
            
        fi
        
        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"
        
    else
        
        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."
        
    fi
    
}

if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
    if [ ${interactiveMode} -gt 0 ]; then
        dialogCheck
    fi
else
    updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Complete"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# General Functions
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

caffExit () {
    updateScriptLog "${scriptFunctionalName}: De-caffeinate $scriptPID..."
    killProcess "caffeinate"
    exit 0
}

### Logging functions ###

makePath() {
    mkdir -p "$(sed 's/\(.*\)\/.*/\1/' <<< $1)" # && touch $1
    updateScriptLog "${scriptFunctionalName}: Path made: $1"
}

notice() {
        updateScriptLog "${scriptFunctionalName}: [NOTICE] $1"
}

infoOut() {
        updateScriptLog "${scriptFunctionalName}: [INFO] $1"
}

error() {
    updateScriptLog "${scriptFunctionalName}: [ERROR] $1"
    let errorCount++
}

warning() {
    updateScriptLog "${scriptFunctionalName}: [WARNING] $1"
    let errorCount++
}

fatal() {
    updateScriptLog "${scriptFunctionalName}: [FATAL ERROR] $1"
    exit 1
}

### Cleanup functions ###
removeInstallomator() {
    updateScriptLog "${scriptFunctionalName}: Removing Installomator..."
    rm -rf ${patchomatorPath}
}

# Kill a specified process (thanks, @grahampugh!)
function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        updateScriptLog "Attempting to terminate the '$process' process …"
        updateScriptLog "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            updateScriptLog "ERROR: '$process' could not be terminated."
        fi
    else
        updateScriptLog "The '$process' process isn't running."
    fi
}

quitScript() {
    updateScriptLog "QUIT SCRIPT: Exiting …"
    
    # Stop `caffeinate` process
    updateScriptLog "QUIT SCRIPT: De-caffeinate …"
    killProcess "caffeinate"
    
    # Remove overlayicon
    if [[ -e ${overlayicon} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${overlayicon} …"
        rm "${overlayicon}"
    fi
    
    # Remove welcomeCommandFile
    if [[ -e ${dialogCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${dialogCommandFile} …"
        rm "${dialogCommandFile}"
    fi
    
    exit 0
}

### swiftDialog Functions ###

swiftDialogCommand(){
    if [ ${interactiveMode} -gt 0 ]; then
        echo "$@" > "$dialogCommandFile"
        sleep .2
    fi
}

swiftDialogListWindow(){
    # If we are using SwiftDialog
    if [ ${interactiveMode} -ge 1 ]; then
        # Check if there's a valid logged in user:
        currentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
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
            currentDisplayName=$(sed -n '/# label descriptions/,$p' ${installomatorPath} | grep -i -A 50 "${label})" | grep -m 1 "name=" | sed 's/.*=//' | sed 's/"//g')
            if [ -n "$currentDisplayName" ]
            then
                displayNames+=("--listitem")
                displayNames+=(${currentDisplayName})
            fi
        done
        touch "$dialogCommandFile"
        # Create our running swiftDialog window
        $dialogPath \
        ${dialogListConfigurationOptions[@]} \
        ${displayNames[@]} \
        &
    fi
}

completeSwiftDialogList(){
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

swiftDialogWriteWindow(){
    # If we are using SwiftDialog
    touch "$dialogCommandFile"
    if [ ${interactiveMode} -gt 1 ]; then
        $dialogPath \
        ${dialogWriteConfigurationOptions[@]} \
        &
    fi
}

completeSwiftDialogWrite(){
    if [ ${interactiveMode} -gt 1 ]; then
        swiftDialogCommand "quit:"
        rm "$dialogCommandFile"
    fi
}

swiftDialogUpdate(){
    infoOut "Update swiftDialog: $1" 
    echo "$1" >> "$dialogCommandFile"
    # sleep 0.4
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Installomator
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

checkInstallomator() {
    
    # check for existence of Installomator to enable installation of updates
    notice "Checking for Installomator.sh at $installomatorPath"
    
    if ! [[ -f $installomatorPath ]]
    then
        warning "Installomator was not found at $installomatorPath"
        
        LatestInstallomator=$(curl --silent --fail "https://api.github.com/repos/Installomator/Installomator/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
        
        updateScriptLog "${scriptFunctionalName}: Attempting to download and install Installomator.sh at $installomatorPath"
        
        PKGurl=$(curl --silent --fail "https://api.github.com/repos/Installomator/Installomator/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")
        
        # Expected Team ID of the downloaded PKG
        expectedTeamID="JME5BW3F3R"
        
        tempDirectory=$( mktemp -d )
        notice "Created working directory '$tempDirectory'"
        
        # Download the installer package
        notice "Downloading Installomator package"
        curl --location --silent "$PKGurl" -o "$tempDirectory/Installomator.pkg" || fatal "Download failed."
        
        # Verify the download
        teamID=$(spctl -a -vv -t install "$tempDirectory/Installomator.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')
        notice "Team ID of downloaded package: $teamID"
        
        # Install the package, only if Team ID validates
        if [ "$expectedTeamID" = "$teamID" ]
        then
            notice "Package verified. Installing package Installomator.pkg"
            installer -pkg "$tempDirectory/Installomator.pkg" -target / || fatal "Installation failed. See /var/log/installer.log for details."
        else
            fatal "Package verification failed. TeamID does not match."
        fi
        
        # Remove the temporary working directory when done
        notice "Deleting working directory '$tempDirectory' and its contents"
        rm -Rf "$tempDirectory"
        
    else
        updateScriptLog "${scriptFunctionalName}: Installomator found, checking version..."
        if [ $($installomatorPath version | cut -d . -f 1) -lt 10 ]
        then
            fatal "Installomator is installed, but is out of date. Versions prior to 10.0 function unpredictably with Patchomator. You can probably update it by running sudo $installomatorPath installomator"
        fi
    fi    
    
}

checkInstallomator

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Check Installomator App Labels
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

downloadLatestLabels() {
    # gets the latest release version tarball.
    latestURL=$(curl -sSL -o - "https://api.github.com/repos/Installomator/Installomator/releases/latest" | grep tarball_url | awk '{gsub(/[",]/,"")}{print $2}') # remove quotes and comma from the returned string
    #eg "https://api.github.com/repos/Installomator/Installomator/tarball/v10.3"
    
    tarPath="$patchomatorPath/installomator.latest.tar.gz"
    
    updateScriptLog "${scriptFunctionalName}: Downloading ${latestURL} to ${tarPath}"
    
    curl -sSL -o "$tarPath" "$latestURL" || fatal "Unable to download. Check ${patchomatorPath} is writable or re-run as root."
    
    updateScriptLog "${scriptFunctionalName}: Extracting ${tarPath} into ${patchomatorPath}"
    tar -xz --include='*/fragments/*' -f "$tarPath" --strip-components 1 -C "$patchomatorPath" || fatal "Unable to extract ${tarPath}. Corrupt or incomplete download?"
    touch "${fragmentsPath}/labels/"
}

checkLabels() {
    notice "Looking for labels in ${fragmentsPath}/labels/"
    
    # use curl to get the labels - who needs git?
    if [[ ! -d "$fragmentsPath" ]]
    then
        if [[ -w "$patchomatorPath" ]]
        then
            infoOut "Package labels not present at $fragmentsPath. Attempting to download from https://github.com/installomator/"
            downloadLatestLabels
        else 
            fatal "Package labels not present and $patchomatorPath is not writable. Re-run patchomator with sudo to download and install them."
        fi
        
    else
        labelsAge=$((($(date +%s) - $(stat -t %s -f %m -- "$fragmentsPath/labels")) / 86400))
        
        if [[ $labelsAge -gt 30 ]]
        then
            if [[ -w "$patchomatorPath" ]]
            then
                warning "Package labels are out of date. Last updated ${labelsAge} days ago. Attempting to download from https://github.com/installomator/"
                downloadLatestLabels
            else
                fatal "Package labels are out of date. Last updated ${labelsAge} days ago. Re-run patchomator with sudo to update them."
                
            fi
            
        else 
            infoOut "Package labels installed. Last updated ${labelsAge} days ago."
        fi
    fi
    
}

checkLabels

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Discovery of installed applications
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

PgetAppVersion() {
    # renamed to avoid conflicts with Installomator version of the same function name.
    # pkgs contains a version number, then we don't have to search for an app
    if [[ $packageID != "" ]]; then
        
        appversion="$(pkgutil --pkg-info-plist ${packageID} 2>/dev/null | grep -A 1 pkg-version | tail -1 | sed -E 's/.*>([0-9.]*)<.*/\1/g')"
        
        if [[ $appversion != "" ]]; then
            notice "Label: $label_name"
            notice "--- found packageID $packageID installed"
            
            if [ ${interactiveMode} -gt 1 ]; then
                swiftDialogUpdate "progresstext: Located ${label_name}"
            fi
            
            InstalledLabelsArray+=( "$label_name" )
            
            return
        fi
    fi
    
    if [ -z "$appName" ]; then
        # when not given derive from name
        appName="$name.app"
    fi
    
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
            
            if [ ${interactiveMode} -gt 1 ]; then
                swiftDialogUpdate "message: Analyzing ${appName//.app/} ($appversion)"
            fi
            
            notice "Label: $label_name"
            notice "--- found app at $installedAppPath"
            
            # Is current app from App Store
            if [[ -d "$installedAppPath"/Contents/_MASReceipt ]]
            then
                notice "--- $appName is from App Store. Skipping."
                return
                # Check disambiguation?
                
            else
                verifyApp $installedAppPath
            fi
        fi
        
    fi
    
    
}

verifyApp() {
	
	appPath=$1
	notice "Verifying: $appPath"
	swiftDialogUpdate "progresstext: Verifying $appPath"
	
	# verify with spctl
	appVerify=$(spctl -a -vv "$appPath" 2>&1 )
	appVerifyStatus=$(echo $?)
	teamID=$(echo $appVerify | awk '/origin=/ {print $NF }' | tr -d '()' )
	
	if [[ $appVerifyStatus -ne 0 ]]
	then
		error "Error verifying $appPath"
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
				
				/usr/libexec/PlistBuddy -c "set \":${appPath}\" ${label_name}" "$patchomatorconfigFile"
			fi
		else
			
			configArray[$appPath]=$label_name

			/usr/libexec/PlistBuddy -c "add \":${appPath}\" string ${label_name}" "$patchomatorconfigFile"

		fi
	fi
	
	
	notice "--- Installed version: ${appversion}"
	
	[[ -n "$newversion" ]] && notice "--- Newest version: ${newversion}"
	
	if [[ "$appversion" == "$newversion" ]]
	then
		notice "--- Latest version installed."
	else
		queueLabel
	fi
	
}

queueLabel() {
    
    notice "Queueing $label_name"
    
    # add to queue if in install mode
    if [[ $installmode ]]
    then
        labelsArray+="$label_name "
        echo "$labelsArray"
    fi
    
}

if [[ "${runDiscovery}" == "true" ]]; then
notice "Re-run discovery of installed applications at $patchomatorconfigFile"
if [[ -f $patchomatorconfigFile ]]; then
    rm -f $patchomatorconfigFile
fi

notice "No config file at $patchomatorconfigFile. Running discovery."
# Call the bouncing progress SwiftDialog window
swiftDialogWriteWindow

notice "Writing Config"

infoOut "No config file at $patchomatorconfigFile. Creating one now."
makePath "$patchomatorconfigFile"


/usr/libexec/PlistBuddy -c "clear dict" "${patchomatorconfigFile}"
/usr/libexec/PlistBuddy -c 'add ":IgnoredLabels" array' "${patchomatorconfigFile}"
/usr/libexec/PlistBuddy -c 'add ":RequiredLabels" array' "${patchomatorconfigFile}"

# Populate Ingnored Labels
updateScriptLog "${scriptFunctionalName}: Attempting to populate ignored labels"
for ignoredLabel in "${ignoredLabelsArray[@]}"; do
    if [[ -f "${fragmentsPath}/labels/${ignoredLabel}.sh" ]]; then
        updateScriptLog "${scriptFunctionalName}: Writing ignored label $ignoredLabel to configuration plist"
        /usr/libexec/PlistBuddy -c "add \":IgnoredLabels:\" string \"${ignoredLabel}\"" "${patchomatorconfigFile}"
    else
        notice "No such label ${ignoredLabel}"
    fi
done

# Populate Required Labels
updateScriptLog "${scriptFunctionalName}: Attempting to populate required labels"
for requiredLabel in "${requiredLabelsArray[@]}"; do
    if [[ -f "${fragmentsPath}/labels/${requiredLabel}.sh" ]]; then
        updateScriptLog "${scriptFunctionalName}: Writing required label ${requiredLabel} to configuration plist"
        /usr/libexec/PlistBuddy -c "add \":RequiredLabels:\" string \"${requiredLabel}\"" "${patchomatorconfigFile}"
    else
        notice "No such label ${requiredLabel}"
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

# MOAR Functions! miscellaneous pieces referenced in the occasional label
# Needs to confirm that labels exist first.
source "$fragmentsPath/functions.sh"

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

labelsFromConfig=($(defaults read "$patchomatorconfigFile" | grep -e ';$' | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:]" | tr -s "[:space:]"))

ignoredLabelsFromConfig=($(defaults read "$patchomatorconfigFile" IgnoredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:]" | tr -s "[:space:]"))

requiredLabelsFromConfig=($(defaults read "$patchomatorconfigFile" RequiredLabels | awk '{printf "%s ",$NF}' | tr -c -d "[:alnum:][:space:]" | tr -s "[:space:]"))

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

updateScriptLog "${scriptFunctionalName}: Discovery of installed applications complete..."

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Perform installations from configuration plist
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

doInstallations() {
    
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
        updateScriptLog "Number of Updates: $queuedLabelsArrayLength"
        #swiftDialogUpdate "infobox: **Updates:** $queuedLabelsArrayLength"
    fi

    i=0
    for label in $queuedLabelsArray
    do
        updateScriptLog "${scriptFunctionalName}: Installing ${label}..."
        swiftDialogUpdate "progress: increment ${progressIncrementValue}"
        
        # Use built in swiftDialog Installomator integration options (if swiftDialog is being used)
        swiftDialogOptions=()
        if [ ${interactiveMode} -ge 1 ]; then
            swiftDialogOptions+=(DIALOG_CMD_FILE="\"${dialogCommandFile}\"")
            
            # Get the "name=" value from the current label and use it in our swiftDialog list
            currentDisplayName=$(sed -n '/# label descriptions/,$p' ${installomatorPath} | grep -i -A 50 "${label})" | grep -m 1 "name=" | sed 's/.*=//' | sed 's/"//g')
            # There are some weird \' shenanigans here because Installomator passes this through eval
            swiftDialogOptions+=(DIALOG_LIST_ITEM_NAME=\'"${currentDisplayName}"\')
            sleep .5

            swiftDialogUpdate "icon: /Applications/${currentDisplayName}.app"
            swiftDialogUpdate "progresstext: Checking ${currentDisplayName} …"
            swiftDialogUpdate "listitem: index: $i, status: wait, statustext: Checking …"

        fi
        
        # Run Installomator
        ${installomatorPath} ${label} ${InstallomatorOptions} ${swiftDialogOptions[@]}
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

    caffExit

}

oldIFS=$IFS
IFS=' '

queuedLabelsArray=("${(@s/ /)labelsArray}")    

if [[ ${#queuedLabelsArray[@]} > 0 ]]; then
    infoOut "Passing ${#queuedLabelsArray[@]} labels to Installomator: $queuedLabelsArray"
    doInstallations
else
    infoOut "All apps up to date. Nothing to do." # inbox zero
    removeInstallomator 
fi

exit 0

IFS=$oldIFS

if [ "$errorCount" -gt 0 ]; then
    updateScriptLog "${scriptFunctionalName}: Completed with $errorCount errors."
    removeInstallomator
else
    updateScriptLog  "${scriptFunctionalName}: Done."
    removeInstallomator
fi

exit 0
