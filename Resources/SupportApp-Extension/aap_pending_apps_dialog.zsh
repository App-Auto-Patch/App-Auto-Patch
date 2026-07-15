#!/bin/zsh --no-rcs

# Support App Extension - App Auto-Patch Pending Apps Dialog
#
# Shows a simplified swiftDialog list of currently pending updates (app icon,
# name, and a "Current Version / New Version" subtitle for each), with only
# "Install Now" and "Later" buttons - no deferral timer or menu, unlike App
# Auto-Patch's (AAP's) own deferral dialog. Clicking "Install Now" triggers
# `appautopatch --workflow-install-now` in the background; "Later" just
# closes the dialog.
#
# Reads pending items from AAP's report PLIST (xyz.techitout.appAutoPatchReport.plist)
# rather than running a fresh discovery scan, so this appears near-instantly.
# Also reads the same managed/local preferences AAP itself uses for
# DialogIcon, UseOverlayIcon, BannerImage/BannerTitle/BannerHeight, AppTitle,
# DialogOnTop, and the existing display_string_* language overrides (Managed
# Preferences only, matching AAP's own behavior), so this dialog's appearance
# and wording stay consistent with AAP's own dialogs without extra config.
#
# REQUIREMENTS:
# - App Auto-Patch 3.6.0 or later, installed with swiftDialog present
# - Deployed as a Privileged Script referenced by an Extension/Button item's
#   Action, via a Support App Configuration Profile (ActionType: PrivilegedScript)
# - Intended to replace aap_install_now.zsh as the pending-updates tile's
#   Action - clicking the tile now shows this dialog first, instead of
#   silently running --workflow-install-now immediately
#
# Optional customization: the "Later" button's text can be overridden via a
# new managed preference key, not part of AAP's own manifests:
#   <key>userInterface</key> -> <key>dialogElements</key> -> array of dicts,
#   each with <key>language</key> matching the user's locale (e.g. "en") and
#   <key>display_string_pendingapps_button_later</key> <string>Later</string>
# If not present, "Later" is used.

# ------------------    edit the variables below this line    ------------------

# Extension ID - must match the ExtensionID configured for the pending-updates
# Extension in the Support App Configuration Profile
extension_id="aap_pending_updates"

# App Auto-Patch install folder - only needs to change if you've customized
# AAP's default appAutoPatchFolder value
aapFolder="/Library/Management/AppAutoPatch"

# Path to the App Auto-Patch binary/symlink
appautopatch_bin="/usr/local/bin/appautopatch"

# Path to swiftDialog
dialogBinary="/usr/local/bin/dialog"

# Path to the companion script that refreshes the pending-updates count.
# Update this if you deploy aap_pending_updates.zsh to a different location.
refresh_script_path="/Library/Management/AppAutoPatch/SupportApp/aap_pending_updates.zsh"

# ---------------------    do not edit below this line    ----------------------

# Support App preference plist
preference_file_location="/Library/Preferences/nl.root3.support.plist"

# AAP's local/managed preference domains and report PLIST
aapReportPLIST="${aapFolder}/xyz.techitout.appAutoPatchReport.plist"
aapLocalPLIST="${aapFolder}/xyz.techitout.appAutoPatch"
aapManagedPLIST="/Library/Managed Preferences/xyz.techitout.appAutoPatch"
fragmentsPath="${aapFolder}/Installomator/fragments"
logoImage="${aapFolder}/AAPLogo.png"

if [[ ! -x "${dialogBinary}" ]]; then
    echo "ERROR: swiftDialog not found or not executable at ${dialogBinary}." >&2
    exit 1
fi

########################################
# Read pending items from AAP's report #
########################################

# Emits one tab-delimited line per queued item: label<TAB>displayName<TAB>installedVersion<TAB>newVersion
# Mirrors AAP's own get_aap_report_entries() function.
_get_pending_items() {
    [[ -f "${aapReportPLIST}" ]] || return 0
    /usr/libexec/PlistBuddy -c "Print :ItemsToInstall" "${aapReportPLIST}" 2> /dev/null | awk '
        /^    Dict \{/ { name = ""; disp = ""; inst = ""; nver = "" }
        /^        name = / { name = $0; sub(/^        name = /, "", name) }
        /^        display_name = / { disp = $0; sub(/^        display_name = /, "", disp) }
        /^        installed_version = / { inst = $0; sub(/^        installed_version = /, "", inst) }
        /^        version_to_install = / { nver = $0; sub(/^        version_to_install = /, "", nver) }
        /^    \}/ { if (name != "") printf "%s\t%s\t%s\t%s\n", name, disp, inst, nver }
    '
}

pendingItems=()
while IFS=$'\t' read -r _label _disp _inst _nver; do
    [[ -z "${_label}" ]] && continue
    pendingItems+=("${_label}"$'\t'"${_disp}"$'\t'"${_inst}"$'\t'"${_nver}")
done < <(_get_pending_items)

##########################################################
# Nothing pending - refresh the tile and exit, no dialog  #
##########################################################

if [[ ${#pendingItems[@]} -eq 0 ]]; then
    "${dialogBinary}" --title "App Auto-Patch" --message "You're all up to date!" --icon "${logoImage}" \
        --button1text "OK" --style "mini" --moveable --position topright --timer 15 --hidetimerbar &> /dev/null
    [[ -x "${refresh_script_path}" ]] && "${refresh_script_path}"
    exit 0
fi

##############################################################
# Read managed/local preferences AAP itself uses for dialogs  #
##############################################################

appTitle="App Auto-Patch"
dialogOnTop="FALSE"
useOverlayIcon="TRUE"
bannerImageOption=""
bannerTitleOption=""
bannerHeightOption=""
dialog_icon_option=""

app_title_managed=$(defaults read "${aapManagedPLIST}" AppTitle 2> /dev/null)
app_title_local=$(defaults read "${aapLocalPLIST}" AppTitle 2> /dev/null)
[[ -n "${app_title_managed}" ]] && appTitle="${app_title_managed}"
{ [[ -z "${app_title_managed}" ]] && [[ -n "${app_title_local}" ]]; } && appTitle="${app_title_local}"

dialog_on_top_managed=$(defaults read "${aapManagedPLIST}" DialogOnTop 2> /dev/null)
dialog_on_top_local=$(defaults read "${aapLocalPLIST}" DialogOnTop 2> /dev/null)
[[ -n "${dialog_on_top_managed}" ]] && dialogOnTop="${dialog_on_top_managed}"
{ [[ -z "${dialog_on_top_managed}" ]] && [[ -n "${dialog_on_top_local}" ]]; } && dialogOnTop="${dialog_on_top_local}"

use_overlay_icon_managed=$(defaults read "${aapManagedPLIST}" UseOverlayIcon 2> /dev/null)
use_overlay_icon_local=$(defaults read "${aapLocalPLIST}" UseOverlayIcon 2> /dev/null)
[[ -n "${use_overlay_icon_managed}" ]] && useOverlayIcon="${use_overlay_icon_managed}"
{ [[ -z "${use_overlay_icon_managed}" ]] && [[ -n "${use_overlay_icon_local}" ]]; } && useOverlayIcon="${use_overlay_icon_local}"

banner_image_managed=$(defaults read "${aapManagedPLIST}" BannerImage 2> /dev/null)
banner_image_local=$(defaults read "${aapLocalPLIST}" BannerImage 2> /dev/null)
[[ -n "${banner_image_managed}" ]] && bannerImageOption="${banner_image_managed}"
{ [[ -z "${banner_image_managed}" ]] && [[ -n "${banner_image_local}" ]]; } && bannerImageOption="${banner_image_local}"

banner_title_managed=$(defaults read "${aapManagedPLIST}" BannerTitle 2> /dev/null)
banner_title_local=$(defaults read "${aapLocalPLIST}" BannerTitle 2> /dev/null)
[[ -n "${banner_title_managed}" ]] && bannerTitleOption="${banner_title_managed}"
{ [[ -z "${banner_title_managed}" ]] && [[ -n "${banner_title_local}" ]]; } && bannerTitleOption="${banner_title_local}"

banner_height_managed=$(defaults read "${aapManagedPLIST}" BannerHeight 2> /dev/null)
banner_height_local=$(defaults read "${aapLocalPLIST}" BannerHeight 2> /dev/null)
[[ -n "${banner_height_managed}" ]] && bannerHeightOption="${banner_height_managed}"
{ [[ -z "${banner_height_managed}" ]] && [[ -n "${banner_height_local}" ]]; } && bannerHeightOption="${banner_height_local}"

dialog_icon_path_managed=$(defaults read "${aapManagedPLIST}" DialogIcon 2> /dev/null)
dialog_icon_path_local=$(defaults read "${aapLocalPLIST}" DialogIcon 2> /dev/null)
[[ -n "${dialog_icon_path_managed}" ]] && dialog_icon_option="${dialog_icon_path_managed}"
{ [[ -z "${dialog_icon_path_managed}" ]] && [[ -n "${dialog_icon_path_local}" ]]; } && dialog_icon_option="${dialog_icon_path_local}"

#####################################################################
# Language overrides - Managed Preferences only, matching AAP itself #
#####################################################################

display_string_there_are="The following"
display_string_deferral_message_02="**application(s)** require updates. \n\n"
display_string_deferral_button2="Install Now"
display_string_pendingapps_button_later="Later"
display_string_version_current="Current Version:"
display_string_version_new="New Version:"

currentUserAccountName=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ {$1=$2="";print $0;}' | xargs)
if [[ -n "${currentUserAccountName}" ]]; then
    langUser=$(su - "${currentUserAccountName}" -c "/usr/bin/defaults read -g AppleLocale | cut -d'_' -f1" 2> /dev/null)
fi

numElements=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements" "${aapManagedPLIST}.plist" 2> /dev/null | grep -c "Dict")
typeset -i numElements=$numElements
if [[ ${numElements} -gt 0 ]]; then
    for (( elements=0; elements<numElements; elements++ )); do
        lang="$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:language" "${aapManagedPLIST}.plist" 2> /dev/null)"
        if [[ "${lang}" == "${langUser}" ]]; then
            _v=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:display_string_there_are" "${aapManagedPLIST}.plist" 2> /dev/null)
            [[ -n "${_v}" ]] && display_string_there_are="${_v}"
            _v=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:display_string_deferral_message_02" "${aapManagedPLIST}.plist" 2> /dev/null)
            [[ -n "${_v}" ]] && display_string_deferral_message_02="${_v}"
            _v=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:display_string_deferral_button2" "${aapManagedPLIST}.plist" 2> /dev/null)
            [[ -n "${_v}" ]] && display_string_deferral_button2="${_v}"
            _v=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:display_string_pendingapps_button_later" "${aapManagedPLIST}.plist" 2> /dev/null)
            [[ -n "${_v}" ]] && display_string_pendingapps_button_later="${_v}"
            _v=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:display_string_version_current" "${aapManagedPLIST}.plist" 2> /dev/null)
            [[ -n "${_v}" ]] && display_string_version_current="${_v}"
            _v=$(/usr/libexec/PlistBuddy -c "Print :userInterface:dialogElements:${elements}:display_string_version_new" "${aapManagedPLIST}.plist" 2> /dev/null)
            [[ -n "${_v}" ]] && display_string_version_new="${_v}"
        fi
    done
fi

########################################################
# Icon / overlay icon / banner - mirrors AAP's own logic #
########################################################

if [[ -z "${dialog_icon_option}" ]]; then
    if system_profiler SPPowerDataType | grep -q "Battery Power"; then
        icon="SF=laptopcomputer.and.arrow.down,weight=regular,palette=gray,red"
    else
        icon="SF=desktopcomputer.and.arrow.down,weight=regular,palette=gray,red"
    fi
else
    icon="${dialog_icon_option}"
fi

dialogTitleOptions=()
if [[ -n "${bannerImageOption}" ]]; then
    dialogTitleOptions=(--bannerimage "${bannerImageOption}")
    if [[ -n "${bannerTitleOption}" ]]; then
        dialogTitleOptions+=(--bannertitle "${bannerTitleOption}")
    else
        dialogTitleOptions+=(--bannertitle "${appTitle}")
    fi
    [[ -n "${bannerHeightOption}" ]] && dialogTitleOptions+=(--bannerheight "${bannerHeightOption}")
else
    dialogTitleOptions=(--title "${appTitle}")
fi

overlayicon=""
if [[ "${useOverlayIcon}" == "TRUE" ]]; then
    rm -f /var/tmp/overlayicon.icns 2> /dev/null
    if [[ -n "$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path 2> /dev/null)" ]]; then
        xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
        overlayicon="/var/tmp/overlayicon.icns"
    elif [[ -n "$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_plus_path 2> /dev/null)" ]]; then
        xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf.plist self_service_plus_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
        overlayicon="/var/tmp/overlayicon.icns"
    elif [[ -e "/Library/Application Support/JAMF/Jamf.app" ]]; then
        overlayicon="/Library/Application Support/JAMF/Jamf.app/Contents/Resources/AppIcon.icns"
    elif [[ -e "/Applications/Self-Service.app" ]]; then
        overlayicon="/Applications/Self-Service.app/Contents/Resources/AppIcon.icns"
    elif [[ -e "/Applications/Manager.app" ]]; then
        overlayicon="/Applications/Manager.app/Contents/Resources/AppIcon.icns"
    elif [[ -e "/Library/Addigy/macmanage/MacManage.app" ]]; then
        overlayicon="/Library/Addigy/macmanage/MacManage.app/Contents/Resources/atom.icns"
    elif [[ "$(profiles show | grep -A4 "Management Profile" | sed -n -e 's/^.*profileIdentifier: //p')" == "Microsoft.Profiles.MDM" ]]; then
        if [[ -e "/Library/Intune/Microsoft Intune Agent.app" ]]; then
            overlayicon="/Library/Intune/Microsoft Intune Agent.app/Contents/Resources/AppIcon.icns"
        elif [[ -e "/Applications/Company Portal.app" ]]; then
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
fi

#####################################################################
# Resolve each pending item's icon and build the --listitem entries #
#####################################################################

# Mirrors AAP's own resolve_app_icon_path(): reads name/folderName/targetDir/appName from the
# label fragment (which may reference each other, e.g. appName="${folderName}/Foo.app"), so
# eval is used here the same way AAP itself does - fragmentsPath lives under AAP's root-owned
# install folder, not a location a non-root local user could tamper with.
_resolve_icon() {
    local label="$1"
    local name folderName targetDir appName
    local raw_name raw_folderName raw_targetDir raw_appName
    raw_name="$(awk -F\" '/^[[:space:]]*name=/{print $2; exit}' "${fragmentsPath}/labels/${label}.sh" 2> /dev/null)"
    raw_folderName="$(awk -F\" '/^[[:space:]]*folderName=/{print $2; exit}' "${fragmentsPath}/labels/${label}.sh" 2> /dev/null)"
    raw_targetDir="$(awk -F\" '/^[[:space:]]*targetDir=/{print $2; exit}' "${fragmentsPath}/labels/${label}.sh" 2> /dev/null)"
    raw_appName="$(awk -F\" '/^[[:space:]]*appName=/{print $2; exit}' "${fragmentsPath}/labels/${label}.sh" 2> /dev/null)"
    [[ -n "${raw_name}" ]] && eval "name=\"${raw_name}\""
    [[ -n "${raw_folderName}" ]] && eval "folderName=\"${raw_folderName}\""
    [[ -n "${raw_targetDir}" ]] && eval "targetDir=\"${raw_targetDir}\""
    [[ -n "${raw_appName}" ]] && eval "appName=\"${raw_appName}\""

    local icon_targetDir="${targetDir:-/}"
    local icon_appName
    if [[ -z "${appName}" ]]; then
        icon_appName="${name}.app"
    else
        icon_appName="${appName%.app}.app"
    fi

    if [[ -e "${icon_targetDir}${icon_appName}" ]]; then
        echo "${icon_targetDir}${icon_appName}"
    elif [[ -e "/Applications/${icon_appName}" ]]; then
        echo "/Applications/${icon_appName}"
    elif [[ -e "/Applications/Utilities/${icon_appName}" ]]; then
        echo "/Applications/Utilities/${icon_appName}"
    else
        local icon_path
        icon_path=$(mdfind "kMDItemFSName == '${icon_appName}' && kMDItemContentType == 'com.apple.application-bundle'" -0 2> /dev/null)
        if [[ -n "${icon_path}" && -e "${icon_path}" ]]; then
            echo "${icon_path}"
        else
            echo "${logoImage}"
        fi
    fi
}

appNamesArray=()
for item in "${pendingItems[@]}"; do
    IFS=$'\t' read -r _label _disp _inst _nver <<< "${item}"
    [[ -z "${_disp}" ]] && _disp="${_label}"

    iconPath=$(_resolve_icon "${_label}")

    _cur="${_inst//,/}"
    _new="${_nver//,/}"
    if [[ -n "${_cur}" ]] && [[ -n "${_new}" ]]; then
        versionSubtitle="${display_string_version_current} ${_cur}  →  ${display_string_version_new} ${_new}"
    elif [[ -n "${_new}" ]]; then
        versionSubtitle="${display_string_version_new} ${_new}"
    elif [[ -n "${_cur}" ]]; then
        versionSubtitle="${display_string_version_current} ${_cur}"
    else
        versionSubtitle=""
    fi

    appNamesArray+=("--listitem")
    if [[ -n "${versionSubtitle}" ]]; then
        appNamesArray+=("${_disp},icon=${iconPath},subtitle=${versionSubtitle}")
    else
        appNamesArray+=("${_disp},icon=${iconPath}")
    fi
done

##############################
# Build and show the dialog  #
##############################

numberOfUpdates=${#pendingItems[@]}
message="${display_string_there_are} **(${numberOfUpdates})** ${display_string_deferral_message_02}"

pendingDialogOptions=(
    ${dialogTitleOptions[@]}
    --message "${message}"
    --icon "${icon}"
    --overlayicon "${overlayicon}"
    --button1text "${display_string_pendingapps_button_later}"
    --button2text "${display_string_deferral_button2}"
    --position bottomright
    --height 500
    --width 600
    --moveable
    --titlefont size=18
    --messagefont size=14
)

[[ "${dialogOnTop}" == "TRUE" ]] && pendingDialogOptions+=(--ontop)

"${dialogBinary}" "${pendingDialogOptions[@]}" "${appNamesArray[@]}"
dialogOutput=$?

##############################
# Handle the user's response #
##############################

if [[ ${dialogOutput} -eq 2 ]]; then
    # Install Now (button2) - kick off the install-now workflow in the background so this
    # script (and the Support App popover) isn't left waiting on the full patch run, then
    # refresh the tile immediately. The tile will show a stale count until the run finishes
    # and AAP's own dialogs (if any apps are still open) take over from here.
    defaults write "${preference_file_location}" "${extension_id}_loading" -bool true
    defaults write "${preference_file_location}" "${extension_id}" -string "Installing Updates…"
    if [[ -x "${appautopatch_bin}" ]]; then
        "${appautopatch_bin}" --workflow-install-now &
        disown
    else
        echo "ERROR: ${appautopatch_bin} not found or not executable." >&2
    fi
fi

# Refresh the pending-updates count either way ("Later", dismissed, or Install Now just
# kicked off above) so the tile reflects the current state.
if [[ -x "${refresh_script_path}" ]]; then
    "${refresh_script_path}"
else
    echo "ERROR: ${refresh_script_path} not found or not executable." >&2
    defaults write "${preference_file_location}" "${extension_id}_loading" -bool false
fi
