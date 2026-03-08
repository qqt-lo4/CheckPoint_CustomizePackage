function Convert-MatchInfoToHashtable {
    <#
    .SYNOPSIS
        Converts a MatchInfo object to an ordered hashtable

    .DESCRIPTION
        Extracts named capture groups from a Select-String MatchInfo result
        and returns them as an ordered hashtable.

    .PARAMETER InputObject
        The MatchInfo object from Select-String

    .PARAMETER ExcludeNumbers
        Exclude numeric group names (unnamed capture groups)

    .PARAMETER ExcludeNull
        Exclude entries with null or empty values

    .OUTPUTS
        OrderedDictionary. Named capture groups as key-value pairs.

    .EXAMPLE
        "Hello World" | Select-String -Pattern "(?<first>\w+) (?<second>\w+)" | Convert-MatchInfoToHashtable

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.PowerShell.Commands.MatchInfo]$InputObject,
        [switch]$ExcludeNumbers,
        [switch]$ExcludeNull
    )
    $hResult = [ordered]@{}
    $matchingGroups = $InputObject.Matches.Groups | Where-Object { $_.Captures.Count -gt 0 }
    if ($ExcludeNumbers) {
        $ahResultKeys = $matchingGroups.name | Where-Object { $_ -notmatch "^[0-9]+$"}
    } else {
        $ahResultKeys = $matchingGroups.name
    }
    foreach ($sKey in $ahResultKeys) {
        $oValue = ($matchingGroups | Where-Object { $_.name -eq $sKey }).Value
        if ($ExcludeNull) {
            if (($oValue -ne $null) -and ($oValue -ne "")) {
                $hResult.$sKey = $oValue
            }
        } else {
            $hResult.$sKey = $oValue
        }
    }
    return $hResult
}
