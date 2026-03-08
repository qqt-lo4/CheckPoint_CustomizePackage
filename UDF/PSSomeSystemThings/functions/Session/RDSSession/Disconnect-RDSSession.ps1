function Disconnect-RDSSession {
    <#
    .SYNOPSIS
        Disconnects an RDS session using native WTS API

    .DESCRIPTION
        Disconnects a Remote Desktop session while keeping applications running.
        Uses WTSDisconnectSession natively. Supports PowerShell remoting

    .PARAMETER SessionId
        ID of the session to disconnect

    .PARAMETER ComputerName
        Name of the RDS server. Default is local server

    .PARAMETER Credential
        PSCredential object for remote authentication

    .PARAMETER Session
        Existing PSSession to use for remote operations

    .PARAMETER Wait
        If specified, waits for disconnection to complete

    .PARAMETER Force
        Forces disconnection without confirmation prompt

    .OUTPUTS
        System.Boolean
        Returns $true if disconnection succeeded, $false otherwise

    .EXAMPLE
        Disconnect-RDSSession -SessionId 2
        Disconnects session ID 2

    .EXAMPLE
        $cred = Get-Credential
        Disconnect-RDSSession -SessionId 3 -ComputerName "RDS01" -Credential $cred -Wait -Force
        Disconnects session using credentials and waits for completion

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int]$SessionId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'Host', 'PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential,

        [System.Management.Automation.Runspaces.PSSession]$Session,

        [switch]$Wait,

        [switch]$Force
    )

    process {
        $params = Split-RemoteAndNativeParameters

        # Get session information first (for confirmation message)
        $sessionGetParams = @{ SessionId = $SessionId }
        $remoteParams = $params.Remote
        if ($remoteParams.Count -gt 0) {
            $sessionGetParams += $remoteParams
        }
        else {
            if ($ComputerName) { $sessionGetParams['ComputerName'] = $ComputerName }
        }

        $sessionInfo = Get-RDSSession @sessionGetParams | Where-Object { $_.SessionId -eq $SessionId }

        if (-not $sessionInfo) {
            Write-Error "Session ID $SessionId not found on $ComputerName"
            return $false
        }

        if ($sessionInfo.State -eq 'Disconnected') {
            Write-Warning "Session $SessionId is already disconnected"
            return $true
        }

        # Confirmation
        $message = "Disconnect session $SessionId ($($sessionInfo.UserName)@$($sessionInfo.DomainName)) on $($sessionInfo.ComputerName)"
        if (-not $Force -and -not $PSCmdlet.ShouldProcess($message, "Disconnect-RDSSession")) {
            Write-Verbose "Disconnection cancelled by user"
            return $false
        }

        $scriptBlock = {
            param($nativeParams)

            # Load WTS API types if not already loaded
            if (-not ([System.Management.Automation.PSTypeName]'WTSApi').Type) {
                Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public enum WTS_CONNECTSTATE_CLASS
{
    Active,
    Connected,
    ConnectQuery,
    Shadow,
    Disconnected,
    Idle,
    Listen,
    Reset,
    Down,
    Init
}

public enum WTS_INFO_CLASS
{
    WTSInitialProgram,
    WTSApplicationName,
    WTSWorkingDirectory,
    WTSOEMId,
    WTSSessionId,
    WTSUserName,
    WTSWinStationName,
    WTSDomainName,
    WTSConnectState,
    WTSClientBuildNumber,
    WTSClientName,
    WTSClientDirectory,
    WTSClientProductId,
    WTSClientHardwareId,
    WTSClientAddress,
    WTSClientDisplay,
    WTSClientProtocolType,
    WTSIdleTime,
    WTSLogonTime,
    WTSIncomingBytes,
    WTSOutgoingBytes,
    WTSIncomingFrames,
    WTSOutgoingFrames,
    WTSClientInfo,
    WTSSessionInfo
}

[StructLayout(LayoutKind.Sequential)]
public struct WTS_SESSION_INFO
{
    public int SessionId;
    public IntPtr pWinStationName;
    public WTS_CONNECTSTATE_CLASS State;
}

public class WTSApi
{
    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern IntPtr WTSOpenServer(string pServerName);

    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern void WTSCloseServer(IntPtr hServer);

    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern bool WTSEnumerateSessions(
        IntPtr hServer,
        int Reserved,
        int Version,
        out IntPtr ppSessionInfo,
        out int pCount);

    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern void WTSFreeMemory(IntPtr pMemory);

    [DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern bool WTSQuerySessionInformation(
        IntPtr hServer,
        int sessionId,
        WTS_INFO_CLASS wtsInfoClass,
        out IntPtr ppBuffer,
        out int pBytesReturned);

    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern bool WTSDisconnectSession(IntPtr hServer, int sessionId, bool bWait);

    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern bool WTSLogoffSession(IntPtr hServer, int sessionId, bool bWait);
}
"@ -ErrorAction SilentlyContinue
            }

            try {
                $serverHandle = [IntPtr]::Zero

                try {
                    # Always use local server since scriptblock runs on target machine
                    # Pass $null for local server (WTSOpenServer expects string, not IntPtr)
                    $serverHandle = [WTSApi]::WTSOpenServer($null)

                    if ($serverHandle -eq [IntPtr]::Zero) {
                        throw "Unable to open connection to local WTS server"
                    }

                    # Disconnect session
                    if ([WTSApi]::WTSDisconnectSession($serverHandle, $nativeParams.SessionId, $nativeParams.Wait)) {
                        return $true
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        $errorMessage = [System.ComponentModel.Win32Exception]::new($errorCode).Message
                        throw "Disconnection failed: $errorMessage (Code: $errorCode)"
                    }
                }
                finally {
                    if ($serverHandle -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSCloseServer($serverHandle)
                    }
                }
            }
            catch {
                Write-Error "Error: $_"
                return $false
            }
        }

        # Execute
        try {
            $nativeParams = $params.Native

            if ($remoteParams.Count -gt 0) {
                $result = Invoke-Command @remoteParams -ScriptBlock $scriptBlock -ArgumentList $nativeParams
            }
            else {
                $result = & $scriptBlock -nativeParams $nativeParams
            }

            if ($result) {
                Write-Verbose "Session $SessionId disconnected successfully"
            }
            return $result
        }
        catch {
            Write-Error "Error disconnecting session: $_"
            return $false
        }
    }
}
