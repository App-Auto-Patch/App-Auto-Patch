# Exceptions for App Auto Patch

The exception workflow allows you to add individual labels into an exception list for App Auto Patch to ignore for specific devices. The normal method to ignore labels involves adding the list of labels to a variable but that is something that gets deployed to all devices. That will then make it so the labels in that list get ignored in every single device.

There are two scripts for you to use. One that adds labels to the exception list and another one that will remove labels from the exception list.

You will use a policy with the script as the payload and use parameter 4 to enter the label. The policy will only be scoped to the specific devices that need the exception for that label.

Add the two scripts in this folder to your Jamf server.

## Adding Labels To The Exception List for a Device
Create a policy with the Scripts and Maintenance payload.

Add the script `AAP-Add-Exception` script to your policy and enter the label you want to add in parameter 4.

You can add wildcards and the exception workflow will handle it. So like the example in the picture for `jamfconnect*`.

Scope this policy only to the individual devices that need this exception.

<p align="center">
  <img alt="App Auto Patch Add Exception" src="/Images/AAP-AddException.png" width="1100;"/>
</p>


## Removing Labels From The Exception List for a Device
Create a policy with the Scripts and Maintenance payload.

Add the script `AAP-Remove-Exception` script to your policy and enter the label you want to remove in parameter 4. It has to match the exact entry in the Exceptions Config file so make sure that is correct. Otherwise it will not remove it.

To remove a wild card entry make sure you include the asterisk the same way as when you added it. For example, `jamfconnect*` has to be entered to remove the wildcard entry you added with the other script.

Scope this policy only to the individual devices that need this exception removed.

<p align="center">
  <img alt="App Auto Patch Remove Exception" src="/Images/AAP-RemoveException.png" width="1100;"/>
</p>