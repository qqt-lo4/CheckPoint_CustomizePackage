function Get-LastConnection {
    <#
    .SYNOPSIS
        Retrieves the last successful connection date and time

    .DESCRIPTION
        Extracts and parses the last successful update time from Check Point trac information object.
        Converts the string date format to a DateTime object.

    .PARAMETER tracinfo
        Trac information object (from Get-CheckPointInfo) containing last_successful_update_time property.

    .OUTPUTS
        [DateTime]. The last successful connection date and time.

    .EXAMPLE
        $info = Get-CheckPointInfo | Select-Object -First 1
        Get-LastConnection -tracinfo $info

    .EXAMPLE
        $info = Get-CheckPointInfo -sitename "Corporate VPN" | Select-Object -First 1
        $lastConn = Get-LastConnection -tracinfo $info
        Write-Host "Last connection: $lastConn"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [ValidateScript({$_.PSobject.Properties.name -match "last_successful_update_time"})]
        [Parameter(Mandatory, Position = 0)]
        [psobject]$tracinfo
    )
    $stringdate = $tracinfo.last_successful_update_time.Trim()
    $cultureinfo = [cultureinfo]::GetCultureInfoByIetfLanguageTag("en-US")
    $objectDate = [Datetime]::ParseExact($stringdate, "ddd MMM dd HH:mm:ss yyyy", $cultureinfo)
    return $objectDate
}
