function Merge-Hashtable {
    <#
    .SYNOPSIS
        Merges two hashtables together

    .DESCRIPTION
        Adds or overwrites entries from MergeWith into InputObject.
        Modifies InputObject in-place and returns it.

    .PARAMETER InputObject
        The target hashtable to merge into

    .PARAMETER MergeWith
        The source hashtable whose entries will be added/overwritten

    .OUTPUTS
        Hashtable. The merged hashtable (same reference as InputObject).

    .EXAMPLE
        $base = @{ a = 1; b = 2 }
        Merge-Hashtable -InputObject $base -MergeWith @{ b = 3; c = 4 }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true)]
        [hashtable]$InputObject,
        [Parameter(Mandatory, Position = 1)]
        [hashtable]$MergeWith
    )
    $result = $InputObject
    foreach ($key in $MergeWith.Keys) {
        $result[$key] = $MergeWith[$key]
    }
    return $result
}