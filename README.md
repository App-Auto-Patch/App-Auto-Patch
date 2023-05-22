# App Auto-Patch via Dialog
Auto patch management script for Jamf Pro via Dialog

This script will provide a user interface for updating applications installed on a Mac computer. The script will run a local discovery of all installed applications and use that information to process installations of those apps using the Installomator.sh script. 

Big shoutout to: @option8, @BigMacAdmin, and @dan-snelson! Thanks for all your help!


# Screenshots
App Auto-Patch running discovery:

<img width="652" alt="Screenshot 2023-05-18 at 9 57 34 AM" src="https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/dc32b13e-cf86-4ed7-a98c-5a33bb84dd7f">

App Auto-Patch running updates:

<img width="762" alt="Screenshot 2023-05-18 at 9 56 35 AM" src="https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/aa7cb284-ecbb-47fe-bff6-9214d5e562c4">

App Auto-Patch completed:

<img width="762" alt="Screenshot 2023-05-18 at 10 06 34 AM" src="https://github.com/robjschroeder/App-Auto-Patch/assets/23343243/847d4e9c-114a-4b5e-baab-b4d57db2987c">

# Why Build This
This script was built off the same idea as the Patchomator project where a majority of this code came from. A requirement for my use included an easily deployable script from Jamf Pro without having to install multiple dependancies on an end-user's computer. Originally this was a forked repo from Patchomator but has become it's own repo hosted here. 
This script can take an inventory of installed applications and patch them without having to build multiple Smart Groups, Policies, Patch Management Titles, etc in Jamf Pro. It is an easy way to keep your end-user's applications updated as easy as possible. 

# Usage
