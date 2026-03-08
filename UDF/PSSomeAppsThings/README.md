# PSSomeAppsThings

A PowerShell module for Windows application management: installed program discovery, WinGet package operations, Microsoft Store integration, Office Deployment Tool support, and Windows Installer (MSI) utilities.

## Features

### Programs
Discover and manage installed applications across the system.

| Function | Description |
|---|---|
| `Get-InstalledPrograms` | Lists installed programs from registry (HKLM/HKCU, native/WOW6432Node), Windows Installer, and optionally AppX packages. Supports remote computers, WMI mode, and hashtable output. |
| `Get-ApplicationUninstallRegKey` | Searches the Windows registry uninstall keys by display name or product code GUID. |
| `Get-InstalledProgramPath` | Retrieves the installation path (InstallLocation) for a program from the uninstall registry. |
| `Get-ProductByPackageName` | Finds installed programs by their AppX PackageName property. |
| `Get-JavaVersion` | Retrieves installed 64-bit Java Runtime versions, sorted by version descending. |
| `Test-Installed` | Checks whether a program is installed by display name or product code. Returns boolean. |
| `Test-MSISuccess` | Evaluates an MSI return code to determine if the installation succeeded (0, 1641, or 3010). |
| `Set-InstallationTag` | Creates a registry-based installation tag with metadata for tracking deployments. |
| `Test-InstallationSuccessTag` | Verifies if an installation tag exists and matches expected status/version criteria. |
| `Select-PreferredArchitecture` | Filters objects to select packages matching the preferred system architecture. |
| `Select-PreferredLocale` | Filters objects to select the preferred locale based on system language. |

### Microsoft Store
Interact with the Microsoft Store APIs to query, download, and install applications (both MSIX/AppX and Win32).

| Function | Description |
|---|---|
| `Get-UnifiedStoreAppInfo` | Unified entry point to query any Store app regardless of type (MSIX or Win32). Returns download info, metadata, and installer details. |
| `Get-StoreAppInfo` | Retrieves complete Store app information including package download URLs via DisplayCatalog and FE3 APIs. |
| `Get-StoreAppManifest` | Queries the PackageManifests API for full app metadata (description, screenshots, ratings, platforms, installers). |
| `Get-MsStoreWin32Installer` | Extracts Win32 installer information from a Store package manifest with architecture and locale filtering. |
| `Download-StoreApp` | Downloads all packages for a Store app to a local directory. |
| `Install-MSStoreApp` | Installs a Microsoft Store application (MSIX via Add-AppxPackage or Win32 via downloaded installer). |
| `Invoke-DisplayCatalogQuery` | Queries the Microsoft Store DisplayCatalog API for product information. |
| `Invoke-PackageManifestQuery` | Queries the PackageManifests API for Win32 Store apps. |
| `Filter-PackagesByArchitecture` | Filters package lists by target architecture with auto-detection support. |

<details>
<summary>Internal / Helper Functions</summary>

| Function | Description |
|---|---|
| `Get-DeviceMSAToken` | Retrieves the MSA Device Token from registry, cache, or UAC elevation. |
| `Get-CurrentMSAToken` | Returns the currently cached MSA Device Token. |
| `Get-DefaultMSAToken` | Returns the generic fallback MSA Device Token. |
| `Update-MSAToken` | Refreshes the cached MSA Device Token from the registry. |
| `Get-FE3Cookie` | Gets an authentication cookie from the FE3 delivery endpoint. |
| `Get-FE3FileUrls` | Retrieves download URLs from FE3 using UpdateIDs and RevisionIDs. |
| `Get-FE3UpdateIDs` | Parses SyncUpdates XML to extract update identifiers and package name mappings. |
| `Get-DCatEndpointUrl` | Returns the DisplayCatalog endpoint URL (Production or Int). |
| `Invoke-FE3SyncUpdates` | Synchronizes updates with the FE3 delivery endpoint. |
| `Invoke-MSHttpRequest` | HTTP client wrapper that automatically adds User-Agent and MS-CV headers. |
| `Invoke-SystemTokenExtraction` | Extracts MSA Device Token from SYSTEM registry via DPAPI decryption. |
| `New-CorrelationVector` | Creates a new Microsoft Correlation Vector string. |
| `New-CorrelationVectorObject` | Creates a CorrelationVector object with Increment/Extend methods. |
| `New-LocaleObject` | Creates a locale object with market, language, and DCat query trail. |

</details>

### WinGet
Query and manage the WinGet package catalog directly via its SQLite database, without requiring the WinGet CLI.

| Function | Description |
|---|---|
| `Get-WingetPackageCatalog` | Downloads and extracts the WinGet SQLite database from the CDN. |
| `Get-WingetPackages` | Queries packages by name, ID, publisher, or row ID with flexible filtering. |
| `Search-WingetPackages` | Searches across name, ID, and moniker fields using LIKE wildcards. |
| `Get-WingetPackageManifest` | Downloads and parses YAML manifests for WinGet packages from the CDN. |
| `Get-WingetPackageInstaller` | Retrieves installer information for a package by architecture and scope. |
| `Get-WingetPackageProductCodes` | Retrieves all product codes associated with a package. |
| `Get-WingetPackageCount` | Counts the total number of packages in the catalog database. |
| `Install-Package` | Installs packages via winget.exe with admin credentials and silent switches. |
| `Initialize-WinGetEnvironment` | Complete environment initialization (availability check, catalog init). |
| `Initialize-WinGetCatalog` | Initializes the WinGet catalog with admin privileges (source agreements, reset, update). |
| `Test-WinGetAvailability` | Checks if WinGet is available on the system. |
| `Get-WinGetExe` | Returns the path to winget.exe. |
| `Get-WingetSources` | Lists configured WinGet sources. |
| `Get-WingetPublisherId` | Retrieves the PublisherId from the DesktopAppInstaller AppX package. |

<details>
<summary>Internal / Helper Functions</summary>

| Function | Description |
|---|---|
| `Invoke-WingetDatabaseQuery` | Executes arbitrary SQL queries against the WinGet SQLite database. |
| `Get-WingetDatabaseTables` | Lists all tables in the WinGet database. |
| `Get-WingetDatabaseSchema` | Retrieves column definitions for a specific table. |
| `ConvertFrom-MSZIPYaml` | Decompresses MSZIP-compressed data from WinGet manifest files. |
| `Get-InstallerDefaultSilentSwitch` | Returns default silent switches for various installer types (MSI, InnoSetup, NSIS, etc.). |

</details>

### Windows Installer (MSI)
Read and modify Windows Installer (.msi) databases using the Windows Installer COM automation interface.

| Function | Description |
|---|---|
| `Open-MSIFile` | Opens an MSI file and creates a WindowsInstaller wrapper object. |
| `Get-MSIProperty` | Reads property values from the MSI Property table. |
| `Set-MSIProperty` | Creates or updates a property in the MSI Property table. |
| `Get-MSISummary` | Retrieves MSI SummaryInformation (Subject, Author, Title, RevisionNumber, Template, etc.). |
| `Get-MSIBinary` | Extracts a binary stream from the MSI Binary table to a file. |
| `Set-MSIBinary` | Inserts or replaces a binary stream in the MSI Binary table. |
| `Get-MSIStreams` | Lists all stream names in the MSI database. |
| `Update-MSIStream` | Updates or inserts a named stream in the MSI _Streams table. |
| `Invoke-MSISQLQuery` | Executes arbitrary SQL queries against an MSI database with automatic column resolution. |
| `Get-TableColumns` | Retrieves column definitions from the MSI _Columns metadata table. |
| `Get-InstallerProduct` | Lists Windows Installer product entries from the HKCR:\Installer\Products registry. |

### Microsoft Office
Manage Office Deployment Tool (ODT) configurations.

| Function | Description |
|---|---|
| `Get-OfficeDeploymentToolPath` | Searches for Office Deployment Tool (setup.exe) in common installation paths. |
| `Test-OfficeDeploymentTool` | Tests if Office Deployment Tool is installed. Returns boolean. |
| `New-OfficeDeploymentConfiguration` | Generates an ODT XML configuration file for deploying Microsoft Office products. |

## Requirements

- **PowerShell** 5.1 or later
- **Windows** operating system
- **PSSQLite** module (for WinGet database functions)
- **powershell-yaml** module (for WinGet manifest parsing)
- Administrator privileges may be required for:
  - MSA Device Token extraction from SYSTEM registry
  - Machine-scope MSIX/AppX installations
  - WinGet catalog initialization

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeAppsThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeAppsThings" -Recurse

# Or import directly
Import-Module ".\PSSomeAppsThings\PSSomeAppsThings.psd1"
```

## Quick Start

### List installed programs
```powershell
# Get all installed programs (Programs and Features style)
$programs = Get-InstalledPrograms -ProgramAndFeatures

# Check if a specific program is installed
Test-Installed -ProgramName "Google Chrome"
```

### Query the Microsoft Store
```powershell
# Get comprehensive info about a Store app
$appInfo = Get-UnifiedStoreAppInfo -ProductId "9NKSQGP7F2NH"

# Download Store app packages
Download-StoreApp -ProductId "9NKSQGP7F2NH" -OutputPath "C:\Temp\StoreApps"

# Install a Store app
$package = @{ Id = "9NKSQGP7F2NH"; Scope = "user"; Name = "WhatsApp" }
Install-MSStoreApp -Package $package
```

### Work with WinGet packages
```powershell
# Download the WinGet catalog database
$catalog = Get-WingetPackageCatalog

# Search for packages
Search-WingetPackages -SearchTerm "vscode"

# Get package manifest
$manifest = Get-WingetPackageManifest -PackageId "Microsoft.VisualStudioCode"
```

### Read MSI properties
```powershell
# Open an MSI file
$msi = Open-MSIFile -Path "C:\Temp\setup.msi"

# Read properties
Get-MSIProperty -MSIFile $msi -Name "ProductVersion"
Get-MSISummary -MSIFile $msi

# Modify a property
Set-MSIProperty -MSIFile $msi -Name "ALLUSERS" -Value "1"
```

### Generate Office configuration
```powershell
# Create an ODT configuration for Microsoft 365
New-OfficeDeploymentConfiguration -Products "O365ProPlusRetail" `
    -ExcludeApps "Teams","Groove" `
    -Language "en-US" `
    -OutputPath "C:\Temp\office-config.xml"
```

## Module Structure

```
PSSomeAppsThings/
├── PSSomeAppsThings.psd1          # Module manifest
├── PSSomeAppsThings.psm1          # Module loader (dot-sources all .ps1 files)
├── README.md                      # This file
├── MicrosoftOffice/               # Office Deployment Tool functions
├── MicrosoftStore/                # Microsoft Store API integration
├── Programs/                      # Installed programs discovery
├── WindowsInstaller/              # MSI database utilities
└── Winget/                        # WinGet package catalog functions
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
