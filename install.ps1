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

Start-Transcript -Path log.txt -Append
$global:RegRunKey ="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
$global:restartKey = "Restart-And-Resume"
$script = $myInvocation.MyCommand.Definition
$ErrorActionPreference = "Stop"
$key = 'WSLFreesurferInstall'
$file=$MyInvocation.MyCommand.Name

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

Write-Host "Downloading and installing Ubuntu..."

$ubpackage = Get-AppxPackage -Name "CanonicalGroupLimited.Ubuntu*"
if($ubpackage -eq $null )
{
	Download-File -Source https://aka.ms/wsl-ubuntu-1804 -Target Ubuntu.appx
	Add-AppxPackage .\Ubuntu.appx
	#cleanup
	rm Ubuntu.appx
	$ubpackage = Get-AppxPackage -Name "CanonicalGroupLimited.Ubuntu*"
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

Write-Host "Installing necessary packages ...."
bash -c "sudo apt-get update"
bash -c "sudo apt-get install wslu"




Write-Host "Downloading Freesurfer..."
Download-File https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.0/freesurfer-linux-centos8_x86_64-7.1.0.tar.gz -Target freesurfer.tar.gz
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

try
{
	$fspathUbuntu=wslpath -a $fspath
	$fileubPath=wslpath -a (Resolve-Path freesurfer.tar.gz).Path
}
catch
{
	$fspathUbuntu=To-WSLPath($fspath)
	$fileubPath=To-WSLPath((Resolve-Path freesurfer.tar.gz).Path)
}

bash -c "tar xvzf $fileubPath -C $fspathUbuntu"
$fstestpath= $fspathUbuntu+"/freesurfer"
#test freesurfer
if(bash -c "export FREESURFER_HOME="+$fspathUbuntu+"/freesurfer 
source $FREESURFER_HOME/SetUpFreeSurfer.sh" -eq 0)
{
Write-Host "Freesurfer and the WSL system have been installed successfully!"
}
else
{
Write-Error "Problem during script!"
}