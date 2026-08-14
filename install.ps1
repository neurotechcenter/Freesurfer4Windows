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


if($featureInfo.State -ne "Enabled")
{	$restartcmd="powershell -Command Start-Process PowerShell $script -verb RunAs"
	Set-Key $global:RegRunKey $key $restartcmd  #automatically open script after reboot
	Write-Host "Enabling WSL... This will require a restart, Script will continue automatically!"
	Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
	Exit
}

if (Test-Key $global:RegRunKey $key) #remove automatic script call after reboot
{
	Remove-Key $global:RegRunKey $key
}


Write-Host "Checking for existing Ubuntu installation..."
# Freesurfer 7.2.0 (downloaded by config_ub.sh) only ships an official Ubuntu18 build
# (freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz). Installing whatever Ubuntu happens to be
# the current WSL default (24.04+ as of 2026) risks library/glibc mismatches, so pin to the
# matching LTS release instead. Bump this if config_ub.sh is ever updated to a newer Freesurfer
# build (e.g. Freesurfer 7.4.1 officially supports Ubuntu 22 - see the Freesurfer wiki's
# FS7_wsl_ubuntu page).
$ubuntuDistro = "Ubuntu-18.04"
$ubpackage = Get-AppxPackage -Name "CanonicalGroupLimited.Ubuntu*"
if($ubpackage -eq $null )
{
	Write-Host "Installing $ubuntuDistro via 'wsl --install -d $ubuntuDistro'..."
	wsl --install -d $ubuntuDistro
	Write-Host "Waiting for the Ubuntu package to register..."
	$retries = 0
	while ($ubpackage -eq $null -and $retries -lt 30)
	{
		Start-Sleep -Seconds 2
		$ubpackage = Get-AppxPackage -Name "CanonicalGroupLimited.Ubuntu*"
		$retries++
	}
	if ($ubpackage -eq $null)
	{
		Write-Error "$ubuntuDistro did not register after 'wsl --install -d $ubuntuDistro'. Run 'wsl --list --online' to see the currently available distro names, install $ubuntuDistro manually, then re-run this script."
		Exit
	}
	wsl --set-default-version 2 # James changed to wsl2
    wsl --set-version $ubuntuDistro 2
    wsl --manage $ubuntuDistro --set-sparse true # James added to try to prevent wsl2 from eating all available hard drive space
	Write-Host "Initializing Ubuntu Installation... Please close the ubuntu window after initialization is done!"
	$ubapp=($ubpackage | Get-AppxPackageManifest).Package.Applications.Application.Id
	Start-Process $ubapp -Wait -verb RunAs
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

