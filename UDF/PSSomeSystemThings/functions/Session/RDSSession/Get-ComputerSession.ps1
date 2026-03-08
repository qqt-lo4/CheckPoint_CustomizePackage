function Get-ComputerSession {
    <#
    .SYNOPSIS
        Retrieves detailed session information from a computer

    .DESCRIPTION
        Uses the WTS API (WTSEnumerateSessionsEx, WTSQuerySessionInformation) to enumerate
        all sessions on a local or remote computer, including session state, client info,
        IP address, and configuration details.

    .PARAMETER ComputerName
        Remote computer name(s) to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession(s) for remote execution.

    .PARAMETER FlattenOutput
        If specified, flattens nested properties into a single level.

    .OUTPUTS
        [PSObject[]]. Session objects with connection state, user, IP, and client details.

    .EXAMPLE
        Get-ComputerSession

    .EXAMPLE
        Get-ComputerSession -ComputerName "SERVER01" -Credential (Get-Credential)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

	[CmdletBinding()]
    Param(
        [string[]]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession[]]$Session,
        # Flattens the output
		[switch]$FlattenOutput
    )

    if ($ComputerName -or $Session) {
		$aResults = Invoke-ThisFunctionRemotely
        foreach ($oSession in $aResults) {
			$oSession.PSTypeNames.Insert(0, "Computer Session")
		}
		return $aResults
    } else {
		# this script is based on the PS code example for WTSEnumerateSessions from:
		#	https://pinvoke.net/default.aspx/wtsapi32.WTSEnumerateSessions
		# and also from:
		#	https://github.com/guyrleech/Microsoft/blob/master/WTSApi.ps1
		# thanks for the input!

		Add-Type -TypeDefinition @'
		// Native interoperability best practices (including WinAPI data type to C# type conversion):
		// https://docs.microsoft.com/en-us/dotnet/standard/native-interop/best-practices
		
		using System;
		using System.ComponentModel;
		using System.Runtime.InteropServices;
		namespace WTS
		{
			public class API
			{
				// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/nf-wtsapi32-wtsopenserverexw
				[DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
				public static extern IntPtr WTSOpenServerEx(string pServerName);
				// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/nf-wtsapi32-wtscloseserver
				[DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
				public static extern void WTSCloseServer(IntPtr hServer);
				// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/nf-wtsapi32-wtsenumeratesessionsexw
				[DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
				public static extern int WTSEnumerateSessionsEx(
						IntPtr hServer,
						ref uint pLevel,
						uint Filter,
						ref IntPtr ppSessionInfo,
						ref uint pCount);
				//https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/nf-wtsapi32-wtsquerysessioninformationw
				// If Remote Desktop Services is not running, calls to WTSQuerySessionInformation fail. In this situation, you can retrieve the current session ID by calling the ProcessIdToSessionId function.
				[DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
				public static extern bool WTSQuerySessionInformation(
						 IntPtr hServer,
						 uint SessionId,
						 WTS_INFO_CLASS WTSInfoClass,
						 ref IntPtr ppQuerySessionInfo,
						 ref uint pBytesReturned);
				// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/nf-wtsapi32-wtsfreememory
				[DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
				public static extern void WTSFreeMemory(IntPtr pMemory);
				// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/nf-wtsapi32-wtsfreememoryexw
				[DllImport("wtsapi32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
				public static extern bool WTSFreeMemoryEx(
					WTS_TYPE_CLASS WTSTypeClass,
					IntPtr pMemory,
					UInt32 NumberOfEntries);
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wts_session_info_1w
			[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
			public struct WTS_SESSION_INFO_1
			{
				public uint ExecEnvId;
				public WTS_CONNECTSTATE_CLASS State;
				public uint SessionId;
				public String SessionName;
				public String HostName;
				public String UserName;
				public String DomainName;
				public String FarmName;
			}
			//https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wtsinfoex_level1_w
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
				private string DomainName;
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
				public DateTimeOffset? LogonTime
				{
					get { if (LogonTimeTicks > 0) { return DateTimeOffset.FromFileTime(LogonTimeTicks); } else { return (DateTimeOffset?)null; } }
				}
				public DateTimeOffset? ConnectTime
				{
					get { if (ConnectTimeTicks > 0) { return DateTimeOffset.FromFileTime(ConnectTimeTicks); } else { return (DateTimeOffset?)null; } }
				}
				public DateTimeOffset? DisconnectTime
				{
					get { if (DisconnectTimeTicks > 0) { return DateTimeOffset.FromFileTime(DisconnectTimeTicks); } else { return (DateTimeOffset?)null; } }
				}
				public DateTimeOffset? LastInputTime
				{
					get { if (LastInputTimeTicks > 0) { return DateTimeOffset.FromFileTime(LastInputTimeTicks); } else { return (DateTimeOffset?)null; } }
				}
				public DateTimeOffset? CurrentTime
				{
					get { if (CurrentTimeTicks > 0) { return DateTimeOffset.FromFileTime(CurrentTimeTicks); } else { return (DateTimeOffset?)null; } }
				}
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wtsinfoex_level_w
			[StructLayout(LayoutKind.Explicit, CharSet = CharSet.Unicode)]
			public struct WTSINFOEX_LEVEL
			{ //Union
				[FieldOffset(0)]
				public WTSINFOEX_LEVEL1 WTSInfoExLevel1;
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wtsinfoexw
			[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
			public struct WTSINFOEX
			{
				public uint Level;
				public WTSINFOEX_LEVEL Data;
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wts_client_display
			[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
			public struct WTS_CLIENT_DISPLAY
			{
				public uint HorizontalResolution;
				public uint VerticalResolution;
				public uint ColorDepth;
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wtsconfiginfow
			[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
			public struct WTSCONFIGINFO
			{
				public uint version;
				public uint fConnectClientDrivesAtLogon;
				public uint fConnectPrinterAtLogon;
				public uint fDisablePrinterRedirection;
				public uint fDisableDefaultMainClientPrinter;
				public uint ShadowSettings;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 21)]
				public string LogonUserName;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 18)]
				public string LogonDomain;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 261)]
				public string WorkDirectory;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 261)]
				public string InitialProgram;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 261)]
				public string ApplicationName;
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wtsclientw
			// todo: Check how to convert IPv4/v6 address properly
			//	more input:	https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wts_client_address
			//				https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ne-wtsapi32-wts_info_class
			// The IP address is offset by two bytes from the start of the Address member of the WTS_CLIENT_ADDRESS structure.
			// 		see "WTSClientAddress": https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ne-wtsapi32-wts_info_class
			//		but this is not the actual WTS_CLIENT_ADDRESS, which is a separate type of WTS_INFO_CLASS
			[StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
			public struct WTSCLIENT
			{
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 21)]
				public string ClientName;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 18)]
				public string Domain;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 21)]
				public string UserName;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 261)]
				public string WorkDirectory;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 261)]
				public string InitialProgram;
				public byte EncryptionLevel;
				public uint ClientAddressFamily;
				[MarshalAs(UnmanagedType.ByValArray, SizeConst = 31)]
				public ushort[] ClientAddress;
				public ushort HRes;
				public ushort VRes;
				public ushort ColorDepth;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 261)]
				public string ClientDirectory;
				public uint ClientBuildNumber;
				public uint ClientHardwareId;
				public ushort ClientProductId;
				public ushort OutBufCountHost;
				public ushort OutBufCountClient;
				public ushort OutBufLength;
				[MarshalAs(UnmanagedType.ByValTStr, SizeConst = 261)]
				public string DeviceId;
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wts_client_address
			// The IP address is offset by two bytes from the start of the Address member of the WTS_CLIENT_ADDRESS structure.
			//		see "WTSClientAddress": https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ne-wtsapi32-wts_info_class
			public struct WTS_CLIENT_ADDRESS
			{
				public WTS_ADDRESS_FAMILY AddressFamily;
				[MarshalAs(UnmanagedType.ByValArray, SizeConst = 20)]
				public byte[] Address;
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ne-wtsapi32-wts_type_class
			public enum WTS_TYPE_CLASS
			{
				TypeProcessInfoLevel0,
				TypeProcessInfoLevel1,
				TypeSessionInfoLevel1
			}
			// SessionFlags parameter definition.
			// See: https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wtsinfoex_level1_w
			[Flags()]
			public enum WTS_SESSIONSTATE
			{
				Unknown = -1,
				Locked = 0,
				Unlocked = 1
			}
			// from "ws2def.h"
			// but only the mentioned types are supported: AF_INET, AF_INET6, AF_IPX, AF_NETBIOS, AF_UNSPEC
			// 		see: https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ns-wtsapi32-wts_client_address
			public enum WTS_ADDRESS_FAMILY : uint
			{
				AF_UNSPEC = 0,
				AF_UNIX = 1,
				AF_INET = 2,
				AF_IMPLINK = 3,
				AF_PUP = 4,
				AF_CHAOS = 5,
				AF_NS = 6,
				AF_IPX = AF_NS,
				AF_ISO = 7,
				AF_OSI = AF_ISO,
				AF_ECMA = 8,
				AF_DATAKIT = 9,
				AF_CCITT = 10,
				AF_SNA = 11,
				AF_DECnet = 12,
				AF_DLI = 13,
				AF_LAT = 14,
				AF_HYLINK = 15,
				AF_APPLETALK = 16,
				AF_NETBIOS = 17,
				AF_VOICEVIEW = 18,
				AF_FIREFOX = 19,
				AF_UNKNOWN1 = 20,
				AF_BAN = 21,
				AF_ATM = 22,
				AF_INET6 = 23,
				AF_CLUSTER = 24,
				AF_12844 = 25,
				AF_IRDA = 26,
				AF_NETDES = 28
			}
			// https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ne-wtsapi32-wts_connectstate_class
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
			//https://docs.microsoft.com/en-us/windows/win32/api/wtsapi32/ne-wtsapi32-wts_info_class
			public enum WTS_INFO_CLASS
			{
				InitialProgram,
				ApplicationName,
				WorkingDirectory,
				OEMId,
				SessionId,
				UserName,
				WinStationName,
				DomainName,
				ConnectState,
				ClientBuildNumber,
				ClientName,
				ClientDirectory,
				ClientProductId,
				ClientHardwareId,
				ClientAddress,
				ClientDisplay,
				ClientProtocolType,
				IdleTime,
				LogonTime,
				IncomingBytes,
				OutgoingBytes,
				IncomingFrames,
				OutgoingFrames,
				ClientInfo,
				SessionInfo,
				SessionInfoEx,
				ConfigInfo,
				ValidationInfo,
				SessionAddressV4,
				IsRemoteSession
			}
		}
'@

		function Get-LastWin32Error () {
			[System.ComponentModel.Win32Exception]::new([Runtime.InteropServices.Marshal]::GetLastWin32Error())
		}

		$wtsStructMemberMap = [ordered]@{
			[WTS.WTSINFOEX] = 'Data.WTSInfoExLevel1'
		}

		# this function returns a property at the given navigation, so we can omit nested structs with unneccessary properties
		function Add-PropertyFromWtsStructMemberMap ($InputObject, [ref] $TargetObject, [string]$PropertyName, [switch]$FlattenOutput) {
			$targetProp = $InputObject
			$propNav    = $wtsStructMemberMap[$targetProp.Gettype()]

			if ($propNav) {
				foreach ($prop in ($propNav -split '\.')) {
					$targetProp = $targetProp.$prop
				}
			}

			if ($FlattenOutput) {
				foreach ($psProp in $targetProp.psobject.properties) {
					$compoundPsPropName = '{0}_{1}' -f $PropertyName, $psProp.Name
					Add-Member -InputObject $TargetObject.Value -NotePropertyName $compoundPsPropName -NotePropertyValue $psProp.Value
				}
			} else {
				Add-Member -InputObject $TargetObject.Value -NotePropertyName $PropertyName -NotePropertyValue $targetProp
			}
		}

		$wtsSessionDataSize = [System.Runtime.InteropServices.Marshal]::SizeOf([System.Type][WTS.WTS_SESSION_INFO_1])

		$wtsInfoClassToStructMap = [ordered]@{
			[WTS.WTS_INFO_CLASS]::SessionInfoEx = [WTS.WTSINFOEX]
			[WTS.WTS_INFO_CLASS]::ClientInfo    = [WTS.WTSCLIENT]
			[WTS.WTS_INFO_CLASS]::ConfigInfo    = [WTS.WTSCONFIGINFO]
			[WTS.WTS_INFO_CLASS]::ClientAddress = [WTS.WTS_CLIENT_ADDRESS]
		}

        [UInt32] $pLevel          = 1 # for a reserved parameter. must be always 1
		[UInt32] $pCount          = 0
		[IntPtr] $ppSessionInfo = [IntPtr]::Zero

		try {
			[IntPtr] $wtsServerHandle = [WTS.API]::WTSOpenServerEx($ComputerName)

			if (-not $wtsServerHandle) {
				Write-Error -Exception (Get-LastWin32Error)

			} else {
				[bool] $wtsSessionsCheck = [WTS.API]::WTSEnumerateSessionsEx($wtsServerHandle, [ref] $pLevel, [UInt32] 0, [ref] $ppSessionInfo, [ref] $pCount)

				if (-not $wtsSessionsCheck) {
					Write-Error -Exception (Get-LastWin32Error)

				} else {
					for ($i = 0; $i -lt $pCount; $i++) {
						$wtsSessionInfoOffset = $wtsSessionDataSize * $i
						$wtsSessionInfo       = [System.Runtime.InteropServices.Marshal]::PtrToStructure([IntPtr]::Add($ppSessionInfo, $wtsSessionInfoOffset), [type][WTS.WTS_SESSION_INFO_1])

						foreach ($wtsInfoClassToStructMapItem in $wtsInfoClassToStructMap.GetEnumerator()) {
							$wtsInfoClass        = $wtsInfoClassToStructMapItem.psbase.Key
							$wtsStruct           = $wtsInfoClassToStructMapItem.psbase.Value
							$wtsQuerySessionInfo = $null

							[IntPtr] $ppQuerySessionInfo = [IntPtr]::Zero
							[uint32] $pBytesReturned     = 0

							try {
								[bool] $wtsSessionInfoCheck = [WTS.API]::WTSQuerySessionInformation($wtsServerHandle, $wtsSessionInfo.SessionId, $wtsInfoClass, [ref] $ppQuerySessionInfo, [ref] $pBytesReturned)

								if (-not $wtsSessionInfoCheck) {
									Write-Error -Exception (Get-LastWin32Error)

								} else {
									$wtsQuerySessionInfo = [System.Runtime.InteropServices.Marshal]::PtrToStructure($ppQuerySessionInfo, [type] $wtsStruct)

									Add-PropertyFromWtsStructMemberMap -InputObject $wtsQuerySessionInfo -TargetObject ([ref] $wtsSessionInfo) -PropertyName ([string] $wtsInfoClass) -FlattenOutput:$FlattenOutput
								}
							} finally {
								[WTS.API]::WTSFreeMemory($ppQuerySessionInfo)
								$ppQuerySessionInfo = [IntPtr]::Zero
							}
						}

						$oWtsSessionInfo = $wtsSessionInfo
						$oWtsSessionInfo.PSTypeNames.Insert(0, "Computer Session")
						if ($oWtsSessionInfo.ClientAddress.AddressFamily -eq "AF_INET") {
							$sIP = $oWtsSessionInfo.ClientAddress.Address[2..5] -join "."
							$oWtsSessionInfo | Add-Member -NotePropertyName "IP" -NotePropertyValue $sIP
						}
						$oWtsSessionInfo | Add-Member -NotePropertyName "ComputerName" -NotePropertyValue $env:COMPUTERNAME
						$oWtsSessionInfo
					}
				}
			}
		} catch {
			Write-Error -ErrorRecord $_
		} finally {
			try {
				$wtsSessionInfoFreeMemCheck = [WTS.API]::WTSFreeMemoryEx([WTS.WTS_TYPE_CLASS]::TypeSessionInfoLevel1, $ppSessionInfo, $pCount)

				if (-not $wtsSessionInfoFreeMemCheck) {
					Write-Error -Exception (Get-LastWin32Error)
				}
			} finally {
				$ppSessionInfo = [IntPtr]::Zero
				[WTS.API]::WTSCloseServer($wtsServerHandle)
			}
		}
    }
}
