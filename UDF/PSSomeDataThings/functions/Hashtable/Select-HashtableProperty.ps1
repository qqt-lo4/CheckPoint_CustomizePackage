function Select-HashtableProperty {
    <#
    .SYNOPSIS
        Selects specific properties from a hashtable

    .DESCRIPTION
        Returns a new ordered hashtable containing only the specified keys.
        Supports wildcard patterns for key matching.

    .PARAMETER InputObject
        The hashtable or ordered dictionary to filter

    .PARAMETER Property
        One or more key names or wildcard patterns to select

    .OUTPUTS
        OrderedDictionary. A new hashtable with only the selected keys.

    .EXAMPLE
        $hash | Select-HashtableProperty -Property "Name","Id"

    .EXAMPLE
        Select-HashtableProperty -InputObject $hash -Property "User*"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(ValueFromPipeline)]
        [AllowNull()]
        [object]$InputObject,
        [Parameter(Mandatory)]
        [string[]]$Property
    )
    $hResult = [ordered]@{}
    if ($null -eq $InputObject) {
        return $hResult
    }
    if (-not (($InputObject -is [hashtable]) `
          -or ($InputObject.GetType().Name -eq "PSBoundParametersDictionary") `
          -or ($InputObject.GetType().Name -eq "OrderedDictionary"))) {
        throw [System.ArgumentException] "`$InputObject is not a hashtable or a PSBoundParametersDictionary"
    }
    foreach ($p in $Property) {
        $aMatchingProperties = $InputObject.Keys | Where-Object { $_ -like $p }
        foreach ($sMatchingProperty in $aMatchingProperties) {
            $hResult[$sMatchingProperty] = $InputObject[$sMatchingProperty]
        }
    }
    return $hResult
}
