function Get-RDSSession {
    <#
    .SYNOPSIS
        Lists all Remote Desktop sessions using WTS API

    .DESCRIPTION
        Retrieves all sessions using Windows Terminal Services (WTS) API natively,
        without depending on qwinsta or other text-based commands.
        Supports PowerShell remoting with Credential and Session parameters.
        Can retrieve detailed information including LogonTime, IdleTime, ClientAddress,
        ClientBuildNumber, ClientDirectory, ClientDisplay, and SessionInfo
        (drive/printer redirection, shadow settings, initial program, etc.).

    .PARAMETER SessionId
        Filter by a specific session ID

    .PARAMETER ComputerName
        Name of the RDS server to query. Default is local server

    .PARAMETER Credential
        PSCredential object for remote authentication

    .PARAMETER Session
        Existing PSSession to use for remote operations

    .PARAMETER State
        Filter sessions by connection state (Active, Disconnected, Idle, Listen, etc.)

    .PARAMETER UserName
        Filter sessions by username. Supports wildcards (e.g. "*admin*") and
        "domain\username" format. Use ".\username" to match the local machine name

    .PARAMETER ExcludeSystemSessions
        Exclude system sessions (session 0 and services sessions)

    .PARAMETER Detailed
        Include extended information (LogonTime, IdleTime, ClientAddress, ClientBuildNumber,
        ClientDirectory, ClientDisplay resolution, and SessionInfo with drive/printer
        redirection settings, shadow mode, initial program, etc.)

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns objects containing SessionId, UserName, State, ClientName, ClientProtocol, etc.
        With -Detailed: also includes LogonTime, IdleTime, ClientAddress, ClientBuildNumber,
        ClientDirectory, ClientDisplay, and SessionInfo

    .EXAMPLE
        Get-RDSSession
        Lists all sessions on local server

    .EXAMPLE
        Get-RDSSession -ComputerName "RDS-Server01" -State Active
        Lists only active sessions on RDS-Server01

    .EXAMPLE
        Get-RDSSession -UserName "*admin*" -ExcludeSystemSessions
        Lists sessions for users matching "*admin*", excluding system sessions

    .EXAMPLE
        $cred = Get-Credential
        Get-RDSSession -ComputerName "RDS-Server01" -Credential $cred -Detailed
        Lists sessions with detailed information using alternate credentials

    .EXAMPLE
        $session = New-PSSession -ComputerName "RDS-Server01"
        Get-RDSSession -Session $session -State Disconnected | Stop-RDSSession -Force
        Gets disconnected sessions and logs them off using an existing PSSession

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [int]$SessionId,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'Host', 'PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential,

        [System.Management.Automation.Runspaces.PSSession]$Session,

        [ValidateSet('Active', 'Connected', 'ConnectQuery', 'Shadow', 'Disconnected', 'Idle', 'Listen', 'Reset', 'Down', 'Init')]
        [string]$State,

        [SupportsWildcards()]
        [string]$UserName,

        [switch]$ExcludeSystemSessions,

        [switch]$Detailed
    )

    process {
        $params = Split-RemoteAndNativeParameters

        $scriptBlock = {
            param($nativeParams, $VerbosePreference)

            # Define WTS API types
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
    WTSSessionInfo,
    WTSSessionInfoEx,
    WTSConfigInfo
}

[StructLayout(LayoutKind.Sequential)]
public struct WTS_SESSION_INFO
{
    public int SessionId;
    public IntPtr pWinStationName;
    public WTS_CONNECTSTATE_CLASS State;
}

[StructLayout(LayoutKind.Sequential)]
public struct WTS_CLIENT_ADDRESS
{
    public uint AddressFamily;
    [MarshalAs(UnmanagedType.ByValArray, SizeConst = 20)]
    public byte[] Address;
}

[StructLayout(LayoutKind.Sequential)]
public struct WTS_CLIENT_DISPLAY
{
    public uint HorizontalResolution;
    public uint VerticalResolution;
    public uint ColorDepth;
}

[Flags]
public enum WTS_SESSIONSTATE
{
    Unknown = -1,
    Locked = 0,
    Unlocked = 1
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct WTSINFOEX_LEVEL1
{
    public uint SessionId;
    public WTS_CONNECTSTATE_CLASS SessionState;
    public WTS_SESSIONSTATE SessionFlags;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 33)]
    public string WinStationName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 21)]
    public string UserName;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 18)]
    public string DomainName;
    private long LogonTimeTicks;
    private long ConnectTimeTicks;
    private long DisconnectTimeTicks;
    private long LastInputTimeTicks;
    private long CurrentTimeTicks;
    public uint IncomingBytes;
    public uint OutgoingBytes;
    public uint IncomingFrames;
    public uint OutgoingFrames;
    public uint IncomingCompressedBytes;
    public uint OutgoingCompressedBytes;
    private static DateTime? FileTimeToDateTime(long ticks)
    {
        return ticks > 0 ? DateTime.FromFileTime(ticks) : (DateTime?)null;
    }
    public DateTime? LogonTime      { get { return FileTimeToDateTime(LogonTimeTicks); } }
    public DateTime? ConnectTime    { get { return FileTimeToDateTime(ConnectTimeTicks); } }
    public DateTime? DisconnectTime { get { return FileTimeToDateTime(DisconnectTimeTicks); } }
    public DateTime? LastInputTime  { get { return FileTimeToDateTime(LastInputTimeTicks); } }
    public DateTime? CurrentTime    { get { return FileTimeToDateTime(CurrentTimeTicks); } }
}

[StructLayout(LayoutKind.Explicit, CharSet = CharSet.Unicode)]
public struct WTSINFOEX_LEVEL
{
    [FieldOffset(0)]
    public WTSINFOEX_LEVEL1 WTSInfoExLevel1;
}

[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
public struct WTSINFOEX
{
    public uint Level;
    public WTSINFOEX_LEVEL Data;
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

            # Helper function to query session info
            function Get-WTSInfo {
                param($ServerHandle, $SessionId, $InfoClass)
                $buffer = [IntPtr]::Zero
                $bytesReturned = 0
                try {
                    if ([WTSApi]::WTSQuerySessionInformation($ServerHandle, $SessionId, $InfoClass, [ref]$buffer, [ref]$bytesReturned)) {
                        if ($InfoClass -eq [WTS_INFO_CLASS]::WTSClientProtocolType) {
                            return [System.Runtime.InteropServices.Marshal]::ReadInt16($buffer)
                        }
                        return [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($buffer)
                    }
                    return $null
                }
                finally {
                    if ($buffer -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($buffer)
                    }
                }
            }

            # Helper function to get ULONG values (for statistics and times)
            function Get-WTSInfoULong {
                param($ServerHandle, $SessionId, $InfoClass)
                $buffer = [IntPtr]::Zero
                $bytesReturned = 0
                try {
                    $result = [WTSApi]::WTSQuerySessionInformation($ServerHandle, $SessionId, $InfoClass, [ref]$buffer, [ref]$bytesReturned)
                    if ($result) {
                        Write-Verbose "Get-WTSInfoULong: InfoClass=$InfoClass, bytesReturned=$bytesReturned"
                        if ($bytesReturned -ge 4) {
                            $value = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer)
                            Write-Verbose "Get-WTSInfoULong: value=$value"
                            return $value
                        }
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        Write-Verbose "Get-WTSInfoULong failed for InfoClass=$InfoClass, Error=$errorCode"
                    }
                    return $null
                }
                finally {
                    if ($buffer -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($buffer)
                    }
                }
            }

            # Helper function to get ULONGLONG values (for byte statistics)
            function Get-WTSInfoULongLong {
                param($ServerHandle, $SessionId, $InfoClass)
                $buffer = [IntPtr]::Zero
                $bytesReturned = 0
                try {
                    $result = [WTSApi]::WTSQuerySessionInformation($ServerHandle, $SessionId, $InfoClass, [ref]$buffer, [ref]$bytesReturned)
                    if ($result) {
                        Write-Verbose "Get-WTSInfoULongLong: InfoClass=$InfoClass, bytesReturned=$bytesReturned"
                        if ($bytesReturned -ge 8) {
                            $value = [System.Runtime.InteropServices.Marshal]::ReadInt64($buffer)
                            Write-Verbose "Get-WTSInfoULongLong: value=$value"
                            return $value
                        }
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        Write-Verbose "Get-WTSInfoULongLong failed for InfoClass=$InfoClass, Error=$errorCode"
                    }
                    return $null
                }
                finally {
                    if ($buffer -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($buffer)
                    }
                }
            }

            # Helper function to parse WTS_CLIENT_ADDRESS
            function Get-WTSClientAddress {
                param($ServerHandle, $SessionId)
                $buffer = [IntPtr]::Zero
                $bytesReturned = 0
                try {
                    $result = [WTSApi]::WTSQuerySessionInformation($ServerHandle, $SessionId, [WTS_INFO_CLASS]::WTSClientAddress, [ref]$buffer, [ref]$bytesReturned)
                    if ($result) {
                        Write-Verbose "Get-WTSClientAddress: bytesReturned=$bytesReturned"
                        if ($bytesReturned -ge 24) {  # Size of WTS_CLIENT_ADDRESS structure
                            # Read AddressFamily (first 4 bytes)
                            $addressFamily = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer)
                            Write-Verbose "Get-WTSClientAddress: AddressFamily=$addressFamily"

                            # AddressFamily: 0 = unspecified, 2 = IPv4, 23 = IPv6
                            if ($addressFamily -eq 2) {
                                # IPv4: Address bytes start at offset 4, IP is at offset 4+2 = 6
                                $byte1 = [System.Runtime.InteropServices.Marshal]::ReadByte($buffer, 6)
                                $byte2 = [System.Runtime.InteropServices.Marshal]::ReadByte($buffer, 7)
                                $byte3 = [System.Runtime.InteropServices.Marshal]::ReadByte($buffer, 8)
                                $byte4 = [System.Runtime.InteropServices.Marshal]::ReadByte($buffer, 9)
                                return "$byte1.$byte2.$byte3.$byte4"
                            }
                            elseif ($addressFamily -eq 23) {
                                # IPv6: 16 bytes starting at offset 6
                                $ipv6Parts = @()
                                for ($i = 0; $i -lt 16; $i += 2) {
                                    $byte1 = [System.Runtime.InteropServices.Marshal]::ReadByte($buffer, 6 + $i)
                                    $byte2 = [System.Runtime.InteropServices.Marshal]::ReadByte($buffer, 6 + $i + 1)
                                    $ipv6Parts += "{0:x}" -f (($byte1 -shl 8) + $byte2)
                                }
                                return $ipv6Parts -join ":"
                            }
                        }
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        Write-Verbose "Get-WTSClientAddress failed, Error=$errorCode"
                    }
                    return $null
                }
                catch {
                    Write-Verbose "Get-WTSClientAddress exception: $_"
                    return $null
                }
                finally {
                    if ($buffer -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($buffer)
                    }
                }
            }

            # Helper function to parse WTS_CLIENT_DISPLAY
            function Get-WTSClientDisplay {
                param($ServerHandle, $SessionId)
                $buffer = [IntPtr]::Zero
                $bytesReturned = 0
                try {
                    $result = [WTSApi]::WTSQuerySessionInformation($ServerHandle, $SessionId, [WTS_INFO_CLASS]::WTSClientDisplay, [ref]$buffer, [ref]$bytesReturned)
                    if ($result) {
                        Write-Verbose "Get-WTSClientDisplay: bytesReturned=$bytesReturned"
                        if ($bytesReturned -ge 12) {  # 3 UINTs = 12 bytes
                            # Read 3 UInt32 values: HorizontalResolution, VerticalResolution, ColorDepth
                            $horizontalResolution = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 0)
                            $verticalResolution = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 4)
                            $colorDepth = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 8)

                            Write-Verbose "Get-WTSClientDisplay: ${horizontalResolution}x${verticalResolution}x${colorDepth}"
                            if ($horizontalResolution -gt 0 -and $verticalResolution -gt 0) {
                                return "${horizontalResolution}x${verticalResolution}x${colorDepth}"
                            }
                        }
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        Write-Verbose "Get-WTSClientDisplay failed, Error=$errorCode"
                    }
                    return $null
                }
                catch {
                    Write-Verbose "Get-WTSClientDisplay exception: $_"
                    return $null
                }
                finally {
                    if ($buffer -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($buffer)
                    }
                }
            }

            # Helper function to parse WTSCONFIGINFO (session configuration)
            # Struct layout (Unicode): 6 x uint32 (24 bytes), then ByValTStr strings
            # Offsets: version=0, fConnectClientDrivesAtLogon=4, fConnectPrinterAtLogon=8,
            #   fDisablePrinterRedirection=12, fDisableDefaultMainClientPrinter=16, ShadowSettings=20,
            #   LogonUserName=24 (21 chars), LogonDomain=66 (18 chars), WorkDirectory=102 (261 chars),
            #   InitialProgram=624 (261 chars), ApplicationName=1146 (261 chars)
            function Get-WTSSessionConfiguration {
                param($ServerHandle, $SessionId)
                $buffer = [IntPtr]::Zero
                $bytesReturned = 0
                try {
                    # WTSConfigInfo = 26
                    $result = [WTSApi]::WTSQuerySessionInformation($ServerHandle, $SessionId, [WTS_INFO_CLASS]::WTSConfigInfo, [ref]$buffer, [ref]$bytesReturned)
                    if ($result -and $bytesReturned -gt 24) {
                        Write-Verbose "Get-WTSSessionConfiguration: bytesReturned=$bytesReturned"

                        # Read uint32 fields
                        $version = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 0)
                        $connectDrives = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 4)
                        $connectPrinter = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 8)
                        $disablePrinter = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 12)
                        $disableDefaultPrinter = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 16)
                        $shadowSettings = [System.Runtime.InteropServices.Marshal]::ReadInt32($buffer, 20)

                        # Read Unicode null-terminated strings at fixed offsets
                        $logonUserName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]::Add($buffer, 24))
                        $logonDomain = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]::Add($buffer, 66))
                        $workDirectory = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]::Add($buffer, 102))
                        $initialProgram = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]::Add($buffer, 624))
                        $applicationName = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]::Add($buffer, 1146))

                        # Interpret ShadowSettings value
                        $shadowSettingsText = switch ($shadowSettings) {
                            0 { 'Disabled' }
                            1 { 'FullControlWithConsent' }
                            2 { 'FullControlWithoutConsent' }
                            3 { 'ViewOnlyWithConsent' }
                            4 { 'ViewOnlyWithoutConsent' }
                            default { "Unknown ($shadowSettings)" }
                        }

                        return [PSCustomObject]@{
                            PSTypeName                      = 'RDS.SessionConfiguration'
                            Version                         = $version
                            ConnectClientDrivesAtLogon      = [bool]$connectDrives
                            ConnectPrinterAtLogon           = [bool]$connectPrinter
                            DisablePrinterRedirection       = [bool]$disablePrinter
                            DisableDefaultMainClientPrinter = [bool]$disableDefaultPrinter
                            ShadowSettings                  = $shadowSettingsText
                            LogonUserName                   = $logonUserName
                            LogonDomain                     = $logonDomain
                            WorkDirectory                   = $workDirectory
                            InitialProgram                  = $initialProgram
                            ApplicationName                 = $applicationName
                        }
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        Write-Verbose "Get-WTSSessionConfiguration failed, Error=$errorCode"
                    }
                    return $null
                }
                catch {
                    Write-Verbose "Get-WTSSessionConfiguration exception: $_"
                    return $null
                }
                finally {
                    if ($buffer -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($buffer)
                    }
                }
            }

            # Helper function to parse WTSINFOEX (extended session information)
            # Uses PtrToStructure with the WTSINFOEX C# struct
            function Get-WTSSessionInfoEx {
                param($ServerHandle, $SessionId)
                $buffer = [IntPtr]::Zero
                $bytesReturned = 0
                try {
                    # WTSSessionInfoEx = 25
                    $result = [WTSApi]::WTSQuerySessionInformation($ServerHandle, $SessionId, [WTS_INFO_CLASS]::WTSSessionInfoEx, [ref]$buffer, [ref]$bytesReturned)
                    if ($result -and $bytesReturned -gt 0) {
                        Write-Verbose "Get-WTSSessionInfoEx: bytesReturned=$bytesReturned"
                        $infoEx = [System.Runtime.InteropServices.Marshal]::PtrToStructure($buffer, [Type][WTSINFOEX])
                        if ($infoEx.Level -eq 1) {
                            $level1 = $infoEx.Data.WTSInfoExLevel1
                            return [PSCustomObject]@{
                                PSTypeName           = 'RDS.SessionInfoEx'
                                SessionFlags         = $level1.SessionFlags.ToString()
                                LogonTime            = $level1.LogonTime
                                ConnectTime          = $level1.ConnectTime
                                DisconnectTime       = $level1.DisconnectTime
                                LastInputTime        = $level1.LastInputTime
                                CurrentTime          = $level1.CurrentTime
                                IncomingBytes        = $level1.IncomingBytes
                                OutgoingBytes        = $level1.OutgoingBytes
                                IncomingFrames       = $level1.IncomingFrames
                                OutgoingFrames       = $level1.OutgoingFrames
                                IncomingCompressedBytes = $level1.IncomingCompressedBytes
                                OutgoingCompressedBytes = $level1.OutgoingCompressedBytes
                            }
                        }
                    }
                    else {
                        $errorCode = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
                        Write-Verbose "Get-WTSSessionInfoEx failed, Error=$errorCode"
                    }
                    return $null
                }
                catch {
                    Write-Verbose "Get-WTSSessionInfoEx exception: $_"
                    return $null
                }
                finally {
                    if ($buffer -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($buffer)
                    }
                }
            }

            try {
                # Keep ComputerName for display purposes
                $targetComputer = if ($nativeParams.ComputerName) { $nativeParams.ComputerName } else { $env:COMPUTERNAME }
                $serverHandle = [IntPtr]::Zero
                $sessionInfoPtr = [IntPtr]::Zero
                $sessions = @()

                try {
                    # Always use local server since this scriptblock runs either:
                    # - Locally (when no remoting)
                    # - On the remote machine (when using Invoke-Command with Session/ComputerName)
                    # Pass $null for local server (WTSOpenServer expects string, not IntPtr)
                    $serverHandle = [WTSApi]::WTSOpenServer($null)

                    if ($serverHandle -eq [IntPtr]::Zero) {
                        throw "Unable to open connection to local WTS server"
                    }

                    # Enumerate sessions
                    $count = 0
                    if (-not [WTSApi]::WTSEnumerateSessions($serverHandle, 0, 1, [ref]$sessionInfoPtr, [ref]$count)) {
                        throw "Unable to enumerate sessions: $([System.ComponentModel.Win32Exception]::new([System.Runtime.InteropServices.Marshal]::GetLastWin32Error()).Message)"
                    }

                    # Parse session information
                    $dataSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type][WTS_SESSION_INFO])

                    for ($i = 0; $i -lt $count; $i++) {
                        $sessionInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure(
                            [IntPtr]::Add($sessionInfoPtr, $i * $dataSize),
                            [Type][WTS_SESSION_INFO]
                        )

                        # Retrieve basic information
                        $userName = Get-WTSInfo $serverHandle $sessionInfo.SessionId ([WTS_INFO_CLASS]::WTSUserName)
                        $domainName = Get-WTSInfo $serverHandle $sessionInfo.SessionId ([WTS_INFO_CLASS]::WTSDomainName)
                        $winStationName = Get-WTSInfo $serverHandle $sessionInfo.SessionId ([WTS_INFO_CLASS]::WTSWinStationName)
                        $clientName = Get-WTSInfo $serverHandle $sessionInfo.SessionId ([WTS_INFO_CLASS]::WTSClientName)
                        $clientProtocol = Get-WTSInfo $serverHandle $sessionInfo.SessionId ([WTS_INFO_CLASS]::WTSClientProtocolType)

                        # Map protocol type
                        $protocolName = switch ($clientProtocol) {
                            0 { 'Console' }
                            1 { 'Legacy' }
                            2 { 'RDP' }
                            default { 'Unknown' }
                        }

                        # Build base session object
                        $sessionObj = [PSCustomObject]@{
                            PSTypeName     = 'RDS.SessionInfo'
                            ComputerName   = $targetComputer
                            SessionId      = $sessionInfo.SessionId
                            SessionName    = $winStationName
                            UserName       = if ([string]::IsNullOrWhiteSpace($userName)) { $null } else { $userName }
                            DomainName     = if ([string]::IsNullOrWhiteSpace($domainName)) { $null } else { $domainName }
                            State          = $sessionInfo.State.ToString()
                            ClientName     = if ([string]::IsNullOrWhiteSpace($clientName)) { $null } else { $clientName }
                            ClientProtocol = $protocolName
                        }

                        # Add detailed information if requested
                        if ($nativeParams.Detailed) {
                            # Get extended session info (times, flags, network stats) via WTS API
                            $sessionInfoEx = Get-WTSSessionInfoEx $serverHandle $sessionInfo.SessionId

                            # LogonTime and IdleTime from WTSINFOEX (native WTS API, consistent DateTime format)
                            $logonTime = if ($sessionInfoEx) { $sessionInfoEx.LogonTime } else { $null }
                            $idleTime = if ($sessionInfoEx -and $sessionInfoEx.LastInputTime -and $sessionInfoEx.CurrentTime) {
                                $sessionInfoEx.CurrentTime - $sessionInfoEx.LastInputTime
                            } else { $null }

                            # Get client information
                            $clientAddress = Get-WTSClientAddress $serverHandle $sessionInfo.SessionId
                            $clientBuildNumber = Get-WTSInfoULong $serverHandle $sessionInfo.SessionId ([WTS_INFO_CLASS]::WTSClientBuildNumber)
                            $clientDirectory = Get-WTSInfo $serverHandle $sessionInfo.SessionId ([WTS_INFO_CLASS]::WTSClientDirectory)
                            $clientDisplay = Get-WTSClientDisplay $serverHandle $sessionInfo.SessionId

                            # Add extended properties
                            $sessionObj | Add-Member -MemberType NoteProperty -Name LogonTime -Value $logonTime
                            $sessionObj | Add-Member -MemberType NoteProperty -Name IdleTime -Value $idleTime
                            $sessionObj | Add-Member -MemberType NoteProperty -Name ClientAddress -Value $clientAddress
                            $sessionObj | Add-Member -MemberType NoteProperty -Name ClientBuildNumber -Value $clientBuildNumber
                            $sessionObj | Add-Member -MemberType NoteProperty -Name ClientDirectory -Value $clientDirectory
                            $sessionObj | Add-Member -MemberType NoteProperty -Name ClientDisplay -Value $clientDisplay

                            # Get session configuration (drives, printers, shadow, initial program)
                            $sessionConfiguration = Get-WTSSessionConfiguration $serverHandle $sessionInfo.SessionId

                            # Build merged SessionInfo object
                            $mergedSessionInfo = [ordered]@{
                                PSTypeName = 'RDS.SessionInfo.Detailed'
                            }
                            # Add SessionInfoEx properties (times, flags, network stats)
                            if ($sessionInfoEx) {
                                $mergedSessionInfo['SessionFlags']         = $sessionInfoEx.SessionFlags
                                $mergedSessionInfo['LogonTime']            = $sessionInfoEx.LogonTime
                                $mergedSessionInfo['ConnectTime']          = $sessionInfoEx.ConnectTime
                                $mergedSessionInfo['DisconnectTime']       = $sessionInfoEx.DisconnectTime
                                $mergedSessionInfo['LastInputTime']        = $sessionInfoEx.LastInputTime
                                $mergedSessionInfo['CurrentTime']          = $sessionInfoEx.CurrentTime
                                $mergedSessionInfo['IncomingBytes']        = $sessionInfoEx.IncomingBytes
                                $mergedSessionInfo['OutgoingBytes']        = $sessionInfoEx.OutgoingBytes
                                $mergedSessionInfo['IncomingFrames']       = $sessionInfoEx.IncomingFrames
                                $mergedSessionInfo['OutgoingFrames']       = $sessionInfoEx.OutgoingFrames
                                $mergedSessionInfo['IncomingCompressedBytes'] = $sessionInfoEx.IncomingCompressedBytes
                                $mergedSessionInfo['OutgoingCompressedBytes'] = $sessionInfoEx.OutgoingCompressedBytes
                            }
                            # Add SessionConfiguration properties (drives, printers, shadow, etc.)
                            if ($sessionConfiguration) {
                                $mergedSessionInfo['ConnectClientDrivesAtLogon']      = $sessionConfiguration.ConnectClientDrivesAtLogon
                                $mergedSessionInfo['ConnectPrinterAtLogon']           = $sessionConfiguration.ConnectPrinterAtLogon
                                $mergedSessionInfo['DisablePrinterRedirection']       = $sessionConfiguration.DisablePrinterRedirection
                                $mergedSessionInfo['DisableDefaultMainClientPrinter'] = $sessionConfiguration.DisableDefaultMainClientPrinter
                                $mergedSessionInfo['ShadowSettings']                  = $sessionConfiguration.ShadowSettings
                                $mergedSessionInfo['WorkDirectory']                   = $sessionConfiguration.WorkDirectory
                                $mergedSessionInfo['InitialProgram']                  = $sessionConfiguration.InitialProgram
                                $mergedSessionInfo['ApplicationName']                 = $sessionConfiguration.ApplicationName
                            }

                            $sessionObj | Add-Member -MemberType NoteProperty -Name SessionInfo -Value ([PSCustomObject]$mergedSessionInfo)
                        }

                        $sessions += $sessionObj
                    }

                    # Apply filters
                    $filteredSessions = $sessions

                    # Filter by SessionId if specified
                    if ($nativeParams.SessionId -and $nativeParams.SessionId -gt 0) {
                        $filteredSessions = $filteredSessions | Where-Object { $_.SessionId -eq $nativeParams.SessionId }
                    }

                    # Filter by State if specified
                    if ($nativeParams.State) {
                        $filteredSessions = $filteredSessions | Where-Object { $_.State -eq $nativeParams.State }
                    }

                    # Filter by UserName if specified (with wildcard support and domain\username parsing)
                    if ($nativeParams.UserName) {
                        $filterUserName = $nativeParams.UserName
                        $filterDomainName = $null

                        if ($filterUserName -match '^\.\\(.+)$') {
                            # .\username -> replace . with local machine name
                            $filterDomainName = $env:COMPUTERNAME
                            $filterUserName = $Matches[1]
                        }
                        elseif ($filterUserName -match '^(.+)\\(.+)$') {
                            # domain\username
                            $filterDomainName = $Matches[1]
                            $filterUserName = $Matches[2]
                        }

                        $filteredSessions = $filteredSessions | Where-Object {
                            $_.UserName -and ($_.UserName -like $filterUserName) -and
                            (-not $filterDomainName -or ($_.DomainName -eq $filterDomainName))
                        }
                    }

                    # Exclude system sessions if requested
                    if ($nativeParams.ExcludeSystemSessions) {
                        $filteredSessions = $filteredSessions | Where-Object {
                            $_.SessionId -ne 0 -and
                            $_.State -ne 'Listen' -and
                            -not [string]::IsNullOrWhiteSpace($_.UserName)
                        }
                    }

                    return $filteredSessions
                }
                finally {
                    # Cleanup resources
                    if ($sessionInfoPtr -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSFreeMemory($sessionInfoPtr)
                    }
                    if ($serverHandle -ne [IntPtr]::Zero) {
                        [WTSApi]::WTSCloseServer($serverHandle)
                    }
                }
            }
            catch {
                Write-Error "Error retrieving sessions: $_"
            }
        }

        # Execute locally or remotely
        $remoteParams = $params.Remote
        $nativeParams = $params.Native

        if ($remoteParams.Count -gt 0) {
            Invoke-Command @remoteParams -ScriptBlock $scriptBlock -ArgumentList $nativeParams, $VerbosePreference
        }
        else {
            & $scriptBlock -nativeParams $nativeParams -VerbosePreference $VerbosePreference
        }
    }
}
