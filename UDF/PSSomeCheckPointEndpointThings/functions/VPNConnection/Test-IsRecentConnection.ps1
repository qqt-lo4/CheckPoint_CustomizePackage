function Test-IsRecentConnection {
    <#
    .SYNOPSIS
        Tests if the last VPN connection was recent

    .DESCRIPTION
        Checks whether the last successful VPN connection occurred within a specified time window.
        Uses the last_successful_update_time from trac information to determine recency.

    .PARAMETER tracinfo
        Trac information object (from Get-CheckPointInfo) containing last_successful_update_time property.

    .PARAMETER recenthourcount
        Number of hours to define "recent". Default: 24 hours.

    .OUTPUTS
        [Boolean]. True if the last connection was within the specified time window, false otherwise.

    .EXAMPLE
        $info = Get-CheckPointInfo | Select-Object -First 1
        Test-IsRecentConnection -tracinfo $info

    .EXAMPLE
        $info = Get-CheckPointInfo -sitename "Corporate VPN" | Select-Object -First 1
        if (Test-IsRecentConnection -tracinfo $info -recenthourcount 48) {
            Write-Host "Connection is recent (within 48 hours)"
        }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [ValidateScript({$_.PSobject.Properties.name -match "last_successful_update_time"})]
        [Parameter(Mandatory, Position = 0)]
        [psobject]$tracinfo,
        [int]$recenthourcount = 24
    )
    $PSBoundParameters.Remove("recenthourcount") | Out-Null
    [datetime]$lastConnectionDate = Get-LastConnection @PSBoundParameters
    if ($lastConnectionDate) {
        return (Get-Date).AddHours(-$recenthourcount) -lt $lastConnectionDate
    } else {
        return $false
    }
}