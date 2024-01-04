<!-- markdownlint-disable-next-line first-line-heading no-inline-html -->
[<img align="left" alt="App Auto Patch" src="Images/AAPLogo.png" width="128" />](https://techitout.xyz/app-auto-patch)

# App Auto-Patch via Dialog

![GitHub release (latest by date)](https://img.shields.io/github/v/release/robjschroeder/App-Auto-Patch?display_name=tag) ![GitHub issues](https://img.shields.io/github/issues-raw/robjschroeder/App-Auto-Patch) ![GitHub closed issues](https://img.shields.io/github/issues-closed-raw/robjschroeder/App-Auto-Patch) ![GitHub pull requests](https://img.shields.io/github/issues-pr-raw/robjschroeder/App-Auto-Patch) ![GitHub closed pull requests](https://img.shields.io/github/issues-pr-closed-raw/robjschroeder/App-Auto-Patch)

## Introduction
App Auto-Patch combines local application discovery, an Installomator integration, and user-friendly swiftDialog prompts to automate application patch management across Mac computers.

## Why Build This

App Auto-Patch was developed based on a similar concept as the Patchomator project, with a significant portion of its code borrowed from there. The main requirement for its use was to create a script deployable through Jamf Pro without the need for installing multiple dependencies on end-user computers. Since the original concept, it has since become an independent repository hosted here.

The script simplifies the process of taking an inventory of installed applications and patching them, eliminating the need for creating multiple Smart Groups, Policies, Patch Management Titles, etc., within Jamf Pro. It provides an easy solution for keeping end-users' applications updated with minimal effort.

This project has since been applied to MDMs outside of Jamf Pro, showcasing its versatility and adaptability. 

## Learn More

Please visit the [App Auto-Patch Wiki](https://github.com/robjschroeder/App-Auto-Patch/wiki) for detailed documentation!

Detailed `AAP` version progress can be found in the [Change Log](https://github.com/robjschroeder/App-Auto-Patch/blob/main/CHANGELOG.md).

You can also join the conversation at the [Mac Admins Foundation Slack](https://www.macadmins.org) in channel [#app-auto-patch](https://macadmins.slack.com/archives/C05D69E7SBH).

## Screenshots
App Auto-Patch running discovery:
![Screenshot 2023-10-30 at 11 56 15 AM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/5804c14a-b79c-45bf-b91e-2fc022077740)

App Auto-Patch running updates:
![Screenshot 2023-10-30 at 12 00 26 PM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/5de4a82d-cadd-4187-bd26-e27df0620af8)

App Auto-Patch Help Message:

![Screenshot 2023-10-30 at 12 00 37 PM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/7f5f8c77-4356-4e83-b547-d8affa8403d2)

App Auto-Patch completed:

![Screenshot 2023-10-30 at 12 03 07 PM](https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/b4e3ec8d-8c72-44c0-b57f-6f73c3dd62ab)

## Thank you
To everyone who has helped contribute to App Auto-Patch, including but not limited to:

- Dan Snelson ([@dan-snelson](https://github.com/dan-snelson))
- Andrew Spokes ([@TechTrekkie](https://github.com/TechTrekkie))
- Andrew Clarke ([@drtaru](https://github.com/drtaru))
- Andrew Barnett ([@andrewmbarnett](https://github.com/AndrewMBarnett))
- Trevor Sysock ([@bigmacadmin](https://github.com/bigmacadmin))
- Bart Reardon ([@bartreardon](https://github.com/bartreardon))
- Charles Mangin ([@option8](https://github.com/option8))
