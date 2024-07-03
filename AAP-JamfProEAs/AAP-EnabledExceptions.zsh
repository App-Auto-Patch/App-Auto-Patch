#!/bin/zsh

# Path to the plist file. This is the default location on the scripts for AAP
appAutoPatchExceptionsConfigFile="/Library/Application Support/AppAutoPatch/AppAutoPatchExceptions.plist"

# Check if the file exists
if [[ ! -f "${appAutoPatchExceptionsConfigFile}" ]]; then
    # If the file does not exist there are no exceptions enabled on the device
    echo "<result>None</result>"
else
    # Check if the array is empty if the file does exist
    arraySize=$(xmllint --xpath "count(/plist/dict/key[text()='ExceptionsLabels']/following-sibling::array[1]/string)" "${appAutoPatchExceptionsConfigFile}")

    if [[ $arraySize -eq 0 ]]; then
        # If the array is empty then there are no exceptions enabled on the device
        # Additionally, a device should never really have this state because when you remove a label and
        # it was the last one left in the array, the removal script takes care of also removing the file defined by appAutoPatchExceptionsConfigFile
        # unless you changed the default location.
        echo "<result>None</result>"
    else
        # If the array is not empty then we ouput what is in the array
        # Extract the array contents and store them in an array
        exceptionsLabelsArray=($(plutil -convert xml1 -o - "$appAutoPatchExceptionsConfigFile" | xmllint --xpath "//dict[key='ExceptionsLabels']/array/string/text()" - 2>/dev/null))

        # Join array elements into a single string with newlines
        exceptions=$(printf "%s\n" "${exceptionsLabelsArray[@]}")

        # Print the output
        echo "<result>$exceptions</result>"
    fi
fi

