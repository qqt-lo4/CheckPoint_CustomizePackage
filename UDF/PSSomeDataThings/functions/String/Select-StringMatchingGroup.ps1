function Select-StringMatchingGroup {
    <#
    .SYNOPSIS
        Extracts named regex capture groups from a string

    .DESCRIPTION
        Applies a regex pattern to a string and returns matching named capture groups
        as a hashtable. Can optionally filter to return only specific groups and
        exclude numbered (unnamed) groups.

    .PARAMETER InputString
        The string to match against. Accepts pipeline input.

    .PARAMETER Regex
        The regex pattern containing named capture groups.

    .PARAMETER ExludeNumbers
        If specified, excludes numbered (unnamed) capture groups from the result.

    .PARAMETER OnlyGroups
        If specified, returns only the named groups listed in this array.

    .OUTPUTS
        System.Collections.Hashtable. A hashtable of matching group names and values.

    .EXAMPLE
        "John Doe, 30" | Select-StringMatchingGroup -Regex "(?<Name>\w+ \w+), (?<Age>\d+)"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputString,
        [Parameter(Mandatory)]
        [string]$Regex,
        [switch]$ExludeNumbers,
        [string[]]$OnlyGroups
    )
    $ss = Select-String -InputObject $InputString -Pattern $Regex -AllMatches
    $hMatchesItems = Convert-MatchInfoToHashtable -InputObject $ss -ExcludeNumbers:$ExludeNumbers
    if ($OnlyGroups) {
        $hResult = @{}
        $sNewKeys = @()
        foreach ($sKey in $OnlyGroups) {
            if ($sKey -in $hMatchesItems.Keys) {
                $sNewKeys += $sKey
            }
        }
        foreach ($sKey in $sNewKeys) {
            $hResult.$sKey = $hMatchesItems.$sKey
        }
        return $hResult
    } else {
        return $hMatchesItems
    }
}
