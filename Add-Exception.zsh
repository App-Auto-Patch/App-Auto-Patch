#!/bin/zsh

exceptionsLabel="${4:="Esteve"}"
appAutoPatchExceptionsConfigFile="${5:="/Library/Application Support/AppAutoPatch/AppAutoPatchExceptions.plist"}"

# Create the base array if the file does not exist
if [[ ! -f "${appAutoPatchExceptionsConfigFile}" ]]; then
    echo "Creating exceptions config file"
    defaults write "${appAutoPatchExceptionsConfigFile%.plist}" ExceptionsLabels -array
else
    echo "Exceptions config file already exists"
fi
echo "Finished if statement"

# Add the new exception label
defaults write "${appAutoPatchExceptionsConfigFile%.plist}" ExceptionsLabels -array-add "${exceptionsLabel}"

# Convert the plist to XML format
plutil -convert xml1 "${appAutoPatchExceptionsConfigFile}"
echo "Converted plist to XML format"

# Set full read permissions
chmod 644 "${appAutoPatchExceptionsConfigFile}"
echo "Set full read permissions"
