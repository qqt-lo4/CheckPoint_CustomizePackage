function Get-WingetPackageInstaller {
    <#
    .SYNOPSIS
        Gets the installer details for a WinGet package

    .DESCRIPTION
        Retrieves the installer manifest for a WinGet package, selecting the appropriate
        installer based on architecture and scope. Determines silent install switches
        and resolves nested installer types (e.g., MSI inside ZIP).

    .PARAMETER PackageId
        The WinGet package identifier (e.g., "Google.Chrome")

    .PARAMETER Architecture
        Target architecture: x64, x86, arm, arm64 (default: x64)

    .PARAMETER BackupArchitecture
        Fallback architecture if the primary is not available

    .PARAMETER Scope
        Installation scope: user or machine (default: machine)

    .OUTPUTS
        Hashtable with Installers, InstallerType, Silent, URL, Scope, and Manifest properties.

    .EXAMPLE
        $installer = Get-WingetPackageInstaller -PackageId "Google.Chrome"
        $installer.URL

    .EXAMPLE
        Get-WingetPackageInstaller -PackageId "Mozilla.Firefox" -Architecture "x64" -Scope "user"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$PackageId,
        [ValidateSet("x64", "x86", "arm", "arm64")]
        [string]$Architecture = "x64",
        [ValidateSet("x64", "x86", "arm", "arm64")]
        [string]$BackupArchitecture,
        [ValidateSet("user", "machine")]
        [string]$Scope = "machine"
    )
    Begin {
        function Get-InstallerForArch {
            Param(
                [Parameter(Mandatory)]
                [object]$Manifest,
                [ValidateSet("x64", "x86", "arm", "arm64")]
                [string]$Architecture = "x64",
                [ValidateSet("user", "machine")]
                [string]$Scope = "machine"
            )
            $aInstallers = $Manifest.Installers | Where-Object { $_.Architecture -eq $Architecture}
            if ($Manifest.Scope) {
                if (-not (($Manifest.Scope -ne $null) -and ($Manifest.Scope -eq $Scope))) {
                    Write-Host "No installer found with matching criteria"
                    return $null
                }
            } else {
                $aInstallers = $aInstallers | Where-Object { if ($_.Scope) { $_.Scope -eq $Scope } else { $true } }
            }
            # MODIFICATION: Ne plus filtrer les packages portables pour permettre leur installation
            # $aInstallers = $aInstallers | Where-Object { $_.NestedInstallerType -ne "portable" }
            # $aInstallers = $aInstallers | Where-Object { $_.InstallerType -ne "portable" }
            if ($aInstallers.Count -gt 1) {
                $aInstallationType = $aInstallers.InstallerType
                $bExeInList = ("exe" -in $aInstallationType)
                $bInnoInList = ("inno" -in $aInstallationType)
                $bNullsoftInList = ("nullsoft" -in $aInstallationType)
                $bWixInList = ("wix" -in $aInstallationType)
                $bMSIInList = ("msi" -in $aInstallationType)
                $bNonMSI = $bExeInList -or $bInnoInList -or $bNullsoftInList
                $bMSI = $bWixInList -or $bMSIInList
                if ($bNonMSI -and $bMSI) {
                    $sTypeToFind = if ($bWixInList) { "wix" } else { "msi" }
                    $aInstallers = $aInstallers | Where-Object { $_.InstallerType -eq "$sTypeToFind" }
                }
            }
            return $aInstallers
        }

        $oPackageManifest = Get-WingetPackageManifest -PackageId $PackageId
        $hResult = @{
            Scope = $Scope
        }
    }
    Process {
        $aInstallers = Get-InstallerForArch -Manifest $oPackageManifest -Architecture $Architecture -Scope $Scope
        if ($BackupArchitecture -and (($aInstallers -eq $null) -or (($aInstallers -is [array]) -and ($aInstallers.Count -eq 0)))) {
            $hResult.Installers = Get-InstallerForArch -Manifest $oPackageManifest -Architecture $BackupArchitecture -Scope $Scope
        } else {
            $hResult.Installers = $aInstallers
        }
        $sInstallerType = if ($oPackageManifest.InstallerType) {
            $oPackageManifest.InstallerType
        } else {
            $hResult.Installers.InstallerType
        }
        $sNestedInstallerType = if ($oPackageManifest.NestedInstallerType) {
            $oPackageManifest.NestedInstallerType
        } else {
            $hResult.Installers.NestedInstallerType
        }
        $sNestedInstallerFiles = if ($oPackageManifest.NestedInstallerFiles) {
            $oPackageManifest.NestedInstallerFiles
        } else {
            $hResult.Installers.NestedInstallerFiles
        }
        $sCustomSwitch = if (($null -ne $hResult.Installers.InstallerSwitches) -and ($null -ne $hResult.Installers.InstallerSwitches.Custom)) {
            $hResult.Installers.InstallerSwitches.Custom
        } else {
            if (($null -ne $oPackageManifest.InstallerSwitches) -and ($null -ne $oPackageManifest.InstallerSwitches.Custom)) {
                $oPackageManifest.InstallerSwitches.Custom
            } else {
                ""
            }
        }
        $sSilentSwitch = if (($null -ne $hResult.Installers.InstallerSwitches) -and ($null -ne $hResult.Installers.InstallerSwitches.Silent)) {
            $hResult.Installers.InstallerSwitches.Silent
        } else {
            if (($null -ne $oPackageManifest.InstallerSwitches) -and ($null -ne $oPackageManifest.InstallerSwitches.Silent)) {
                $oPackageManifest.InstallerSwitches.Silent
            } else {
                ""
            }
        }
        if ([string]::IsNullOrEmpty($sSilentSwitch)) {
            $sRealInstallerType = if ($sInstallerType -eq "zip") {
                $sNestedInstallerType
            } else {
                $sInstallerType
            }
            $sSilentSwitch = Get-InstallerDefaultSilentSwitch $sRealInstallerType
        }
        $hResult.InstallerType = $sInstallerType
        if (-not [string]::IsNullOrEmpty($sNestedInstallerType)) {
            $hResult.NestedInstallerType = $sNestedInstallerType
        }
        if (-not [string]::IsNullOrEmpty($sNestedInstallerFiles)) {
            $hResult.NestedInstallerFiles = $sNestedInstallerFiles
        }
        $hResult.Silent = if ([string]::IsNullOrEmpty($sCustomSwitch)) {
            $sSilentSwitch
        } else {
            $sSilentSwitch + " " + $sCustomSwitch
        }
        $hResult.URL = $hResult.Installers.InstallerUrl
        $hResult.Manifest = $oPackageManifest
    }
    End {
        return $hResult
    }
}