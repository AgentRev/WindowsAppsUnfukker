#
# WindowsAppsUnfukker v1.2
# by AgentRev
#
# This shitstain code needs to run on the SYSTEM account via PAExec. Get it here:
# https://www.poweradmin.com/paexec/
#
# How to start the motherfukker:
# 1. Download PAExec from the link above.
# 2. Open CMD as admin (the real CMD, not PowerShell), then access that folder: cd "PAEXEC_PATH_HERE"
# 3. Adjust "FULL_PATH_HERE" and execute the script: paexec.exe -s -i powershell -ExecutionPolicy Bypass -File "FULL_PATH_HERE\WindowsAppsUnfukker.ps1" "%LocalAppData%"
#
# Ajust the bitch-ass variables below as needed.
# You can include secondary drives as well. For example: @("C:\Program Files\WindowsApps", "D:\WindowsApps")
#
# If you want to restore a backup, you must first open PowerShell with: psexec.exe -s -i powershell
# Then, for example: icacls "C:\Program Files" /restore "C:\Program Files\WindowsApps_20211109_221014.txt" /c /q 2>$null
#

$WinAppsPaths = @("%SystemDrive%\Program Files\WindowsApps")
$BackupExistingPerms = 1  # set to 1 to grab a backup before the unfukking

####################################################################################################

Write-Host
Write-Host "Welcome to the amazing WindowsApps Unfukker! Please sit tight!!" -ForegroundColor Green

if ([Environment]::OSVersion.Version.Major -ne 10)
{
	Write-Host
	Write-Warning "This script has only been tested on Windows 10 and 11. Cuntinue at your own risk!!" -WarningAction Inquire
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

function DoBackupExistingPerms($AppsPath)
{
	if (-not $BackupExistingPerms) { return }

	Write-Host "Backup of existing permissions..."

	$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
	$BackupPath = Join-Path (Resolve-Path "$AppsPath\..").Path ((Get-Item $AppsPath -Force).Name + "_$Timestamp.txt")
	icacls $AppsPath /save $BackupPath /t /c /q 2>$null  # mutes junction errors

	Write-Host "Saved to $BackupPath"
}

[Regex]$FirstParenthesis = '\('

foreach ($WinAppsPath in $WinAppsPaths)
{
	Write-Host
	Write-Host "Fixing WindowsApps permissions..." -ForegroundColor Cyan
	DoBackupExistingPerms($WinAppsPath)

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
			if ($AppFolder.Name -Match '(.+?_).*?_.*?_.*?_([a-zA-Z0-9]+)')
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
		DoBackupExistingPerms($WpSystem)

		# Grant ALL APPLICATION PACKAGES "Full control" for subfolders and files only
		icacls $WpSystem /grant "*S-1-15-2-1:(OI)(CI)(IO)(F)" /q

		# Grant Users "List folder contents" for this folder only
		icacls $WpSystem /grant "*S-1-5-32-545:(RX)" /q

		# Grant Administrators "Full control" for this folder, subfolders and files
		icacls $WpSystem /grant "*S-1-5-32-544:(OI)(CI)(F)" /q
	}
}


# Fix AppData Packages

$AppDataPackages = ""
$C = $Env:SystemDrive

if ($args) # command line args
{
	$AppDataPackages = $args[0] + "\Packages"
}
else
{
	# Since we are on SYSTEM user, we cannot use environment variables to find AppData...
	$Username = (Get-WMIObject Win32_ComputerSystem).UserName.Split('\')[-1]
	$AppDataPackages = "${C}\Users\$Username\AppData\Local\Packages"
}

function DoAppDataPackages
{
	Write-Host
	Write-Host "Fixing AppData Packages permissions, this could take a couple minutes..." -ForegroundColor Cyan
	DoBackupExistingPerms($AppDataPackages)

	# Enable folder tree inheritance
	icacls $AppDataPackages /inheritance:e /t /c /q

	# Grant ALL APPLICATION PACKAGES "Full control" for this folder, subfolders and files
	icacls $AppDataPackages /grant "*S-1-15-2-1:(OI)(CI)(F)"
}

if (Test-Path $AppDataPackages -PathType Container)
{
	DoAppDataPackages
}
else
{
	Write-Host
	$UserFolderName = Read-Host "Please enter the name of your User folder. (This is usually seen as ${C}\Users\{USERNAME}\ in Explorer.)"
	$AppDataPackages = "${C}\Users\$UserFolderName\AppData\Local\Packages"

	if (Test-Path $UserFolderName -PathType Container) # in case the user enters the full path of their user folder
	{
		$SplitUFN = $UserFolderName.Split("\")[-1]
		$AppDataPackages = "${C}\Users\$SplitUFN\AppData\Local\Packages"
	}

	if (Test-Path $AppDataPackages -PathType Container)
	{
		DoAppDataPackages
	}
	else
	{
		Write-Warning 'AppData Packages not found, make sure that you properly ran the PAExec command in CMD, and that you correctly wrote "%LocalAppData%" at the end'
	}
}


# Fix ProgramData Packages

$ProgramData = "${C}\ProgramData\Packages"

if (Test-Path $ProgramData -PathType Container)
{
	Write-Host
	Write-Host "Fixing ProgramData Packages permissions..." -ForegroundColor Cyan
	DoBackupExistingPerms($ProgramData)

	# Grant SYSTEM ownership of this folder
	icacls $ProgramData /setowner "*S-1-5-18" /c /q

	# Deeply grant SYSTEM "Full control" for this folder, subfolders and files
	icacls $ProgramData /grant "*S-1-5-18:(OI)(CI)(F)" /t /c /q

	# Deeply grant TrustedInstaller "Full control" for this folder, subfolders and files
	icacls $ProgramData /grant "*S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464:(OI)(CI)(F)" /t /c /q

	# Deeply grant Administrators "Full control" for this folder, subfolders and files
	icacls $ProgramData /grant "*S-1-5-32-544:(OI)(CI)(F)" /t /c /q
}

Write-Host
Write-Host "Unfukking finished!! (hopefully)"  -ForegroundColor Green
Write-Host
pause
