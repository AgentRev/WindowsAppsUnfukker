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

1. Download and extract [PAExec](https://www.poweradmin.com/paexec/) to a folder.
2. Open CMD as admin (the real CMD, not PowerShell), then access that folder: `cd "PAEXEC_PATH_HERE"`
3. Adjust `FULL_PATH_HERE` and execute the script: <br>
   `paexec.exe -s -i powershell -ExecutionPolicy Bypass -File "FULL_PATH_HERE\WindowsAppsUnfukker.ps1" "%LocalAppData%"`

---
Note: If your objective is to modify files inside an app folder, I don't provide any assistance for that use-case, but there is an extra step required after running the script. You have to rename the app folder by adding `-old` at the end, make a copy of the folder, and rename the copy back to the original name. This will allow you to modify the files inside if they are not [encrypted](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/cipher). I don't why "Full control" permissions alone aren't sufficient, probably just [Microsoft eating a bag of dicks](https://www.youtube.com/watch?v=Gksc2aR2KCk) as usual.
