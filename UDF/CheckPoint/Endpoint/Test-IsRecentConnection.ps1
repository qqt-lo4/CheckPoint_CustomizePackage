function Test-IsRecentConnection {
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