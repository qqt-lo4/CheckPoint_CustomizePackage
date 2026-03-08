function Get-UnifiedStoreAppInfo {
    <#
    .SYNOPSIS
    Unified function to query Microsoft Store app information regardless of app type

    .DESCRIPTION
    Retrieves comprehensive information about a Microsoft Store application including
    download links, metadata, and installer information. Automatically detects whether
    the app is a modern MSIX/APPX package or a Win32 Store package and returns
    appropriate download information.

    .PARAMETER ProductId
    The Microsoft Store Product ID (12-14+ characters like 9NKSQGP7F2NH or xpfm306ts4phh5)

    .PARAMETER Market
    Market code (default: US)

    .PARAMETER Language
    Language code (default: en-US)

    .PARAMETER Architecture
    Preferred architecture for installers (default: x64)

    .PARAMETER Scope
    Installation scope - 'user' or 'machine' (default: machine)

    .EXAMPLE
    Get-UnifiedStoreAppInfo -ProductId "9NKSQGP7F2NH"

    .EXAMPLE
    Get-UnifiedStoreAppInfo -ProductId "xpfm306ts4phh5" -Architecture "x64"

    .OUTPUTS
    PSCustomObject with unified structure containing:
    - AppType: "MSIX/AppX" or "Win32"
    - Manifest: Full manifest from Get-StoreAppManifest
    - DownloadInfo: Download URLs and package information
    - InstallerInfo: Specific installer details (architecture, locale, etc.)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        This function combines Get-StoreAppManifest, Get-StoreAppInfo, and Get-MsStoreWin32Installer
        to provide a single entry point for querying any Store app type.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern('^[A-Za-z0-9]{12,}$')]
        [string]$ProductId,

        [Parameter(Mandatory = $false)]
        [string]$Market = 'US',

        [Parameter(Mandatory = $false)]
        [string]$Language = 'en-US',

        [Parameter(Mandatory = $false)]
        [ValidateSet('x64', 'x86', 'ARM64', 'ARM', 'neutral', 'All', 'Autodetect')]
        [string]$Architecture = 'Autodetect',

        [Parameter(Mandatory=$false)]
        [switch]$LatestVersionsOnly
    )

    Begin {
        Write-Verbose "Querying unified Store information for ProductId: $ProductId"
    }

    Process {
        try {
            # Step 1: Get the manifest to determine app type
            Write-Verbose "Retrieving Store app manifest..."
            $manifest = Get-StoreAppManifest -ProductId $ProductId -Market $Market -Language $Language

            if (-not $manifest) {
                throw "Unable to retrieve manifest for ProductId: $ProductId"
            }

            $appType = $manifest.AppType
            Write-Verbose "Detected app type: $appType"

            # Step 2: Get download information based on app type
            $downloadInfo = $null
            $installerInfo = $null
            $rawWin32Installer = $null
            $rawStoreAppInfo = $null
            $sPackageVersion = $null

            $packageInfo = $manifest.RawManifest.Data.Versions
            $defaultLocale = $packageInfo.DefaultLocale
            $hAgreements = @{}
            foreach ($oAgreement in $defaultLocale.Agreements) {
                $sAgreementLabel = $oAgreement.AgreementLabel
                $hAgreements.$sAgreementLabel = ($defaultLocale.Agreements | Where-Object { $_.AgreementLabel -eq $sAgreementLabel }).Agreement
            }

            if ($appType -eq "Win32") {
                # Win32 Store app - extract installer information from manifest
                Write-Verbose "Processing Win32 Store app..."

                try {
                    $rawWin32Installer = Get-MsStoreWin32Installer -PackageManifest $manifest -Architecture $Architecture
                    $installerInfo = $rawWin32Installer

                    if ($rawWin32Installer) {
                        $downloadInfo = [ordered]@{
                            Type = "Win32"
                            InstallerUrl = $rawWin32Installer.InstallerUrl
                            InstallerSha256 = $rawWin32Installer.InstallerSha256
                            Architecture = $rawWin32Installer.Architecture
                            InstallerType = $rawWin32Installer.InstallerType
                            InstallerLocale = $rawWin32Installer.InstallerLocale
                            InstallerSwitches = $rawWin32Installer.InstallerSwitches.Silent
                            Scope = $rawWin32Installer.Scope
                            RowInfo = $rawWin32Installer
                        }
                    } else {
                        Write-Warning "No Win32 installer found for the specified architecture: $Architecture"
                    }
                    $sPackageVersion = $packageInfo.PackageVersion
                }
                catch {
                    Write-Warning "Failed to retrieve Win32 installer info: $($_.Exception.Message)"
                }
            }
            elseif ($appType -eq "MSIX/AppX") {
                # Modern MSIX/APPX app - use DisplayCatalog API
                Write-Verbose "Processing MSIX/APPX Store app..."

                try {
                    $rawStoreAppInfo = Get-StoreAppInfo -ProductId $ProductId -Architecture $Architecture -Market $Market -Language $Language -LatestVersionsOnly:$LatestVersionsOnly

                    if ($rawStoreAppInfo -and $rawStoreAppInfo.Packages) {
                        $downloadInfo = [ordered]@{
                            Type = "MSIX/AppX"
                            Packages = $rawStoreAppInfo.Packages
                            PackageCount = $rawStoreAppInfo.PackageCount
                            MainPackage = $rawStoreAppInfo.Packages | Where-Object {
                                $_.IsMainPackage
                            }
                            RawInfo = $rawStoreAppInfo
                        }

                        $installerInfo = @{
                            PackageFamilyName = $manifest.PackageInfo.PackageFamilyName
                            PackageIdentityName = $manifest.PackageInfo.PackageIdentityName
                            Version = $manifest.ProductInfo.Version
                            Architecture = $Architecture
                        }
                    } else {
                        Write-Warning "No MSIX/APPX packages found"
                    }
                    $sPackageVersion = ($downloadInfo.Packages | Where-Object { $_.IsMainPackage }).Version
                }
                catch {
                    Write-Warning "Failed to retrieve MSIX/APPX package info: $($_.Exception.Message)"
                }
            }
            else {
                Write-Warning "Unknown app type: $appType"
            }

            # Step 3: Build unified result object
            $result = [ordered]@{
                ProductId = $ProductId
                AppType = $appType
                Market = $Market
                Language = $Language
                QueryDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                # Display information
                DisplayName = $defaultLocale.PackageName
                Publisher = $defaultLocale.Publisher
                Description = $defaultLocale.Description

                # Product information
                Category = $hAgreements["Category"]
                Version = $sPackageVersion
                ReleaseDate = $manifest.ProductInfo.ReleaseDate

                # Pricing
                IsFree = $hAgreements["Pricing"] -eq "Free"
                Price = $hAgreements["Pricing"]

                # Download information
                DownloadInfo = $downloadInfo
                InstallerInfo = $installerInfo
            }

            # Full manifest for advanced usage
            $result.Manifest = $manifest

            return [PSCustomObject]$result
        }
        catch {
            Write-Error "Failed to retrieve unified Store app information: $($_.Exception.Message)"
            throw
        }
    }
}
