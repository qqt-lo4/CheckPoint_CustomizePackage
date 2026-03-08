function Get-MsStoreWin32Installer {
    <#
    .SYNOPSIS
    Gets the appropriate Win32 installer from a Microsoft Store package manifest

    .PARAMETER PackageId
    The Store Product ID

    .PARAMETER PackageManifest
    The package manifest object from Get-StoreAppManifest

    .PARAMETER Architecture
    Architecture preference: x64, x86, ARM64, ARM, All, or Autodetect (default)
    - Autodetect: Uses Get-SystemArchitecture to detect system architecture and fallbacks
    - All: Returns all installers without filtering by architecture

    .PARAMETER InstallerLocale
    Optional locale filter for the installer

    .OUTPUTS
    Installer object(s) matching the specified architecture and locale criteria

    .EXAMPLE
        Get-MsStoreWin32Installer -PackageId "XPFM306TS4PHH5" -Architecture x64

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "Id")]
    Param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "Id")]
        [string]$PackageId,

        [Parameter(Mandatory, ParameterSetName = "Package")]
        [object]$PackageManifest,

        [Parameter(Mandatory = $false)]
        [ValidateSet('x64', 'x86', 'ARM64', 'ARM', 'All', 'Autodetect')]
        [string]$Architecture = "Autodetect",

        [Parameter(Mandatory = $false)]
        [string]$InstallerLocale
    )

    # Get the package manifest
    $oPackageManifest = if ($PackageId) {
        Get-StoreAppManifest -ProductId $PackageId
    } else {
        $PackageManifest
    }

    if ($oPackageManifest.AppType -ne "Win32") {
        throw "Not a Win32 package (AppType: $($oPackageManifest.AppType))"
    }

    # Get all installers
    $aInstallers = $oPackageManifest.RawManifest.Data.Versions.Installers

    if (-not $aInstallers -or $aInstallers.Count -eq 0) {
        throw "No installers found in manifest"
    }

    # Filter by architecture
    $aResult = $aInstallers

    if ($Architecture -eq "Autodetect") {
        # Auto-detect system architecture and fallbacks
        $sysArch = Get-SystemArchitecture
        Write-Verbose "Auto-detected architecture: Primary=$($sysArch.Primary), Fallback=$($sysArch.Fallback -join ', ')"

        # Try primary architecture first
        $aResult = $aInstallers | Where-Object { $_.Architecture -eq $sysArch.Primary }

        # If not found, try fallback architectures in order
        if (-not $aResult -and $sysArch.Fallback) {
            foreach ($fallbackArch in $sysArch.Fallback) {
                $aResult = $aInstallers | Where-Object { $_.Architecture -eq $fallbackArch }
                if ($aResult) {
                    Write-Verbose "Using fallback architecture: $fallbackArch"
                    break
                }
            }
        }

        if (-not $aResult) {
            throw "No installer found for system architecture $($sysArch.Primary) or fallbacks: $($sysArch.Fallback -join ', ')"
        }
    }
    elseif ($Architecture -ne "All") {
        # Filter by specific architecture
        $aResult = $aInstallers | Where-Object { $_.Architecture -eq $Architecture }

        if (-not $aResult) {
            throw "No installer found for architecture: $Architecture"
        }
    }
    # If Architecture is "All", $aResult already contains all installers

    # Filter by locale
    if ($InstallerLocale) {
        $aResult = $aResult | Where-Object { $_.InstallerLocale -eq $InstallerLocale }
        if (-not $aResult) {
            throw "No installer found for locale: $InstallerLocale"
        }
    } else {
        # Auto-detect locale
        $oLang = Get-LocaleFormats
        $aResultFullLang = $aResult | Where-Object { $_.InstallerLocale -eq $oLang.Full }
        if ($aResultFullLang) {
            return $aResultFullLang
        }

        $aResultShortLang = $aResult | Where-Object { $_.InstallerLocale -eq $oLang.Short }
        if ($aResultShortLang) {
            return $aResultShortLang
        }

        # Fallback to English
        $aResultEn = $aResult | Where-Object { $_.InstallerLocale -eq "en" }
        if ($aResultEn) {
            return $aResultEn
        }

        # If no locale match, return first result
        Write-Verbose "No locale match found, returning first available installer"
        return $aResult | Select-Object -First 1
    }

    return $aResult
}