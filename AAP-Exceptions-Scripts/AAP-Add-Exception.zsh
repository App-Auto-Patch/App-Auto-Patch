#!/bin/zsh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Instructions:
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Copy this script into your Jamf instance. You will be using parameter 4 and 5. Although parameter
# 5 is optional and you can leave the default location for the exceptions list which is defined
# in the variable 'appAutoPatchExceptionsConfigFile'
# 
# Variables:
# exceptionsLabel: used to add an entry to the exceptions plist. You can also add labels using the
# wildcard version of the labels. For example, "1password*""
# 
# Enter only one label. This exception method is meant to be used as a single deployment to
# individual devices to exempt individual software. For example, if you have a security exemption
# and you need to stay on a version of Docker. You can use a policy deploying this script and add
# the Docker label to parameter 4 of the script parameters and then deploy the policy to the one
# device. If other exceptions already exist, this will take care of adding an additional entry
# to the array of exceptions for that individual device where the script ran.
# 
# appAutoPatchExceptionsConfigFile: the path where your exceptions list defined by you will be
# created. You can define your own location but you will need to make sure you also add that same
# path in the App-Auto-Patch-via-Sialog.zsh script for the variable "appAutoPatchExceptionsConfigFile"
# 
# The default location is the same across the App-Auto-Patch-via-Sialog.zsh, the 
# Remove-Exceptions.zsh and Add-Exception.zsh scripts so you don't really need to change it.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Assign the arguments with default values if not provided
exceptionsLabel="${4:=""}"
appAutoPatchExceptionsConfigFile="${5:="/Library/Application Support/AppAutoPatch/AppAutoPatchExceptions.plist"}"

# Check if the exceptionsLabel is provided
if [[ -z "${exceptionsLabel}" ]]; then
    echo "Error: No exception label provided."
    exit 1
fi

# Create the base array if the file does not exist
if [[ ! -f "${appAutoPatchExceptionsConfigFile}" ]]; then
    echo "Creating exceptions config file"
    /usr/bin/defaults write "${appAutoPatchExceptionsConfigFile}" ExceptionsLabels -array
else
    echo "Exceptions config file already exists"
fi

# Function to check if the exceptionsLabel is already in the array
function label_exists {
    # Escape asterisks in the exceptionsLabel for grep
    escapedExceptionsLabel=$(echo "${exceptionsLabel}" | sed 's/\*/\\*/g')

    # Find the index of the label to delete
    index=$(/usr/libexec/PlistBuddy -c "Print :ExceptionsLabels" "${appAutoPatchExceptionsConfigFile}" | grep -n "^[ \t]*${escapedExceptionsLabel}$" | cut -d: -f1 | head -n 1)

    # Check if the label was found
    if [[ -z "${index}" ]]; then
        # Return true because it exists
        return 1
    fi

    # Return false if it did not
    return 0
}

# Check if the label already exists in the array
if label_exists; then
    echo "Label ${exceptionsLabel} already exists in the exceptions list."
    exit 0
else
    # Add the new exception label
    /usr/bin/defaults write "${appAutoPatchExceptionsConfigFile}" ExceptionsLabels -array-add "${exceptionsLabel}"
    echo "Added ${exceptionsLabel} label to exceptions."
fi

# Convert the plist to XML format
/usr/bin/plutil -convert xml1 "${appAutoPatchExceptionsConfigFile}"
echo "Converted plist to XML format"

# Set full read permissions
/bin/chmod 644 "${appAutoPatchExceptionsConfigFile}"
echo "Set full read permissions"
