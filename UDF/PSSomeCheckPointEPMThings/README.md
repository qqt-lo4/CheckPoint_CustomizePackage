# PSSomeCheckPointEPMThings

A PowerShell module wrapping the Check Point Endpoint Policy Manager (EPM) on-premise GraphQL API: authentication, computer management, policy rules, package operations, network objects, and service definitions.

## Features

### Connect
Authenticate and maintain sessions with the EPM management server.

| Function | Description |
|---|---|
| `Connect-EPSAPI` | Authenticates to the EPM on-premise server via GraphQL. Returns a connection object with `CallAPI()`, `CallAPIGet()`, and `Reconnect()` methods. Supports `-GlobalVar` to store the connection in `$Global:EPSAPI`. |
| `Invoke-KeepAlive` | Sends a keep-alive request to prevent session timeout. |

### Computers
Query and inspect managed endpoints.

| Function | Description |
|---|---|
| `Get-EPSComputer` | Retrieves endpoints by ID, name, or paginated list with filters and sorting. Returns detailed info including deployed policies, anti-malware status, FDE status, compliance, and more. |
| `Get-EPSComputerPolicies` | Retrieves deployed and enforced policy details for a specific computer (by name, ID, or object). Returns feature name, policy name, and version information. |

### Filter & Sorting
Build filter and sorting descriptors for computer queries.

| Function | Description |
|---|---|
| `New-EPSComputerFilter` | Creates a filter hashtable for `Get-EPSComputer`. Supports `-eq` (contains), `-ge` (greater), and `-le` (smaller) comparison operators. |
| `New-EPSComputerSorting` | Creates a sorting descriptor hashtable with column name and ascending/descending direction. |

### Rules
Manage endpoint security policy rules.

| Function | Description |
|---|---|
| `Get-RuleSettings` | Retrieves comprehensive policy rule settings including web protection, threat emulation, antivirus, EDR, anti-ransomware, firewall rules, application control, full disk encryption, and more. Supports filtering by rule ID, family, and connection state. |
| `Get-RulesJob` | Initiates a job to gather rules from the EPM server. Returns a job ID. |
| `Get-RulesReadyToInstall` | Retrieves the list of modified rules that are ready to be pushed to endpoints. Returns an object with `rulesIds`. |

### Install
Push policy rules to managed endpoints.

| Function | Description |
|---|---|
| `Get-RulesToInstallJob` | Retrieves the list of rules queued for installation as a job. |
| `Invoke-InstallPolicyJob` | Triggers the installation of one or more policy rules by their IDs. Returns the install job ID. |

### Jobs
Monitor asynchronous operations.

| Function | Description |
|---|---|
| `Get-EPSJobStatus` | Retrieves the status of a job by its ID via the REST API. |
| `Get-Notifications` | Retrieves all notifications from the EPM server (ID, status, progress, message, timestamps). |
| `Wait-EPSJobEnd` | Polls a job until completion, displaying a progress bar. Returns the final job status. |

### Packages
Manage endpoint agent packages and downloads.

| Function | Description |
|---|---|
| `Get-Packages` | Retrieves all available packages with version, type, platform, features, and status flags (isInstalled, isLatest, isRecommended). |
| `Get-ExportPackages` | Retrieves export package configurations including blade selection, VPN site info, and dependency settings. |
| `Download-EPSPackage` | Downloads a dynamic package from the EPM server. Supports `-waitEnd` to block until download completes and save the file locally. |
| `Get-LatestAgentFromCheckPoint` | Synchronously fetches the latest endpoint agent from Check Point (starts the job and waits for completion). |
| `Get-LatestAgentFromCheckPointJob` | Triggers an asynchronous job to download and install the latest endpoint agent. Returns a job ID. |
| `Test-AlwaysGetLatestPackage` | Checks whether the server is configured to always automatically retrieve the latest agent. |

### Objects
Query and create network objects, services, and groups used in firewall rules.

| Function | Description |
|---|---|
| `Get-ObjectsByName` | Looks up objects by an array of names. Returns uid, name, type, and __typename. |
| `New-NetworkObject` | Creates or updates a network (subnet) object with IPv4 or IPv6 addressing. |

<details>
<summary>Network & Address Objects</summary>

| Function | Description |
|---|---|
| `Get-NetworkObjects` | Retrieves all network (subnet) objects with IPv4/IPv6 subnet and mask info. |
| `Get-NetworkGroups` | Retrieves all network groups with their member objects. |
| `Get-Hosts` | Retrieves all host objects with their IPv4 and IPv6 addresses. |
| `Get-EPSAddressRanges` | Retrieves all address range objects with first/last IPv4 and IPv6 addresses. |
| `Get-SiteObjects` | Retrieves all site objects with their host property. |
| `Get-SiteGroups` | Retrieves all site groups with their member sites. |

</details>

<details>
<summary>Service Objects</summary>

| Function | Description |
|---|---|
| `Get-TCPServices` | Retrieves all TCP service definitions with destination and source ports. |
| `Get-UDPServices` | Retrieves all UDP service definitions with destination and source ports. |
| `Get-ICMPServices` | Retrieves all ICMP service definitions with ICMP type and code. |
| `Get-ICMPv6Services` | Retrieves all ICMPv6 service definitions with ICMP type and code. |
| `Get-OtherServices` | Retrieves all non-TCP/UDP/ICMP service definitions with protocol number. |
| `Get-ServiceGroups` | Retrieves all service groups with their member services and ports. |

</details>

## Requirements

- **PowerShell** 5.1 or later
- **Check Point Endpoint Policy Manager** on-premise management server with GraphQL API enabled
- Network access to the EPM server (default port: 443)
- Valid EPM administrator credentials

## Installation

```powershell
# Clone or copy the module to a PowerShell module path
Copy-Item -Path ".\PSSomeCheckPointEPMThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeCheckPointEPMThings" -Recurse

# Or import directly
Import-Module ".\PSSomeCheckPointEPMThings\PSSomeCheckPointEPMThings.psd1"
```

## Quick Start

### Connect to the EPM server

```powershell
# Authenticate and store the connection globally
$secPassword = Read-Host -AsSecureString -Prompt "Password"
Connect-EPSAPI -Server "epm.example.com" -Username "admin" -Password $secPassword `
               -IgnoreSSLError -GlobalVar

# The connection is now available as $Global:EPSAPI
# All other functions use it automatically
```

### Query computers

```powershell
# Get a computer by name
$pc = Get-EPSComputer -Name "WORKSTATION01"

# List computers with filtering and sorting
$filter = New-EPSComputerFilter -Column "computerName" -eq -Value "PC"
$sort = New-EPSComputerSorting -Column "computerLastConnection" -Descending
$computers = Get-EPSComputer -filter $filter -sorting $sort -pageSize 50

# Get deployed policies for a computer
Get-EPSComputerPolicies -Name "WORKSTATION01"
```

### Manage policy rules

```powershell
# Get comprehensive rule settings
$rules = Get-RuleSettings

# Get rules ready to push
$pending = Get-RulesReadyToInstall
Write-Host "Rules pending installation: $($pending.rulesIds.Count)"

# Install pending rules
$jobId = Invoke-InstallPolicyJob -RuleIds $pending.rulesIds
Wait-EPSJobEnd -Id $jobId
```

### Work with packages

```powershell
# List all available packages
$packages = Get-Packages
$packages | Where-Object { $_.isLatest } | Select-Object name, version, platform

# Download a package and wait for completion
$file = Download-EPSPackage -softwarePackageId $packageId -waitEnd -OutputFolder "C:\Temp"
Write-Host "Downloaded: $($file.FullName)"

# Fetch the latest agent from Check Point
Get-LatestAgentFromCheckPoint
```

### Query network objects

```powershell
# Get all network objects
$networks = Get-NetworkObjects
$hosts = Get-Hosts
$tcpServices = Get-TCPServices

# Look up objects by name
$objects = Get-ObjectsByName -Names @("Any", "InternalNetwork", "HTTP")

# Create a network object
New-NetworkObject -Name "ServerSubnet" -subnet4 "10.0.1.0" -mask__length4 "24"
```

## Module Structure

```
PSSomeCheckPointEPMThings/
├── PSSomeCheckPointEPMThings.psd1    # Module manifest
├── PSSomeCheckPointEPMThings.psm1    # Module loader (dot-sources all .ps1 files)
├── README.md                         # This file
├── LICENSE                           # PolyForm Noncommercial License 1.0.0
├── Connect/                          # Authentication & session management (2 functions)
├── Computers/                        # Endpoint queries (2 functions)
├── Filter/                           # Filter builder (1 function)
├── Sorting/                          # Sorting builder (1 function)
├── Rules/                            # Policy rules (3 functions)
├── Install/                          # Policy installation (2 functions)
├── Jobs/                             # Job monitoring (3 functions)
├── Packages/                         # Agent packages (6 functions)
└── Objects/                          # Network objects & services (14 functions)
    ├── AddressRanges/
    ├── Hosts/
    ├── ICMPServices/
    ├── ICMPv6Services/
    ├── NetworkGroups/
    ├── NetworkObjects/
    ├── OtherServices/
    ├── ServiceGroups/
    ├── SiteGroups/
    ├── SiteObjects/
    ├── TCPServices/
    └── UDPServices/
```

## API Pattern

All functions follow a consistent pattern:

1. Accept an optional `-EPSAPI` connection object (defaults to `$Global:EPSAPI`)
2. Send a GraphQL query or mutation via `CallAPI()`, or a REST GET request via `CallAPIGet()`
3. Auto-reconnect on authentication errors
4. Return the relevant data from the API response

```powershell
# Explicit connection object
$result = Get-Packages -EPSAPI $myConnection

# Or use the global variable (set by Connect-EPSAPI -GlobalVar)
$result = Get-Packages
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). See the [LICENSE](LICENSE) file for details.

In short:
- **Non-commercial use only** — You may use, modify, and distribute this software for any non-commercial purpose.
- **Attribution required** — You must include a copy of the license terms with any distribution.
- **No warranty** — The software is provided as-is.
