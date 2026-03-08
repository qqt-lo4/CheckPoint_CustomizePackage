function Wait-VPNStatus {
    <#
    .SYNOPSIS
        Waits for a VPN connection to reach a specific status

    .DESCRIPTION
        Polls the VPN connection status at 1-second intervals until the expected status is reached
        or a timeout occurs. Can also wait for the status to change from a specific value.

    .PARAMETER tracexe
        Path to trac.exe executable.

    .PARAMETER SiteName
        Name of the VPN site to monitor.

    .PARAMETER ExpectedStatus
        The expected status to wait for (e.g., "Connected", "Disconnected").

    .PARAMETER NegateExpectedStatus
        If specified, waits for the status to change FROM the ExpectedStatus instead of waiting to reach it.

    .PARAMETER Timeout
        Maximum time to wait in seconds. Default: 20.

    .OUTPUTS
        [PSCustomObject]. Object with Timeout (remaining seconds) and Status (current status) properties.

    .EXAMPLE
        Wait-VPNStatus -tracexe "C:\...\trac.exe" -SiteName "Corporate VPN" -ExpectedStatus "Connected"

    .EXAMPLE
        Wait-VPNStatus -tracexe (Get-CheckPointTracExe) -SiteName "Office" -ExpectedStatus "Connecting" -NegateExpectedStatus -Timeout 30

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$tracexe,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ExpectedStatus,

        [switch]$NegateExpectedStatus,

        [int]$Timeout = 20
    )

    function Get-VPNConnectionStatus {
        Param(
            [string]$tracexe,
            [string]$sitename
        )
        $tracinfo = Get-CheckPointInfo -tracexe $tracexe -sitename $sitename
        if ($tracinfo) {
            return $tracinfo.status
        } else {
            return $null
        }
    }

    $iTimeout = $Timeout
    $sStatus = Get-VPNConnectionStatus -tracexe $tracexe -sitename $sitename 

    if ($NegateExpectedStatus.IsPresent) {
        while (($iTimeout -gt 0) -and ($sStatus -eq $expectedStatus)) {
            Start-Sleep -Seconds 1
            $iTimeout = $iTimeout - 1
            $sStatus = Get-VPNConnectionStatus -tracexe $tracexe -sitename $sitename 
            Write-Debug ("Wait timer = " + $iTimeout + ", current status = " + $sStatus)
        }    
    } else {
        while (($iTimeout -gt 0) -and ($sStatus -ne $expectedStatus)) {
            Start-Sleep -Seconds 1
            $iTimeout = $iTimeout - 1
            $sStatus = Get-VPNConnectionStatus -tracexe $tracexe -sitename $sitename 
            Write-Debug ("Wait timer = " + $iTimeout + ", current status = " + $sStatus)
        }    
    }

    $result = @{
        "Timeout" = $iTimeout
        "Status" = $sStatus
    }
    return New-Object PSObject -Property $result 
}