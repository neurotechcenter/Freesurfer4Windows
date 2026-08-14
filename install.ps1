Write-Host "Installing Windows Subsystem for Linux..."
Write-Host "Check if optional feature is enabled..."
# https://www.codeproject.com/Articles/223002/Reboot-and-Resume-PowerShell-Script


function Get-Key([string] $path, [string] $key) 
{
    return (Get-ItemProperty $path).$key
}

function Test-Key([string] $path, [string] $key)
{
    return ((Test-Path $path) -and ((Get-Key $path $key) -ne $null))   
}

function Remove-Key([string] $path, [string] $key)
{
    Remove-ItemProperty -path $path -name $key
}

function Set-Key([string] $path, [string] $key, [string] $value) 
{
    Set-ItemProperty -path $path -name $key -value $value
}

function To-WSLPath([string] $path)
{
	$fsrelpath=Split-Path $path -NoQualifier
	$drive=Split-Path $path -Qualifier
	$drive = ($drive -replace ':','').ToLower()
	return ("\mnt\" + $drive + $fsrelpath) -replace "\\","/"
}

function Download-File
{
	param( [string]$Source, [string]$Target )
	try
	{
		curl.exe -L -o $Target $Source
	}
	catch
	{ #fallback if Win10 is < spring 2018 and does not include curl
		Invoke-WebRequest -Uri $Source -OutFile $Target -UseBasicParsing
	}
}


$global:RegRunKey ="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$script = $myInvocation.MyCommand.Definition
$scriptPath = Split-Path -parent $script
$ErrorActionPreference = "Stop"
$key = 'WSLFreesurferInstall'
cd $scriptPath
Start-Transcript -Path $scriptPath/log.txt -Append



$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if(-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Error "This script required Admin Privileges, please re-run as admin"
	Exit
}

$featureInfo = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
# WSL2 also needs the Virtual Machine Platform feature. 'wsl --install' would normally enable this
# automatically, but this script installs Ubuntu manually (see below), so it has to be enabled here too.
$vmFeatureInfo = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform


if($featureInfo.State -ne "Enabled" -or $vmFeatureInfo.State -ne "Enabled")
{	$restartcmd="powershell -Command Start-Process PowerShell $script -verb RunAs"
	Set-Key $global:RegRunKey $key $restartcmd  #automatically open script after reboot
	Write-Host "Enabling WSL and Virtual Machine Platform... This will require a restart, Script will continue automatically!"
	if($featureInfo.State -ne "Enabled")
	{
		Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
	}
	if($vmFeatureInfo.State -ne "Enabled")
	{
		Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
	}
	Exit
}

if (Test-Key $global:RegRunKey $key) #remove automatic script call after reboot
{
	Remove-Key $global:RegRunKey $key
}


Write-Host "Checking for existing Ubuntu installation..."
# Freesurfer 7.2.0 (downloaded by config_ub.sh) only ships an official Ubuntu18 build
# (freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz). 'wsl --install -d <name>' can no longer pin a
# version though - as of 2026 'wsl --list --online' only lists the generic, rolling "Ubuntu"
# (currently 24.04+), not versioned entries like "Ubuntu-18.04"/"Ubuntu-20.04"/"Ubuntu-22.04".
# So instead we download the Ubuntu 18.04 appx directly (the same method this script used pre-2023,
# just pointed at 18.04 instead of 20.04) to get the version Freesurfer 7.2.0 actually matches.
# Note: this appx registers its WSL distro simply as "Ubuntu", not "Ubuntu-18.04".
# If config_ub.sh is ever bumped to a newer Freesurfer build (e.g. 7.4.1, which officially
# supports Ubuntu 22 - see the Freesurfer wiki's FS7_wsl_ubuntu page), change $ubuntuAppxUrl
# below to match (e.g. https://aka.ms/wslubuntu2204) and update config_ub.sh together.
$ubuntuAppxUrl = "https://aka.ms/wsl-ubuntu-1804"
$ubuntuDistro = "Ubuntu"
$ubpackage = Get-AppxPackage -Name "CanonicalGroupLimited.Ubuntu*"
if($ubpackage -eq $null )
{
	Write-Host "Downloading and installing Ubuntu 18.04..."
	Download-File -Source $ubuntuAppxUrl -Target Ubuntu.appx
	wsl --set-default-version 2 # James changed to wsl2
	Write-Host "(Any WSL command-line messages above can be ignored - installing Ubuntu now. An Ubuntu window will open shortly; please wait for it.)"
	Add-AppxPackage .\Ubuntu.appx
	#cleanup
	rm Ubuntu.appx
	$ubpackage = Get-AppxPackage -Name "CanonicalGroupLimited.Ubuntu*"
	if ($ubpackage -eq $null)
	{
		Write-Error "Ubuntu did not install from '$ubuntuAppxUrl'. Download and install it manually, then re-run this script."
		Exit
	}
	Write-Host ""
	Write-Host "A new Ubuntu console window is about to open to finish setting up Ubuntu. In that window:"
	Write-Host "  1. Wait for it to finish unpacking (can take a minute or two)."
	Write-Host "  2. When prompted, create a UNIX username and password for Ubuntu - this is separate"
	Write-Host "     from your Windows login, can be anything, and the password won't show as you type."
	Write-Host "  3. Once you see a normal prompt like 'username@computername:~$', setup is done -"
	Write-Host "     close that Ubuntu window now. This installer is waiting for it to close and will"
	Write-Host "     continue automatically once you do."
	Write-Host ""
	$ubapp=($ubpackage | Get-AppxPackageManifest).Package.Applications.Application.Id
	Start-Process $ubapp -Wait -verb RunAs

	# The distro only registers with WSL once this first-launch initialization completes, so
	# --set-version/--manage (which target it by name) have to run after Start-Process, not before.
	wsl --set-version $ubuntuDistro 2
	wsl --manage $ubuntuDistro --set-sparse true 2>&1 | Out-Null # James added to try to prevent wsl2 from eating all available hard drive space
	if ($LASTEXITCODE -ne 0)
	{
		Write-Host "Note: 'wsl --manage --set-sparse' isn't supported by this system's WSL version - skipping (this only affects disk-space usage, not Freesurfer). Run 'wsl --update' for a newer WSL if you want it."
	}
}
else
{
	Write-Host "Found existing Ubuntu installation..."
}


$checkInstall = bash -c "echo success"
if($checkInstall -eq "success")
{
	Write-Host "Ubuntu successfully installed!"
}


#select target dir for freesurfer
#configure paths
$fspath = Read-Host "Choose Freesurfer Path (default is C:/freesurfer)"
if([string]::IsNullOrEmpty($fspath))
{
	$fspath="C:\freesurfer"
}
if(-Not (Test-Path $fspath))
{
mkdir $fspath
}

$configScriptPath= $scriptPath+"\config_ub.sh"
try
{
	$fspathUbuntu=wslpath -a $fspath
	$fileubPath=wslpath -a $configScriptPath
}
catch
{
	$fspathUbuntu=To-WSLPath($fspath)
	$fileubPath=To-WSLPath($configScriptPath)
}

bash -c "'$fileubPath' '$fspathUbuntu'"


#Download Winserver for Windows
Write-Host "Downloading most recent VcXsrv..."
Download-File -Source https://sourceforge.net/projects/vcxsrv/files/latest/download -Target VcXsrv.exe

Write-Host "Installing VcXsrv..."
Start-Process "./VcXsrv.exe" -argumentlist "/S" -wait
Write-Host "Installation of VcXserv done!."

rm VcXsrv.exe
Write-Host "Installation finished without issues! Please close this window. Do not forget the freesurfer license!"
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

