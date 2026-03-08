function Stop-RDSSession {
    <#
    .SYNOPSIS
        Closes an RDS session using native WTS API

    .DESCRIPTION
        Completely closes a Remote Desktop session (logoff) using WTSLogoffSession.
        All applications will be closed. Supports PowerShell remoting

    .PARAMETER SessionId
        ID of the session to close

    .PARAMETER UserName
        Username of the session to close. Supports wildcards and "domain\username" format.
        Use ".\username" to match the local machine name.
        If multiple sessions match, all will be closed

    .PARAMETER ComputerName
        Name of the RDS server. Default is local server

    .PARAMETER Credential
        PSCredential object for remote authentication

    .PARAMETER Session
        Existing PSSession to use for remote operations

    .PARAMETER Wait
        If specified, waits for logoff to complete

    .PARAMETER Force
        Forces logoff without confirmation prompt

    .OUTPUTS
        System.Boolean
        Returns $true if logoff succeeded, $false otherwise

    .EXAMPLE
        Stop-RDSSession -SessionId 2
        Closes session ID 2

    .EXAMPLE
        Stop-RDSSession -UserName "jdoe"
        Closes all sessions for user "jdoe"

    .EXAMPLE
        $cred = Get-Credential
        Stop-RDSSession -SessionId 3 -ComputerName "RDS01" -Credential $cred -Wait -Force
        Closes session using credentials and waits for completion

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High', DefaultParameterSetName = 'BySessionId')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'BySessionId', ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int]$SessionId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByUser')]
        [Alias('User')]
        [SupportsWildcards()]
        [string]$UserName,

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
        $remoteParams = $params.Remote

        # Build base parameters for Get-RDSSession
        $sessionGetParams = @{}
        if ($remoteParams.Count -gt 0) {
            $sessionGetParams += $remoteParams
        }
        else {
            if ($ComputerName) { $sessionGetParams['ComputerName'] = $ComputerName }
        }

        # Find sessions based on parameter set
        if ($PSCmdlet.ParameterSetName -eq 'ByUser') {
            $sessionGetParams['UserName'] = $UserName
            $sessions = Get-RDSSession @sessionGetParams

            if (-not $sessions) {
                Write-Error "No session found for user '$UserName' on $ComputerName"
                return $false
            }

            # Process each matching session recursively
            foreach ($sess in $sessions) {
                $stopParams = @{
                    SessionId    = $sess.SessionId
                    ComputerName = $ComputerName
                }
                if ($Credential) { $stopParams['Credential'] = $Credential }
                if ($Session) { $stopParams['Session'] = $Session }
                if ($Wait) { $stopParams['Wait'] = $true }
                if ($Force) { $stopParams['Force'] = $true }
                Stop-RDSSession @stopParams
            }
            return
        }

        # BySessionId parameter set
        $sessionGetParams['SessionId'] = $SessionId
        $sessionInfo = Get-RDSSession @sessionGetParams | Where-Object { $_.SessionId -eq $SessionId }

        if (-not $sessionInfo) {
            Write-Error "Session ID $SessionId not found on $ComputerName"
            return $false
        }

        if ($sessionInfo.State -eq 'Listen') {
            Write-Error "Cannot logoff a Listen session"
            return $false
        }

        # Confirmation
        $message = "Logoff session $SessionId ($($sessionInfo.UserName)@$($sessionInfo.DomainName)) on $($sessionInfo.ComputerName) - All applications will be closed!"
        if (-not $Force -and -not $PSCmdlet.ShouldProcess($message, "Stop-RDSSession")) {
            Write-Verbose "Logoff cancelled by user"
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

                    # Logoff session
                    if ([WTSApi]::WTSLogoffSession($serverHandle, $nativeParams.SessionId, $nativeParams.Wait)) {
                        return $true
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        $errorMessage = [System.ComponentModel.Win32Exception]::new($errorCode).Message
                        throw "Logoff failed: $errorMessage (Code: $errorCode)"
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
                Write-Verbose "Session $SessionId logged off successfully"
            }
            return $result
        }
        catch {
            Write-Error "Error logging off session: $_"
            return $false
        }
    }
}
