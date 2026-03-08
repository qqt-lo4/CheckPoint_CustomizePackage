# PSSomeCheckPointEndpointThings

A PowerShell module for Check Point Endpoint Security client management: VPN connections, site configuration, service control, installation, and trac configuration.

## Features

### ConfigFile (3 functions + 2 classes)

| Function | Description |
|----------|-------------|
| `Get-CheckPointTracDefaults` | Retrieves the path to the trac.defaults configuration file |
| `New-TracConfigFile` | Creates a new trac.config XML configuration file for VPN sites |
| `Set-TracDefaultsConfig` | Applies configuration settings to trac.defaults file from JSON |
| `tracDefaultsSetting` | Class representing a single trac.defaults configuration setting |
| `tracDefaultsSettings` | Class for managing trac.defaults configuration with read/modify/backup/save operations |

### Configure (2 functions)

| Function | Description |
|----------|-------------|
| `Set-EndpointLogLevel` | Sets the log level for Check Point Endpoint Security (disabled/basic/extended) |
| `Set-EndpointSDL` | Enables or disables SDL (Software Defined Logging) |

### GetInfo (7 functions)

| Function | Description |
|----------|-------------|
| `Get-CheckPointInfo` | Retrieves comprehensive connection information with structured parsing |
| `Get-CheckPointProduct` | Retrieves the Check Point product display name from registry |
| `Get-CheckPointRegKey` | Retrieves the Windows registry key for Check Point installation |
| `Get-CheckPointTracExe` | Retrieves the path to trac.exe executable |
| `Get-CheckPointTracInfo` | Executes trac.exe info to get raw connection and gateway information |
| `Get-CheckPointVersion` | Retrieves the Check Point version number from registry |

### Installation (2 functions + 1 enum)

| Function | Description |
|----------|-------------|
| `Install-NewCheckPointVPN` | Silently installs Check Point VPN from MSI or EXE with language/password/SDL options |
| `ConvertTo-EPSInstalledFeatures` | Converts feature bitmask to array or string of EPS feature names |
| `EPSFeatures` | Enum defining bitmask values for EPS features (DA, FDE, ME, FW1, COMP, etc.) |

### Other (1 function)

| Function | Description |
|----------|-------------|
| `Get-CheckPointFile` | Retrieves the full path to a Check Point file (auto-detects product and architecture) |

### Service (2 functions)

| Function | Description |
|----------|-------------|
| `Start-CheckPointService` | Starts the Check Point Endpoint Security service using trac.exe |
| `Stop-CheckPointService` | Stops the Check Point Endpoint Security service using trac.exe |

### VPNConnection (5 functions)

| Function | Description |
|----------|-------------|
| `Connect-CheckPointVPN` | Establishes a VPN connection with username/password authentication |
| `Disconnect-CheckPointVPN` | Terminates the active VPN connection |
| `Get-LastConnection` | Extracts and parses the last successful connection date/time |
| `Show-CheckPointConnectGUI` | Launches the Check Point VPN graphical connection interface |
| `Test-IsRecentConnection` | Checks if the last connection occurred within a specified time window |
| `Wait-VPNStatus` | Polls VPN status until expected status is reached or timeout |

### VPNSites (3 functions + 2 classes)

| Function | Description |
|----------|-------------|
| `Get-SiteInfo` | Retrieves detailed site information including properties and gateway list |
| `List-CheckPointSites` | Lists all configured VPN site names |
| `New-CheckPointVPNSite` | Creates a new VPN site configuration with authentication method |
| `connectedFirewall` | Class representing a connected firewall gateway (name, status, main) |
| `checkpointSiteInfo` | Class representing VPN site information (connection name, properties, gateways) |

## Requirements

- **PowerShell** 5.1 or later
- **Windows** operating system
- **Check Point VPN** or **Check Point Endpoint Security** installed

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeCheckPointEndpointThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeCheckPointEndpointThings" -Recurse

# Or import directly
Import-Module ".\PSSomeCheckPointEndpointThings\PSSomeCheckPointEndpointThings.psd1"
```

## Quick Start

### Getting Information

```powershell
# Get Check Point product and version
$product = Get-CheckPointProduct
$version = Get-CheckPointVersion
Write-Host "$product version $version"

# Get all connection information
$info = Get-CheckPointInfo
$info | ForEach-Object {
    Write-Host "Connection: $($_.Connection)"
    Write-Host "Status: $($_.status)"
    $_.gateway_list
}

# List all configured VPN sites
$sites = List-CheckPointSites
$sites | ForEach-Object { Write-Host "Site: $_" }

# Get detailed site information
$siteInfo = Get-SiteInfo -sitename "Corporate VPN"
$siteInfo.properties
$siteInfo.gatewayList
```

### Connecting and Disconnecting

```powershell
# Connect to a VPN site
$result = Connect-CheckPointVPN -SiteName "Corporate VPN" -Username "user@company.com" -Password "MyPassword"
if ($result.Success) {
    Write-Host "Connected successfully"
} else {
    Write-Host "Connection failed"
    $result.CommandResult
}

# Wait for connection to establish
Wait-VPNStatus -tracexe (Get-CheckPointTracExe) -SiteName "Corporate VPN" -ExpectedStatus "Connected" -Timeout 30

# Disconnect
$result = Disconnect-CheckPointVPN
if ($result.Success) {
    Write-Host "Disconnected successfully"
}

# Show connection GUI
Show-CheckPointConnectGUI -sitename "Corporate VPN" -waitOpenAndClose
```

### Managing Sites

```powershell
# Create a new VPN site
$result = New-CheckPointVPNSite -site "vpn.example.com" -displayName "Company VPN" -authenticationMethod "username-password"
if ($result.Success) {
    Write-Host "Site created: $($result.Site)"
}

# Create a site with certificate authentication
New-CheckPointVPNSite -site "secure.example.com" -displayName "Secure VPN" -authenticationMethod "certificate"

# Create trac.config file
New-TracConfigFile -Path "C:\Temp" -Site "vpn.company.com" -DisplayName "Corporate VPN" -AuthenticationMethod "username-password"
```

### Configuration Management

```powershell
# Get trac.defaults path
$tracDefaults = Get-CheckPointTracDefaults

# Load and modify trac.defaults
$config = @{ log_level = "debug"; enable_ssl = "true" } | ConvertTo-Json | ConvertFrom-Json
Set-TracDefaultsConfig -tracDefaultsPath $tracDefaults -jsonConfig $config

# Set log level
Set-EndpointLogLevel -loglevel "extended"

# Enable SDL
Set-EndpointSDL -loglevel "enaled"
```

### Service Control

```powershell
# Stop service
Stop-CheckPointService
Start-Sleep -Seconds 5

# Start service
Start-CheckPointService
Start-Sleep -Seconds 10

# Verify service is running
$info = Get-CheckPointInfo
if ($info) {
    Write-Host "Service is running"
}
```

## Advanced Usage

### Automated Connection with Retry

```powershell
function Connect-CheckPointVPNWithRetry {
    param(
        [string]$SiteName,
        [string]$Username,
        [string]$Password,
        [int]$MaxAttempts = 3,
        [int]$WaitSeconds = 10
    )

    for ($i = 1; $i -le $MaxAttempts; $i++) {
        Write-Host "Connection attempt $i of $MaxAttempts..."

        $result = Connect-CheckPointVPN -SiteName $SiteName -Username $Username -Password $Password

        if ($result.Success) {
            Write-Host "Connected successfully on attempt $i"
            return $true
        }

        if ($i -lt $MaxAttempts) {
            Write-Host "Connection failed. Waiting $WaitSeconds seconds before retry..."
            Start-Sleep -Seconds $WaitSeconds
        }
    }

    Write-Error "Failed to connect after $MaxAttempts attempts"
    return $false
}

# Usage
Connect-CheckPointVPNWithRetry -SiteName "Corporate VPN" -Username "user@company.com" -Password "MyPassword"
```

### Monitor Connection Status

```powershell
function Monitor-VPNConnection {
    param(
        [string]$SiteName,
        [int]$IntervalSeconds = 30,
        [switch]$ContinuousMode
    )

    do {
        $info = Get-CheckPointInfo -sitename $SiteName | Select-Object -First 1

        if ($info) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Write-Host "[$timestamp] Status: $($info.status)"

            # Check if connection is recent
            $isRecent = Test-IsRecentConnection -tracinfo $info -recenthourcount 1
            if (-not $isRecent) {
                Write-Warning "Last connection was more than 1 hour ago"
            }
        } else {
            Write-Warning "Could not retrieve connection information"
        }

        if ($ContinuousMode) {
            Start-Sleep -Seconds $IntervalSeconds
        }
    } while ($ContinuousMode)
}

# Usage
Monitor-VPNConnection -SiteName "Corporate VPN" -ContinuousMode -IntervalSeconds 60
```

### Installation Automation

```powershell
function Install-CheckPointWithConfig {
    param(
        [string]$InstallerPath,
        [string]$Language = "EN",
        [string]$UninstallPassword,
        [string]$VPNSite,
        [string]$VPNDisplayName,
        [string]$AuthMethod = "username-password"
    )

    # Install Check Point
    Write-Host "Installing Check Point Endpoint Security..."
    $process = Install-NewCheckPointVPN -msipath $InstallerPath -language $Language -uninstPasswd $UninstallPassword -SDL_ENABLED "true"
    $process.WaitForExit()

    if ($process.ExitCode -eq 0) {
        Write-Host "Installation completed successfully"

        # Wait for service to be ready
        Start-Sleep -Seconds 30

        # Create VPN site
        Write-Host "Creating VPN site..."
        $result = New-CheckPointVPNSite -site $VPNSite -displayName $VPNDisplayName -authenticationMethod $AuthMethod

        if ($result.Success) {
            Write-Host "VPN site created successfully"
        } else {
            Write-Warning "Failed to create VPN site"
            $result.Output
        }
    } else {
        Write-Error "Installation failed with exit code: $($process.ExitCode)"
    }
}

# Usage
Install-CheckPointWithConfig -InstallerPath "C:\Install\E86.90.msi" `
                              -Language "FR" `
                              -UninstallPassword "MyPassword123" `
                              -VPNSite "vpn.company.com" `
                              -VPNDisplayName "Corporate VPN" `
                              -AuthMethod "username-password"
```

### Feature Detection

```powershell
# Get installed features from registry or installation
$featureMask = 8265  # Example feature bitmask

# Convert to feature array
$features = ConvertTo-EPSInstalledFeatures -Features $featureMask
Write-Host "Installed features:"
$features | ForEach-Object { Write-Host "  - $_" }

# Convert to string with custom separator
$featuresString = ConvertTo-EPSInstalledFeatures -Features $featureMask -StringOutput -FeatureSeparatorChar ","
Write-Host "Features: $featuresString"

# Remove DA from output
$featuresWithoutDA = ConvertTo-EPSInstalledFeatures -Features $featureMask -StringOutput -RemoveDA
Write-Host "Features (excluding DA): $featuresWithoutDA"
```

### Configuration Backup and Restore

```powershell
# Load configuration
$tracDefaults = Get-CheckPointTracDefaults
$settings = [tracDefaultsSettings]::new($tracDefaults)

# Show current option values
Write-Host "Current log_level: $($settings.GetOptionValue('log_level'))"

# Modify options
$settings.SetOptionValue("log_level", "debug")
$settings.SetOptionValue("enable_ssl", "true")

# Save (automatically creates backup)
$settings.Save()
Write-Host "Configuration saved. Backup created."

# Manual backup
$backupPath = $settings.Backup()
Write-Host "Backup created at: $backupPath"
```

### Scheduled Connection

```powershell
# Create a scheduled task to connect to VPN at specific times
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument @"
-NoProfile -WindowStyle Hidden -Command "& {
    Import-Module PSSomeCheckPointEndpointThings
    Connect-CheckPointVPN -SiteName 'Corporate VPN' -Username 'user@company.com' -Password 'MyPassword'
}"
"@

$trigger = New-ScheduledTaskTrigger -Daily -At 8:00AM

Register-ScheduledTask -TaskName "ConnectCheckPointVPN" -Action $action -Trigger $trigger -Description "Automatically connect to Corporate VPN at 8 AM"
```

## Common Workflows

### Complete Site Setup Workflow

```powershell
# 1. Check if Check Point is installed
$product = Get-CheckPointProduct
if (-not $product) {
    Write-Error "Check Point is not installed"
    return
}

# 2. List existing sites
$existingSites = List-CheckPointSites
Write-Host "Existing sites:"
$existingSites | ForEach-Object { Write-Host "  - $_" }

# 3. Create new site if it doesn't exist
$newSiteName = "vpn.newcompany.com"
if ($existingSites -notcontains $newSiteName) {
    $result = New-CheckPointVPNSite -site $newSiteName -displayName "New Company VPN" -authenticationMethod "username-password"
    if ($result.Success) {
        Write-Host "Site created successfully"
    }
}

# 4. Test connection
$connectResult = Connect-CheckPointVPN -SiteName "New Company VPN" -Username "testuser" -Password "TestPassword123"
if ($connectResult.Success) {
    Write-Host "Test connection successful"

    # Wait a few seconds
    Start-Sleep -Seconds 5

    # Disconnect
    Disconnect-CheckPointVPN
}
```

### Troubleshooting Workflow

```powershell
# Enable extended logging
Set-EndpointLogLevel -loglevel "extended"
Set-EndpointSDL -loglevel "enaled"

# Get detailed information
$info = Get-CheckPointInfo
Write-Host "Connection Information:"
$info | Format-List *

# Check recent connection
$info | ForEach-Object {
    $isRecent = Test-IsRecentConnection -tracinfo $_ -recenthourcount 24
    Write-Host "Site: $($_.Connection)"
    Write-Host "Recent connection (last 24h): $isRecent"

    if ($_.PSObject.Properties.Name -contains "last_successful_update_time") {
        $lastConn = Get-LastConnection -tracinfo $_
        Write-Host "Last connection: $lastConn"
    }
}

# Get site details
$sites = List-CheckPointSites
$sites | ForEach-Object {
    Write-Host "`n=== Site: $_ ==="
    $siteInfo = Get-SiteInfo -sitename $_
    Write-Host "Properties:"
    $siteInfo.properties.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Key): $($_.Value)" }
    Write-Host "Gateways:"
    $siteInfo.gatewayList.GetEnumerator() | ForEach-Object { Write-Host "  $($_.Value)" }
}
```

### Migration to New Server

```powershell
# Export current site configurations
$currentSites = List-CheckPointSites
$exportData = @()

foreach ($siteName in $currentSites) {
    $siteInfo = Get-SiteInfo -sitename $siteName
    $exportData += [PSCustomObject]@{
        SiteName = $siteName
        Properties = $siteInfo.properties
        Gateways = $siteInfo.gatewayList
    }
}

# Save to file
$exportData | ConvertTo-Json -Depth 10 | Out-File "C:\Temp\checkpoint_sites_export.json"

# On new machine, import and recreate sites
$importData = Get-Content "C:\Temp\checkpoint_sites_export.json" | ConvertFrom-Json

foreach ($site in $importData) {
    # Extract gateway hostname from properties
    $gatewayHost = $site.Properties.gateway_ip_address  # Adjust based on actual property name

    # Recreate site
    New-CheckPointVPNSite -site $gatewayHost -displayName $site.SiteName -authenticationMethod "username-password"
}
```

## Module Structure

```
PSSomeCheckPointEndpointThings/
├── PSSomeCheckPointEndpointThings.psd1    # Module manifest
├── PSSomeCheckPointEndpointThings.psm1    # Module loader
├── README.md                               # This file
├── LICENSE                                 # PolyForm Noncommercial License
├── ConfigFile/                             # Configuration file management
│   ├── class-tracDefaultsSetting.ps1
│   ├── class-tracDefaultsSettings.ps1
│   ├── Get-CheckPointTracDefaults.ps1
│   ├── New-TracConfigFile.ps1
│   └── Set-TracDefaultsConfig.ps1
├── Configure/                              # Client configuration
│   ├── Set-EndpointLogLevel.ps1
│   └── Set-EndpointSDL.ps1
├── GetInfo/                                # Information retrieval
│   ├── Get-CheckPointInfo.ps1
│   ├── Get-CheckPointProduct.ps1
│   ├── Get-CheckPointRegKey.ps1
│   ├── Get-CheckPointTracExe.ps1
│   ├── Get-CheckPointTracInfo.ps1
│   └── Get-CheckPointVersion.ps1
├── Installation/                           # Installation utilities
│   ├── ConvertTo-EPSInstalledFeatures.ps1
│   └── Install-NewCheckPointVPN.ps1
├── Other/                                  # Utility functions
│   └── Get-CheckPointFile.ps1
├── Service/                                # Service control
│   ├── Start-CheckPointService.ps1
│   └── Stop-CheckPointService.ps1
├── VPNConnection/                          # VPN connection management
│   ├── Connect-CheckPointVPN.ps1
│   ├── Disconnect-CheckPointVPN.ps1
│   ├── Get-LastConnection.ps1
│   ├── Show-CheckPointConnectGUI.ps1
│   ├── Test-IsRecentConnection.ps1
│   └── Wait-VPNStatus.ps1
└── VPNSites/                               # VPN site management
    ├── Get-SiteInfo.ps1
    ├── List-CheckPointSites.ps1
    └── New-CheckPointVPNSite.ps1
```

## Check Point Endpoint Security Features

The `EPSFeatures` enum defines the following feature flags:

| Feature | Value | Description |
|---------|-------|-------------|
| DA | 1 | Data Awareness |
| FDE | 2 | Full Disk Encryption |
| ME | 4 | Media Encryption |
| FW1 | 8 | Firewall |
| COMP | 16 | Compliance |
| PC | 32 | Policy Control |
| AM | 64 | Anti-Malware |
| FF | 128 | Firewall Features |
| EC | 256 | Endpoint Compliance |
| SC | 512 | Security Compliance |
| URLF | 1024 | URL Filtering |
| DS | 2048 | Data Security |
| AB | 4096 | Application Blocking |
| DLP | 8192 | Data Loss Prevention |
| EFR | 65536 | Endpoint Forensics |
| TE | 131072 | Threat Emulation |

## Supported Authentication Methods

- **username-password**: Standard username and password
- **certificate**: Certificate-based authentication
- **p12-certificate**: PKCS#12 certificate
- **challenge-response**: Challenge-response authentication
- **securIDKeyFob**: SecurID with key fob
- **securIDPinPad**: SecurID with pin pad
- **SoftID**: Software-based token

## Troubleshooting

### Common Issues

#### trac.exe Not Found
```powershell
# Manually locate trac.exe
$tracExe = Get-CheckPointFile -filename "trac.exe"
if ($tracExe) {
    Write-Host "Found trac.exe at: $tracExe"
} else {
    Write-Error "trac.exe not found. Is Check Point installed?"
}
```

#### Connection Fails
```powershell
# Enable debug logging
Set-EndpointLogLevel -loglevel "extended"

# Try connection
$result = Connect-CheckPointVPN -SiteName "MySite" -Username "user" -Password "pass"

# Check output
$result.CommandResult | ForEach-Object { Write-Host $_ }

# Check service status
$info = Get-CheckPointInfo
$info | Format-List *
```

#### Service Won't Start
```powershell
# Stop service completely
Stop-CheckPointService
Start-Sleep -Seconds 10

# Check if process is still running
$processes = Get-Process | Where-Object { $_.ProcessName -like "*trac*" -or $_.ProcessName -like "*Check*" }
if ($processes) {
    Write-Warning "Check Point processes still running:"
    $processes | Format-Table ProcessName, Id, CPU
}

# Start service
Start-CheckPointService
Start-Sleep -Seconds 15

# Verify
$info = Get-CheckPointInfo
if ($info) {
    Write-Host "Service started successfully"
}
```

#### Configuration Changes Not Applied
```powershell
# Ensure service is stopped before modifying configuration
Stop-CheckPointService

# Modify configuration
$tracDefaults = Get-CheckPointTracDefaults
$config = @{ option1 = "value1" } | ConvertTo-Json | ConvertFrom-Json
Set-TracDefaultsConfig -tracDefaultsPath $tracDefaults -jsonConfig $config

# Restart service
Start-CheckPointService
```

## Security Notes

- **Password Storage**: This module does not store passwords. Always use secure credential management.
- **Plain-text Passwords**: The `Connect-CheckPointVPN` function requires plain-text passwords as per trac.exe requirements.
- **Administrator Rights**: Some operations may require administrator privileges.
- **Log Files**: Extended logging may contain sensitive information. Secure log files appropriately.
- **Configuration Backups**: The `tracDefaultsSettings` class automatically creates backups before modifying configuration.

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
