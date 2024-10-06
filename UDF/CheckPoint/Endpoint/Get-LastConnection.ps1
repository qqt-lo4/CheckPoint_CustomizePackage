function Get-LastConnection {
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
