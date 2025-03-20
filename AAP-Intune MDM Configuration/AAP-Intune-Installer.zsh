#!/bin/zsh --no-rcs

# This script will install App Auto-Patch by downloading the script from GitHub to a temporary location and running the script to perform the install
# This is necessary for deploying with Intune because of the way macOS scripts are run from Intune, leaving out necessary variables to self-install
# 
# https://github.com/App-Auto-Patch/App-Auto-Patch
# by Andrew Spokes (@TechTrekkie)
# 2025/03/09

# Path to the AAP working folder:
AAP_FOLDER="/Library/Management/AppAutoPatch"

# Path to the local property list file:
AAP_LOCAL_PLIST="${AAP_FOLDER}/xyz.techitout.appAutoPatch" # No trailing ".plist"

# Version to install:
INSTALL_VERSION="3.0.4"

# Hash of downloaded script for security reasons:
HASH_CHECK=bad8e82bc47d84839c6ceb79f1517f2f2a372dfba7f0de9cae7a51ba4f5ae1c9

# Temporary download folder
AAP_TEMP="/var/tmp/temp_aap"

#LaunchDaemon
appAutoPatchLaunchDaemonLabel="xyz.techitout.aap"

# Report if the AAP preference file exists.
if [[ -f "${AAP_FOLDER}/appautopatch" ]]; then
	if [[ -f "${AAP_LOCAL_PLIST}.plist" ]]; then
		AAP_version_local=$(defaults read "${AAP_LOCAL_PLIST}" AAPVersion 2> /dev/null)
		[[ $(echo "${AAP_version_local}" | cut -c 1) -lt 4 ]] && AAP_version_local=$(grep -m1 -e 'scriptVersion=' -e '  Version ' "${AAP_FOLDER}/appautopatch" | cut -d '"' -f 2 | cut -d " " -f 4)
		[[ -n "${AAP_version_local}" ]] && echo "<result>${AAP_version_local}</result>"
		[[ -z "${AAP_version_local}" ]] && echo "<result>No AAP version number found</result>"
	else
		echo "<result>No AAP preference file</result>"
		AAP_version_local="FALSE"
	fi
else
	echo "<result>Not installed</result>"
	AAP_version_local="FALSE"
fi


#Script to deploy App Auto-Patch in Microsoft Intune.

#Check for expected version
if [[ ${AAP_version_local} = "FALSE" ]]; then
	echo "No local version found to perform check, skipping"
	
elif [ $INSTALL_VERSION = ${AAP_version_local} ]; then
	exit 0
fi

#Download expected version
mkdir -p $AAP_TEMP && cd $_
curl -L -O https://raw.githubusercontent.com/App-Auto-Patch/App-Auto-Patch/$INSTALL_VERSION/App-Auto-Patch-via-Dialog.zsh

#Check the downloaded file against expected hash 
if ! echo "$HASH_CHECK  $AAP_TEMP/App-Auto-Patch-via-Dialog.zsh" | shasum -a 256 -c -; then
    echo "Checksum not matching or download failed" >&2
    exit 1
fi

#Install App Auto-Patch
chmod a+x $AAP_TEMP/App-Auto-Patch-via-Dialog.zsh
$AAP_TEMP/App-Auto-Patch-via-Dialog.zsh --reset-defaults --reset-labels

sleep 5
launchctl bootstrap system "/Library/LaunchDaemons/${appAutoPatchLaunchDaemonLabel}.plist" &
disown

rm -rf $AAP_TEMP

exit 0


