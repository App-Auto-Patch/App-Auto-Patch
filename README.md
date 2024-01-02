# App Auto-Patch via Dialog

[<img_alt="App Auto-Patch" src="images/AAPLogo.png" width="128" />](https://techitout.xyz/app-auto-patch)

Auto patch management script for Jamf Pro via Dialog

![GitHub release (latest by date)](https://img.shields.io/github/v/release/robjschroeder/App-Auto-Patch?display_name=tag) ![GitHub issues](https://img.shields.io/github/issues-raw/robjschroeder/App-Auto-Patch) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/robjschroeder/App-Auto-Patch) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/robjschroeder/App-Auto-Patch) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/robjschroeder/App-Auto-Patch)

...Next up, creating wiki and updating documentation @robjschroeder 12.19.2023

This script will provide a user interface for updating applications installed on a Mac computer. The script will run a local discovery of all installed applications and use that information to process installations of those apps using the Installomator.sh script. 

Big shoutout to: @option8, @BigMacAdmin, and @dan-snelson! Thanks for all your help!


# Screenshots
App Auto-Patch running discovery:

![Screenshot 2023-10-30 at 11 56 15 AM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/5804c14a-b79c-45bf-b91e-2fc022077740)


App Auto-Patch running updates:

![Screenshot 2023-10-30 at 12 00 26 PM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/5de4a82d-cadd-4187-bd26-e27df0620af8)


App Auto-Patch Help Message:

![Screenshot 2023-10-30 at 12 00 37 PM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/7f5f8c77-4356-4e83-b547-d8affa8403d2)


App Auto-Patch completed:

![Screenshot 2023-10-30 at 12 03 07 PM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/b4e3ec8d-8c72-44c0-b57f-6f73c3dd62ab)


# Why Build This
This script was built off the same idea as the Patchomator project where a majority of this code came from. A requirement for my use included an easily deployable script from Jamf Pro without having to install multiple dependancies on an end-user's computer. Originally this was a forked repo from Patchomator but has become it's own repo hosted here. 
This script can take an inventory of installed applications and patch them without having to build multiple Smart Groups, Policies, Patch Management Titles, etc in Jamf Pro. It is an easy way to keep your end-user's applications updated as easy as possible. 

## Learn More

Please visit the [App Auto-Patch Wiki](https://github.com/robjschroeder/App-Auto-Patch/wiki) for detailed documentation! (Still in progress...)

Detailed `AAP` version progress can be found in the [Change Log](https://github.com/robjschroeder/App-Auto-Patch/blob/main/CHANGELOG.md).

You can also join the conversation at the [Mac Admins Foundation Slack](https://www.macadmins.org) in channel [#app-auto-patch](https://macadmins.slack.com/archives/C05D69E7SBH).
