# PSSomeSystemThings

Windows system management utilities for PowerShell: system info, services, drives, registry, sessions, shortcuts, network mappings, environment paths, task scheduler, and user management.

## Requirements

- PowerShell 5.1 or later
- Windows operating system

## Installation

```powershell
# Clone or copy the module to a PowerShell modules directory
Copy-Item -Path ".\PSSomeSystemThings" -Destination "$env:USERPROFILE\Documents\PowerShell\Modules\PSSomeSystemThings" -Recurse

# Import the module
Import-Module PSSomeSystemThings
```

## Quick Start

```powershell
Import-Module PSSomeSystemThings

# Get system information
Get-SystemInfo
Get-OS

# Check services
Get-Service -Name "Spooler"
Test-Service -name "wuauserv"

# Get disk drive info
Get-DiskDrive
Get-InternalDrivesPartitions -PartitionsWithLetters

# Check if running as admin
Test-IsAdmin
```

## Functions

### Drive

| Function | Description |
|----------|-------------|
| `Get-DiskDrive` | Retrieves disk drive information via WMI |
| `Get-InternalDrivesPartitions` | Retrieves partitions from internal (fixed) disk drives |
| `Get-Volume` | Retrieves volume information with remote execution support |
| `Get-PhysicalMedia` | Retrieves physical media information via WMI |

### Environment

| Function | Description |
|----------|-------------|
| `Add-PathToEnvironment` | Adds a directory path to the system or user PATH environment variable |
| `Test-ExeInPath` | Searches for an executable file in PATH directories |

### Info

| Function | Description |
|----------|-------------|
| `Get-DotNetVersions` | Retrieves installed .NET Framework versions |
| `Get-IPConfiguration` | Retrieves IP configuration for active network interfaces |
| `Get-LocaleFormats` | Retrieves locale formats (fr-FR, fr, etc.) |
| `Get-OS` | Returns the operating system name |
| `Get-PSVersion` | Retrieves the PowerShell version |
| `Get-SystemArchitecture` | Retrieves the system architecture and its fallback architectures |
| `Get-SystemInfo` | Retrieves comprehensive system information |
| `Get-SystemLocales` | Retrieves system locales in various formats |
| `Test-WindowsFeatureInstalled` | Tests if a Windows Optional Feature is enabled |

### KnownFolders

| Function | Description |
|----------|-------------|
| `Get-System32Directory` | Returns the System32 directory path |
| `Get-SystemTemp` | Returns the system-level TEMP directory path |

### Map

| Function | Description |
|----------|-------------|
| `Get-RemoteShare` | Retrieves shared folders from a remote computer |
| `Get-SmbMapping` | Retrieves SMB mappings with persistence information |
| `New-NetworkMap` | Creates a new network drive mapping |
| `Remove-NetworkMap` | Removes a network drive mapping |
| `Test-NetworkMaps` | Tests the availability of network drive mappings |

### Other

| Function | Description |
|----------|-------------|
| `Invoke-AsSystem` | Executes a PowerShell script block as SYSTEM using a scheduled task |

### Process

| Function | Description |
|----------|-------------|
| `Get-ParentProcess` | Retrieves the parent process of a given process |
| `Get-ProcessChildProcess` | Gets child and grandchild processes of a given process via WMI |

### Registry

| Function | Description |
|----------|-------------|
| `Get-FileTypeShellExtensionCommand` | Retrieves the shell extension command for a file type |
| `Get-RemoteRegistryKey` | Retrieves registry key children from a remote computer |
| `Get-RemoteRegistryValue` | Retrieves a specific registry value from a remote computer |

### Services

| Function | Description |
|----------|-------------|
| `Get-Service` | Retrieves Windows services with remote execution support |
| `Remove-Service` | Removes (deletes) a Windows service |
| `Restart-Service` | Restarts Windows services with remote execution support |
| `Set-ServiceRecovery` | Configures service recovery options on a remote server |
| `Test-Service` | Tests whether a Windows service exists |
| `Wait-ServiceStatus` | Waits for a service to reach a specified status |

### Session

| Function | Description |
|----------|-------------|
| `Get-OpenedSessions` | Retrieves all logon sessions on a computer |

### Session / [RDSSession](Session/RDSSession/README.md)

| Function | Description |
|----------|-------------|
| `Get-RDSSession` | Lists RDS sessions with filtering by user, state, session ID. Supports detailed info |
| `Get-ComputerSession` | Retrieves detailed session information using WTSEnumerateSessionsEx |
| `Get-RDSSessionHistory` | Retrieves RDS session history from Event Logs (logons, logoffs, disconnections) |
| `Get-RDSSessionProcess` | Lists processes running in a specific RDS session via CIM/WMI |
| `Stop-RDSSession` | Logs off an RDS session (closes all applications) |
| `Disconnect-RDSSession` | Disconnects an RDS session while keeping applications running |
| `Send-RDSMessage` | Sends a popup message to an RDS session via WTSSendMessage |
| `Invoke-RDSSessionCommand` | Executes a scriptblock or launches a process in an RDS session |
| `Start-RDSShadow` | Initiates a shadow connection to view or control an RDS session |

### Shortcut

| Function | Description |
|----------|-------------|
| `Get-ShortcutInfo` | Retrieves properties of a Windows shortcut (.lnk) file |
| `New-Shortcut` | Creates a new Windows shortcut (.lnk) file |

### TaskScheduler

| Function | Description |
|----------|-------------|
| `Invoke-ScheduledTask` | Executes a script block via Windows Task Scheduler |

### User

| Function | Description |
|----------|-------------|
| `Get-CurrentUserGroups` | Get current user groups |
| `Test-IsAdmin` | Tests if the current PowerShell session is running as Administrator |
| `Test-IsCurrentUserLocalAdmin` | Tests if the current user is a member of the local Administrators group |

## Module Structure

```
PSSomeSystemThings/
├── PSSomeSystemThings.psd1        # Module manifest
├── PSSomeSystemThings.psm1        # Module loader
├── LICENSE                        # PolyForm Noncommercial License 1.0.0
├── README.md
├── Drive/                         # Disk and volume management
├── Environment/                   # PATH and environment utilities
├── Info/                          # System information and diagnostics
├── KnownFolders/                  # Well-known system folder paths
├── Map/                           # Network drive mapping
├── Other/                         # Miscellaneous utilities
├── Process/                       # Process management
├── Registry/                      # Registry access (local and remote)
├── Services/                      # Windows service management
├── Session/                       # User session management
│   └── RDSSession/                # RDS session management (WTS API)
├── Shortcut/                      # Windows shortcut (.lnk) management
├── TaskScheduler/                 # Scheduled task execution
└── User/                          # User and permission checks
```

## Author

**Loïc Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE).
