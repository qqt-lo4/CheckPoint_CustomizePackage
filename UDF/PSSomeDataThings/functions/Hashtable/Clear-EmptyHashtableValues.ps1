function Clear-EmptyHashtableValues {
    <#
    .SYNOPSIS
        Removes empty or null values from a hashtable

    .DESCRIPTION
        Returns a new ordered hashtable containing only entries with non-null,
        non-empty values. Removes null values, empty strings, and empty arrays.

    .PARAMETER InputObject
        The hashtable or ordered dictionary to clean

    .OUTPUTS
        OrderedDictionary. A new hashtable with empty values removed.

    .EXAMPLE
        @{ Name = "Test"; Empty = ""; Null = $null } | Clear-EmptyHashtableValues

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object]$InputObject
    )
    if (($InputObject -isnot [hashtable]) -and ($InputObject -isnot [System.Collections.Specialized.OrderedDictionary])) {
        throw "Invalid input object"
    }
    $hResult = [ordered]@{}
    foreach ($key in $InputObject.Keys) {
        $oValue = $InputObject.$key
        if ($oValue -ne $null) {
            if ($oValue -is [array]) {
                if ($oValue.Count -gt 0) {
                    $hResult.$key = $oValue
                }
            } elseif ($oValue -is [string]) {
                if ($oValue -ne "") {
                    $hResult.$key = $oValue
                }
            }
        }
    }
    return $hResult
}