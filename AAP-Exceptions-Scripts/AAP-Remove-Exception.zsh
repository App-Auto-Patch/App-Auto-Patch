#!/bin/zsh

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Instructions:
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Copy this script into your Jamf instance. You will be using parameter 4 and 5. Although parameter
# 5 is optional and you can leave the default location for the exceptions list which is defined
# in the variable 'appAutoPatchExceptionsConfigFile'
# 
# Variables:
# exceptionsLabel: used to remove an entry from the exceptions plist. Enter the label the same way
# it is entered in the exception plist.
# 
# If the entry being removed is the last entry in the array then this script will take care of
# deleting the plist as well.
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

# Check if the file exists
if [[ ! -f "${appAutoPatchExceptionsConfigFile}" ]]; then
    echo "Error: Exceptions config file does not exist."
    exit 1
fi

# Function to check if the array is empty by counting elements and delete config file if it is
checkArraySize() {
    echo "Checking if the ExceptionsLabels array is empty."
    arraySize=$(xmllint --xpath "count(/plist/dict/key[text()='ExceptionsLabels']/following-sibling::array[1]/string)" "${appAutoPatchExceptionsConfigFile}")

    if [[ $arraySize -eq 0 ]]; then
        echo "Error: Exceptions array is empty."
        echo "Deleting $appAutoPatchExceptionsConfigFile"
        rm "${appAutoPatchExceptionsConfigFile}"
        exit 0
    else
        echo "Exceptions array is not empty."
        echo "Array size is $arraySize"
    fi
}

# Initial array size check
checkArraySize

# Escape asterisks in the exceptionsLabel for grep
escapedExceptionsLabel=$(echo "${exceptionsLabel}" | sed 's/\*/\\*/g')

# Find the index of the label to delete
index=$(/usr/libexec/PlistBuddy -c "Print :ExceptionsLabels" "${appAutoPatchExceptionsConfigFile}" | grep -n "^[ \t]*${escapedExceptionsLabel}$" | cut -d: -f1 | head -n 1)

# Check if the label was found
if [[ -z "${index}" ]]; then
    echo "Error: Label '${exceptionsLabel}' not found in the exceptions."
    exit 1
fi

# PlistBuddy uses 0-based indexing, and the grep output is 1-based, so we decrement the index by 1.
# However, grep registers an extra line because of the output, so we need to decrement by another 1.
# Thus, we decrement by 2 for correct indexing for PlistBuddy.
index=$(( index - 2 ))

# Delete the label from the array
/usr/libexec/PlistBuddy -c "Delete :ExceptionsLabels:${index}" "${appAutoPatchExceptionsConfigFile}"
echo "Removed label '${exceptionsLabel}' from exceptions."

# Convert the plist to XML format
/usr/bin/plutil -convert xml1 "${appAutoPatchExceptionsConfigFile}"
echo "Converted plist to XML format"

# Set full read permissions
/bin/chmod 644 "${appAutoPatchExceptionsConfigFile}"
echo "Set full read permissions"

# Final array size check after deletion
checkArraySize
