# WindowsAppsUnfukker - [Download here](https://github.com/AgentRev/WindowsAppsUnfukker/archive/refs/heads/main.zip)

![The parameter is incorrect](https://i.imgur.com/ygnGtJE.png)

Are you getting "The parameter is incorrect" errors when trying to run apps? <br>
Are Microsoft Store, Xbox, and other apps refusing to open or install? <br>
Are you getting access denied errors with a bunch of apps? <br>
Then boy do I have a solution for you! <br/>

Use this script to whip WindowsApps into submission and finally get rid of these goddamn issues!

Seriously Microsoft, why the fuck is this crap so extremely convoluted?
I bet my ass some NTFS nerd creamed his pants at your office while building your steaming pile of permissions garbage.

Jesus Fucking Christ.

---
### How to start the motherfukker

1. Download and extract [PsTools](https://docs.microsoft.com/en-us/sysinternals/downloads/pstools) to a folder.
2. Open CMD as admin, then access that folder: `cd "PSTOOLS_PATH_HERE"`
3. Execute the script: <br>
   `psexec.exe -s -i powershell -ExecutionPolicy Bypass -File "FULL_PATH_HERE\WindowsAppsUnfukker.ps1"`
