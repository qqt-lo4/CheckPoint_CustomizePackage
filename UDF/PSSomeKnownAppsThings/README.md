# PSSomeKnownAppsThings

PowerShell module providing launchers and helpers for common applications: admin tools (PAExec, PuTTY, MSTSC), OneDrive management, Nmap, web browsers, Microsoft Teams, and Windows File Explorer.

## Requirements

- PowerShell 5.1 or later
- Windows operating system
- Optional: PSSomeCoreThings module (for `Invoke-ThisFunctionRemotely`, `Get-ScriptDir`, etc.)

## Installation

Import the module from the `UDF` directory:

```powershell
Import-Module "G:\Scripts\PowerShell\UDF\PSSomeKnownAppsThings"
```

## Functions

### AdminTools (6)

| Function | Description |
|---|---|
| `Invoke-PAExec` | Runs a command on a remote computer using PAExec |
| `Invoke-PAExecRemoteShell` | Opens a remote shell (cmd/powershell/pwsh) via PAExec |
| `Search-PAExecPath` | Searches for the PAExec executable path |
| `Invoke-Putty` | Launches a PuTTY session (SSH v1/v2 or Telnet) |
| `Search-PuttyPath` | Searches for the PuTTY executable path |
| `Invoke-MSTSC` | Launches a Remote Desktop (MSTSC) session |

### OneDrive (4)

| Function | Description |
|---|---|
| `Get-OneDriveClient` | Gets the OneDrive client executable path |
| `Start-OneDrive` | Starts the OneDrive client in the background |
| `Exit-OneDrive` | Shuts down the OneDrive client |
| `Restart-OneDrive` | Restarts the OneDrive client |

### Other (6)

| Function | Description |
|---|---|
| `Find-NMap` | Finds the Nmap/Zenmap installation on the system |
| `Start-Nmap` | Launches an Nmap scan via Zenmap with predefined profiles |
| `Invoke-Browser` | Opens a URL in the default or a specific browser |
| `Invoke-BrowserWhois` | Opens a WHOIS lookup in the browser |
| `Restart-Teams` | Restarts Microsoft Teams |
| `Invoke-WindowsFileExplorer` | Opens Windows File Explorer at a specific path |

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE).

## Author

Loïc Ade
