function Send-RDSMessage {
    <#
    .SYNOPSIS
        Sends a message to an RDS session using WTSSendMessage

    .DESCRIPTION
        Sends a native popup message to a session via WTS API.
        Supports PowerShell remoting with Credential and Session parameters

    .PARAMETER SessionId
        ID of the destination session

    .PARAMETER Message
        Message text to send

    .PARAMETER Title
        Window title for the message

    .PARAMETER ComputerName
        Name of the RDS server. Default is local server

    .PARAMETER Credential
        PSCredential object for remote authentication

    .PARAMETER Session
        Existing PSSession to use for remote operations

    .PARAMETER Wait
        If specified, waits for user acknowledgment

    .PARAMETER Timeout
        Wait timeout in seconds (0 = infinite)

    .PARAMETER MessageType
        Type of message box icon to display (Information, Warning, Error, Question).
        Default is Information (blue "i" icon)

    .PARAMETER ButtonType
        Type of buttons to display (OK, OkCancel, YesNo, YesNoCancel, RetryCancel, AbortRetryIgnore).
        Default is OK. Use with -Wait to get user's response.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns an object containing:
        - Success: Boolean indicating if message was sent
        - Response: Numeric code of button clicked (1-7)
        - ButtonClicked: User-friendly name of button clicked (OK, Cancel, Yes, No, Retry, Abort, Ignore)

    .EXAMPLE
        Send-RDSMessage -SessionId 2 -Message "Maintenance in 10 minutes"
        Sends a simple message with information icon

    .EXAMPLE
        Send-RDSMessage -SessionId 2 -Message "Critical update required!" -MessageType Warning
        Sends a message with yellow warning icon

    .EXAMPLE
        Send-RDSMessage -SessionId 2 -Message "Error detected in your session" -MessageType Error
        Sends a message with red error icon

    .EXAMPLE
        $cred = Get-Credential
        Send-RDSMessage -SessionId 3 -Message "Save your work" -Title "WARNING" -ComputerName "RDS01" -Credential $cred -Wait -MessageType Warning
        Sends a warning message with credentials and waits for acknowledgment

    .EXAMPLE
        $result = Send-RDSMessage -SessionId 2 -Message "Do you want to save before logout?" -Title "Confirmation" -MessageType Question -ButtonType YesNo -Wait
        if ($result.ButtonClicked -eq 'Yes') {
            # User clicked Yes - trigger save
        }
        Sends a question with Yes/No buttons and checks user response

    .EXAMPLE
        $result = Send-RDSMessage -SessionId 2 -Message "Application crashed. Retry?" -MessageType Error -ButtonType RetryCancel -Wait
        if ($result.Response -eq 4) {  # IDRETRY = 4
            # Restart application
        }
        Sends error message with Retry/Cancel buttons

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int]$SessionId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [string]$Title = "System Message",

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'Host', 'PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential,

        [System.Management.Automation.Runspaces.PSSession]$Session,

        [switch]$Wait,

        [int]$Timeout = 0,

        [ValidateSet('Information', 'Warning', 'Error', 'Question')]
        [string]$MessageType = 'Information',

        [ValidateSet('OK', 'OkCancel', 'YesNo', 'YesNoCancel', 'RetryCancel', 'AbortRetryIgnore')]
        [string]$ButtonType = 'OK'
    )

    process {
        $params = Split-RemoteAndNativeParameters

        # Verify session exists
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
            Write-Error "Session ID $SessionId not found"
            return [PSCustomObject]@{
                Success       = $false
                Response      = $null
                ButtonClicked = $null
            }
        }

        $scriptBlock = {
            param($nativeParams)

            # Define WTSSendMessage
            if (-not ([System.Management.Automation.PSTypeName]'WTSMessage').Type) {
                Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class WTSMessage
{
    [DllImport("wtsapi32.dll", SetLastError = true)]
    public static extern bool WTSSendMessage(
        IntPtr hServer,
        int SessionId,
        string pTitle,
        int TitleLength,
        string pMessage,
        int MessageLength,
        int Style,
        int Timeout,
        out int pResponse,
        bool bWait);
}
"@ -ErrorAction SilentlyContinue
            }

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

                    # Map MessageType to Windows message box icon styles
                    $iconStyle = switch ($nativeParams.MessageType) {
                        'Information' { 0x40 }  # MB_ICONINFORMATION - Blue "i"
                        'Warning'     { 0x30 }  # MB_ICONWARNING - Yellow "!"
                        'Error'       { 0x10 }  # MB_ICONERROR - Red "X"
                        'Question'    { 0x20 }  # MB_ICONQUESTION - Blue "?"
                        default       { 0x40 }  # Default to Information
                    }

                    # Map ButtonType to Windows message box button styles
                    $buttonStyle = switch ($nativeParams.ButtonType) {
                        'OK'                { 0x00 }  # MB_OK - OK button only
                        'OkCancel'          { 0x01 }  # MB_OKCANCEL - OK and Cancel buttons
                        'AbortRetryIgnore'  { 0x02 }  # MB_ABORTRETRYIGNORE - Abort, Retry, and Ignore buttons
                        'YesNoCancel'       { 0x03 }  # MB_YESNOCANCEL - Yes, No, and Cancel buttons
                        'YesNo'             { 0x04 }  # MB_YESNO - Yes and No buttons
                        'RetryCancel'       { 0x05 }  # MB_RETRYCANCEL - Retry and Cancel buttons
                        default             { 0x00 }  # Default to OK
                    }

                    # Combine icon and button styles (they are OR'd together)
                    $style = $iconStyle -bor $buttonStyle
                    $response = 0

                    # Function to convert numeric response to user-friendly button name
                    function Get-ButtonName {
                        param([int]$ResponseCode)
                        switch ($ResponseCode) {
                            1 { return 'OK' }       # IDOK
                            2 { return 'Cancel' }   # IDCANCEL
                            3 { return 'Abort' }    # IDABORT
                            4 { return 'Retry' }    # IDRETRY
                            5 { return 'Ignore' }   # IDIGNORE
                            6 { return 'Yes' }      # IDYES
                            7 { return 'No' }       # IDNO
                            default { return $null }
                        }
                    }

                    $result = [WTSMessage]::WTSSendMessage(
                        $serverHandle,
                        $nativeParams.SessionId,
                        $nativeParams.Title,
                        $nativeParams.Title.Length,
                        $nativeParams.Message,
                        $nativeParams.Message.Length,
                        $style,
                        $nativeParams.Timeout,
                        [ref]$response,
                        $nativeParams.Wait
                    )

                    if ($result) {
                        return [PSCustomObject]@{
                            Success       = $true
                            Response      = $response
                            ButtonClicked = Get-ButtonName -ResponseCode $response
                        }
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        throw "Send failed: $([System.ComponentModel.Win32Exception]::new($errorCode).Message)"
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
                return [PSCustomObject]@{
                    Success       = $false
                    Response      = $null
                    ButtonClicked = $null
                }
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

            if ($result.Success) {
                Write-Verbose "Message sent successfully to session $SessionId"
            }
            return $result
        }
        catch {
            Write-Error "Error sending message: $_"
            return [PSCustomObject]@{
                Success       = $false
                Response      = $null
                ButtonClicked = $null
            }
        }
    }
}
