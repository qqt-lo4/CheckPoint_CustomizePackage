function Wait-VPNStatus {
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