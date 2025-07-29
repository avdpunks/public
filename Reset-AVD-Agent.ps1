#################################################################################
#
# The sample scripts are not supported under any Microsoft standard support
# program or service. The sample scripts are provided AS IS without warranty
# of any kind. Microsoft further disclaims all implied warranties including, without
# limitation, any implied warranties of merchantability or of fitness for a particular
# purpose. The entire risk arising out of the use or performance of the sample scripts
# and documentation remains with you. In no event shall Microsoft, its authors, or
# anyone else involved in the creation, production, or delivery of the scripts be liable
# for any damages whatsoever (including, without limitation, damages for loss of business
# profits, business interruption, loss of business information, or other pecuniary loss)
# arising out of the use of or inability to use the sample scripts or documentation,
# even if Microsoft has been advised of the possibility of such damages.
#
#################################################################################

<#
.SYNOPSIS
    Resets and reinstalls the Azure Virtual Desktop (AVD) Agent and Bootloader using a provided registration token to resolve agent-related issues.

.DESCRIPTION
    This script is designed to troubleshoot and resolve issues with the AVD Agent by performing a clean reinstallation of both the AVD Agent and its Bootloader. 
    It requires a valid RegToken parameter to re-register the session host with the AVD host pool.

.NOTES
    Author: Daniel Weppeler
    Date: 07/28/2025
    Version: 1.0
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$AVDRegistrationToken
)

$LogPath = "C:\Windows\Temp\ResetAVDAgent.log"

function Write-Log {
    param([string]$Message)
    Write-Output $Message
}

try {

    Start-Transcript -Path $LogPath -ErrorAction Stop
    Write-Log "Transcript started. Log file: $LogPath"

    $services = Get-Service | Where-Object { $_.Name -Match 'TermService' -or $_.Name -Match 'UmRdpService'}
    Foreach ($s in $services) {
    Stop-Service -Name $s.Name -Force
    }

    $Packages = Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -Match 'Remote Desktop Services' -or $_.Name -Match 'Remote Desktop Agent Boot Loader'}
    Install-Package -Name 'nuget' -Force

    Foreach ($p in $packages) {
    Uninstall-Package -Name $p.name
    }

    Write-Log "Starting AVD Agent installation..."
    $TempPath = "$env:WINDIR\Temp"
    $AgentInstaller = Join-Path $TempPath "AVDAgentInstaller.msi"
    $BootloaderInstaller = Join-Path $TempPath "AVDAgentBootloaderInstaller.msi"

    Write-Log "Downloading AVD Agent installer..."
    Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2310011' -OutFile $AgentInstaller -UseBasicParsing
    Start-Sleep -Seconds 10
    Write-Log "Installing AVD Agent..."
    Unblock-File $AgentInstaller
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$AgentInstaller`" /quiet REGISTRATIONTOKEN=$RegToken" -Wait
    Write-Log "Successfully installed AVD Agent."

    Write-Log "Downloading AVD Agent Bootloader installer..."
    Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2311028' -OutFile $BootloaderInstaller -UseBasicParsing
    Start-Sleep -Seconds 10
    Write-Log "Installing AVD Agent Bootloader..."
    Unblock-File $BootloaderInstaller
    Start-Process -FilePath 'msiexec.exe' -ArgumentList "/i `"$BootloaderInstaller`" /quiet" -Wait
    Write-Log "Successfully installed AVD Agent Bootloader."
    
    Stop-Transcript
    Write-Log "Transcript stopped."
    exit 0
} catch {
    Write-Error "An error occurred: $_"
    Stop-Transcript
    exit 1
}
