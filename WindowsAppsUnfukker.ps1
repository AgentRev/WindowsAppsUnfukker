#
# WindowsAppsUnfukker v1.1
# by AgentRev
#
# This shitstain code needs to run on the SYSTEM account via PsExec. Get it here:
# https://docs.microsoft.com/en-us/sysinternals/downloads/pstools
#
# How to start the motherfukker:
# 1. Download PsTools from the link above and extract it a folder.
# 2. Open CMD as admin, then access that folder: cd "PSTOOLS_PATH_HERE"
# 3. Execute the script: psexec.exe -s -i powershell -ExecutionPolicy Bypass -File "FULL_PATH_HERE\WindowsAppsUnfukker.ps1"
#
# Ajust the bitch-ass variables below as needed.
# You can include secondary drives as well. For example: @("C:\Program Files\WindowsApps", "D:\WindowsApps")
#
# If you want to restore a backup, you must first open PowerShell with: psexec.exe -s -i powershell
# Then, for example: icacls "C:\Program Files" /restore "C:\Program Files\WindowsApps_20211109_221014.txt" /c /q 2>$null
#

$WinAppsPaths = @("C:\Program Files\WindowsApps")
$BackupExistingPerms = 1  # set to 1 to grab a backup before the unfukking

####################################################################################################

Write-Host
Write-Host "Welcome to the amazing WindowsApps Unfukker! Please sit tight!!" -ForegroundColor Green

$WinVer = [Environment]::OSVersion.Version

if (-not ($WinVer.Major -eq 10 -and $WinVer.Build -lt 22000))
{
	Write-Host
	Write-Warning "This script has only been tested on Windows 10. Cuntinue at your own risk!!" -WarningAction Inquire
}

if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -ne 'S-1-5-18')
{
	Write-Host
	Write-Host "Error: Not running as SYSTEM user!! Please start this script via PsExec." -ForegroundColor Red
	Write-Host
	pause
	exit 1
}

$WinAppsPaths = $WinAppsPaths | ForEach-Object { [Environment]::ExpandEnvironmentVariables($_).TrimEnd('\') }

foreach ($WinAppsPath in $WinAppsPaths)
{
	if (-not ((Test-Path $WinAppsPath -PathType Container) -and $((Get-Item $WinAppsPath -Force).Name -eq 'WindowsApps')))
	{
		Write-Host
		Write-Host 'Error: Folder does not exist or is not named "WindowsApps" you big dummy!!' -ForegroundColor Red
		Write-Host
		pause
		exit 1
	}
}

if ($BackupExistingPerms)
{
	Write-Host
	Write-Host "Backup of existing permissions..." -ForegroundColor Cyan

	$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'

	foreach ($WinAppsPath in $WinAppsPaths)
	{
		$BackupPath = Join-Path (Resolve-Path "$WinAppsPath\..").Path "WindowsApps_$Timestamp.txt"
		icacls $WinAppsPath /save $BackupPath /t /c /q 2>$null  # mutes junction errors
		Write-Host "Saved to $BackupPath"
	}
}

[Regex]$FirstParenthesis = '\('

foreach ($WinAppsPath in $WinAppsPaths)
{
	Write-Host
	Write-Host "Fixing WindowsApps permissions..." -ForegroundColor Cyan

	# Default ownership and permissions, courtesy of https://www.winhelponline.com/blog/windowsapps-folder-restore-default-permissions/
	$WinAppsDefaultPerms = 'O:S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464G:SYD:PAI(A;;FA;;;S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464)(A;OICIIO;GA;;;S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464)(A;;0x1200a9;;;S-1-15-3-1024-3635283841-2530182609-996808640-1887759898-3848208603-3313616867-983405619-2501854204)(A;OICIIO;GXGR;;;S-1-15-3-1024-3635283841-2530182609-996808640-1887759898-3848208603-3313616867-983405619-2501854204)(A;;FA;;;SY)(A;OICIIO;GA;;;SY)(A;CI;0x1200a9;;;BA)(A;OICI;0x1200a9;;;LS)(A;OICI;0x1200a9;;;NS)(A;OICI;0x1200a9;;;RC)(XA;;0x1200a9;;;BU;(Exists WIN://SYSAPPID))'

	$WinAppsACL = Get-Acl $WinAppsPath
	$WinAppsACL.SetSecurityDescriptorSddlForm($WinAppsDefaultPerms)

	# Grant ALL APPLICATION PACKAGES "Read & execute" for this folder, subfolders and files
	$GroupID = New-Object Security.Principal.SecurityIdentifier('S-1-15-2-1')
	$NewRule = New-Object Security.AccessControl.FileSystemAccessRule($GroupID, 'ReadAndExecute', 'ObjectInherit,ContainerInherit', 'None', 'Allow')
	$WinAppsACL.AddAccessRule($NewRule)

	# Grant Users "Read & execute" for subfolders and files only
	$GroupID = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-545')
	$NewRule = New-Object Security.AccessControl.FileSystemAccessRule($GroupID, 'ReadAndExecute', 'ObjectInherit,ContainerInherit', 'InheritOnly', 'Allow')
	$WinAppsACL.AddAccessRule($NewRule)

	# Grant Administrators "Full control" for this folder, subfolders and files
	$GroupID = New-Object Security.Principal.SecurityIdentifier('S-1-5-32-544')
	$NewRule = New-Object Security.AccessControl.FileSystemAccessRule($GroupID, 'FullControl', 'ObjectInherit,ContainerInherit', 'None', 'Allow')
	$WinAppsACL.AddAccessRule($NewRule)

	# Apply all of the above
	Set-Acl $WinAppsPath $WinAppsACL

	$DeepFixInheritance = 0

	# Checks if you disabled inheritance on the entire folder tree like dumbass me
	if (-not $DeepFixInheritance)
	{
		$AppxFolders = Get-ChildItem $WinAppsPath -Filter 'AppxMetadata' -Depth 1 -Directory -Force -Attributes !ReparsePoint  # ignores junctions

		# if inheritance is disabled
		if (($AppxFolders | Where-Object { (Get-Acl $_.FullName).AreAccessRulesProtected }).Count -gt 0)
		{
			$DeepFixInheritance = 1
		}
	}

	Write-Host

	if ($DeepFixInheritance)
	{
		Write-Host "Fixing WindowsApps folder tree inheritance, this could take a couple minutes..." -ForegroundColor Cyan
		icacls "$WinAppsPath\*" /inheritance:e /t /c /q 2>$null
	}
	else
	{
		Write-Host "Fixing WindowsApps subfolders inheritance..." -ForegroundColor Cyan
		icacls "$WinAppsPath\*" /inheritance:e /c /q 2>$null
	}

	Write-Host
	Write-Host "Fixing WindowsApps subfolders permissions..." -ForegroundColor Cyan

	# Get all app folder containers (they have no underscore in their name)
	$AppsFolders = Get-ChildItem $WinAppsPath -Exclude *_* -Directory -Force -Attributes !ReparsePoint
	$AppsFolders = @($WinAppsPath) + ($AppsFolders | ForEach-Object { $_.FullName })

	foreach ($AppsFolder in $AppsFolders)
	{
		# Get all app folders
		$AppFolders = Get-ChildItem $AppsFolder -Directory -Force -Attributes !ReparsePoint

		# Now, time to smear the bullshit
		foreach ($AppFolder in $AppFolders)
		{
			if ($AppFolder.Name -Match '(.+?_).*?_.*?_.*?_(\w+$|\w{1,13})')
			{
				$AppFolderPath = $AppFolder.FullName
				$AppFolderACL = Get-Acl $AppFolderPath

				# Grant Users "Read & execute" for this folder, subfolders and files with Microsoft's bullshit condition
				$MsBullshit = '(XA;OICI;0x1200a9;;;BU;(WIN://SYSAPPID Contains "{0}{1}"))' -f $Matches.1, $Matches.2

				if ($AppFolderACL.Sddl -NotMatch ([Regex]::Escape($MsBullshit)))
				{
					Write-Host "Fixing $AppFolderPath"
					$AppFolderSDDL = $FirstParenthesis.Replace($AppFolderACL.Sddl, "$MsBullshit(", 1)
					$AppFolderACL.SetSecurityDescriptorSddlForm($AppFolderSDDL)
					Set-Acl $AppFolderPath $AppFolderACL
				}
			}
		}
	}

	$WpSystem = Join-Path $WinAppsPath "..\WpSystem"

	# Fix WpSystem if it exists alongside WindowsApps (only present on secondary drives)
	if (Test-Path $WpSystem -PathType Container)
	{
		Write-Host
		Write-Host "Fixing WpSystem permissions..." -ForegroundColor Cyan

		# Grant ALL APPLICATION PACKAGES "Full control" for subfolders and files only
		icacls $WpSystem /grant "*S-1-15-2-1:(OI)(CI)(IO)(F)" /q

		# Grant Users "List folder contents" for this folder only
		icacls $WpSystem /grant "*S-1-5-32-545:(RX)" /q

		# Grant Administrators "Full control" for this folder, subfolders and files
		icacls $WpSystem /grant "*S-1-5-32-544:(OI)(CI)(F)" /q
	}
}

# Since we are on SYSTEM user, we cannot use environment variables to find AppData...
$Username = (Get-WMIObject Win32_ComputerSystem).UserName.Split('\')[-1]
$AppDataPackages = "C:\Users\$Username\AppData\Local\Packages"

Write-Host

if (Test-Path $AppDataPackages -PathType Container)
{
	Write-Host "Fixing AppData Packages permissions, this could take a couple minutes..." -ForegroundColor Cyan

	# Enable folder tree inheritance
	icacls $AppDataPackages /inheritance:e /t /c /q

	# Grant ALL APPLICATION PACKAGES "Full control" for this folder, subfolders and files
	icacls $AppDataPackages /grant "*S-1-15-2-1:(OI)(CI)(F)"
}
else
{
	Write-Warning "AppData Packages not found, please file a GitHub issue here:
https://github.com/AgentRev/WindowsAppsUnfukker/issues
Copy-paste this in the description: $AppDataPackages"
}

Write-Host
Write-Host "Unfukking finished!! (hopefully)"  -ForegroundColor Green
Write-Host
pause
