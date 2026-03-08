function Rename-HashtableProperty {
    <#
    .SYNOPSIS
        Renames keys in a hashtable

    .DESCRIPTION
        Creates a new ordered hashtable with renamed keys. Supports three modes:
        regex replacement on a single key, a mapping hashtable for multiple keys,
        or an indexed array of new key names.

    .PARAMETER InputObject
        The hashtable or ordered dictionary to process

    .PARAMETER LookFor
        Regex pattern to match in key names (OneProperty mode)

    .PARAMETER ReplaceBy
        Replacement string for matched keys (OneProperty mode)

    .PARAMETER RenameInfo
        Hashtable mapping old key names to new key names (MultipleProperties mode)

    .PARAMETER RenameKeys
        Array of new key names applied by index order (RenameKeysIndexed mode)

    .OUTPUTS
        OrderedDictionary. A new hashtable with renamed keys.

    .EXAMPLE
        @{ old_name = "test" } | Rename-HashtableProperty -LookFor "old_" -ReplaceBy "new_"

    .EXAMPLE
        Rename-HashtableProperty -InputObject $hash -RenameInfo @{ "OldKey" = "NewKey" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object]$InputObject,
        [Parameter(Mandatory, ParameterSetName = "OneProperty")]
        [string]$LookFor,
        [Parameter(Mandatory, ParameterSetName = "OneProperty")]
        [string]$ReplaceBy,
        [Parameter(Mandatory, ParameterSetName = "MultipleProperties")]
        [hashtable]$RenameInfo,
        [Parameter(Mandatory, ParameterSetName = "RenameKeysIndexed")]
        [string[]]$RenameKeys
    )
    if (-not (($InputObject -is [hashtable]) `
          -or ($InputObject.GetType().Name -eq "PSBoundParametersDictionary") `
          -or ($InputObject.GetType().Name -eq "OrderedDictionary"))) {
        throw [System.ArgumentException] "`$InputObject is not a hashtable or a PSBoundParametersDictionary"
    }
    $hResult = [ordered]@{}

    $aProp = ([string[]]$InputObject.Keys)

    switch ($PSCmdlet.ParameterSetName) {
        "OneProperty" {
            foreach ($p in $aProp) {
                if ($p -match $LookFor) {
                    $sNewProperty = $p -replace $LookFor, $ReplaceBy
                    $hResult[$sNewProperty] = $InputObject[$p]
                } else {
                    $hResult[$p] = $InputObject[$p]
                }
            }
        }
        "MultipleProperties" {
            foreach ($p in $aProp) {
                $sNewProperty = $RenameInfo[$p]
                if ($sNewProperty) {
                    $hResult[$sNewProperty] = $InputObject[$p]
                } else {
                    $hResult[$p] = $InputObject[$p]
                }
            }
        }
        "RenameKeysIndexed" {
            if ($RenameKeys.Count -le $aProp.Count) {
                for ($i = 0; $i -lt $RenameKeys.Count; $i++) {
                    $oNewValue = $InputObject[$aProp[$i]]
                    $oNewProp = $RenameKeys[$i]
                    $hResult[$oNewProp] = $oNewValue
                }
            }
        }
    }
    
    return $hResult
}
