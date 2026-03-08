function Convert-ArrayToHashtable {
    <#
    .SYNOPSIS
        Converts an array of objects to a hashtable indexed by a property

    .DESCRIPTION
        Creates a hashtable from an array where each entry is keyed by the
        specified property value. Useful for fast lookups by key.

    .PARAMETER Array
        The array of objects to convert

    .PARAMETER Property
        The property name to use as the hashtable key

    .OUTPUTS
        Hashtable. Objects indexed by the specified property value.

    .EXAMPLE
        $users | Convert-ArrayToHashtable -Property "Id"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Position = 0)]
        [object[]]$Array,
        [Parameter(Position = 1)]
        [string]$Property
    )
    $hResult = @{}
    foreach ($item in $Array) {
        $sObjectProperty = ($item.$Property).ToString()
        $hResult.Add($sObjectProperty, $item)
    }
    return $hResult
}
