function ConvertTo-ScriptBlock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = "Hashtable")]
        [object]$Hashtable,
        [Parameter(Mandatory, ParameterSetName = "Hashtable")]
        [string]$HashtableName
    )
    switch ($PSCmdlet.ParameterSetName) {
        "Hashtable" {
            $sResult = "`$$HashtableName = "
            if ($Hashtable.GetType().Name -eq "OrderedDictionary") {
                $sResult += "[ordered]"
            }
            $sResult += "@{`n"
            foreach ($p in $Hashtable.GetEnumerator()) {
                $sResult += "    ""$($p.key)"" = "
                if ($p.value -is [string]) {
                    $sResult += ($p.value | ConvertTo-Json) + "`n"
                }
            }
            $sResult += "}"
            return $sResult
        }
        default {
            throw "Unmanaged method"
        }
    }
}