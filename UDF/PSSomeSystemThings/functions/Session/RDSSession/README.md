# RDSSession

PowerShell functions for managing Remote Desktop Services (RDS) sessions using native Windows Terminal Services (WTS) API calls. No dependency on `qwinsta`, `quser`, or other text-based commands.

All functions support PowerShell remoting via `-Credential` or `-Session` parameters.

## Functions (9)

### Session Information

| Function | Description |
|----------|-------------|
| `Get-RDSSession` | Lists RDS sessions with filtering by user, state, session ID. Supports `-Detailed` for extended info (logon time, idle time, client address, display, drive/printer redirection, shadow settings) |
| `Get-ComputerSession` | Retrieves detailed session information using `WTSEnumerateSessionsEx`. Supports multiple computers and `-FlattenOutput` |
| `Get-RDSSessionHistory` | Queries TerminalServices-LocalSessionManager event logs for session history (logons, logoffs, disconnections, reconnections). Supports `-Last N` days, `-EventType`, `-StartTime`/`-EndTime` |
| `Get-RDSSessionProcess` | Lists processes running in a specific session via CIM/WMI |

### Session Actions

| Function | Description |
|----------|-------------|
| `Stop-RDSSession` | Logs off a session (closes all applications). Supports `-UserName` filter and `-Force` |
| `Disconnect-RDSSession` | Disconnects a session while keeping applications running |
| `Send-RDSMessage` | Sends a popup message to a session via `WTSSendMessage`. Supports message types (Information, Warning, Error, Question) and button types (OK, YesNo, RetryCancel, etc.) with response capture |
| `Invoke-RDSSessionCommand` | Executes a scriptblock or launches a process in a session. Process mode uses `WTSQueryUserToken`/`CreateProcessAsUser` for interactive desktop visibility |
| `Start-RDSShadow` | Initiates a shadow connection to view or control a session via `mstsc.exe`. Supports `-Control` and `-NoConsent` modes |

## Usage Examples

```powershell
# List active sessions on a remote server
Get-RDSSession -ComputerName "RDS01" -State Active -ExcludeSystemSessions

# Get detailed session info with logon time, idle time, client address
Get-RDSSession -ComputerName "RDS01" -Detailed

# Find sessions for a specific user
Get-RDSSession -UserName "john.doe" -ComputerName "RDS01"

# View session history from the last 7 days
Get-RDSSessionHistory -Last 7 -ComputerName "RDS01"

# Send a warning message to a session
Send-RDSMessage -SessionId 2 -Message "Maintenance in 10 minutes" -MessageType Warning

# Ask user a question and capture response
$result = Send-RDSMessage -SessionId 2 -Message "Save before logout?" -ButtonType YesNo -Wait
if ($result.ButtonClicked -eq 'Yes') { ... }

# Log off disconnected sessions
Get-RDSSession -State Disconnected -Session $s | Stop-RDSSession -Force

# Shadow a session with full control
Start-RDSShadow -SessionId 2 -ComputerName "RDS01" -Control

# Launch a process in the user's interactive session
Invoke-RDSSessionCommand -SessionId 2 -ComputerName "RDS01" -FilePath "notepad.exe"

# Run a scriptblock with session context
Invoke-RDSSessionCommand -SessionId 2 -Session $s -ScriptBlock {
    param($SessionInfo)
    "User $($SessionInfo.UserName) is in state $($SessionInfo.State)"
}
```

## Pipeline Support

Functions support pipeline chaining via `ValueFromPipelineByPropertyName` on `SessionId`, `ComputerName`:

```powershell
# Find and disconnect idle sessions
Get-RDSSession -State Disconnected -ComputerName "RDS01" | Disconnect-RDSSession -Force

# List processes in all active sessions
Get-RDSSession -State Active -ComputerName "RDS01" | Get-RDSSessionProcess

# Complete support workflow
$session = Get-RDSSession -UserName "john.doe" -ComputerName "RDS01" -Session $s
$result = Send-RDSMessage -SessionId $session.SessionId -Message "Support wants to help. Accept?" `
    -ButtonType YesNo -Wait -Session $s
if ($result.ButtonClicked -eq 'Yes') {
    Start-RDSShadow -SessionId $session.SessionId -ComputerName $session.ComputerName -Control
}
```

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+
- Administrator privileges for some operations (shadow, process launch in session)
- `Start-RDSShadow` requires `mstsc.exe` and appropriate GPO configuration for shadow permissions

## Author

Loic Ade
