function ConvertTo-ScriptBlock {
    <#
    .SYNOPSIS
        Converts objects to PowerShell script block strings

    .DESCRIPTION
        Converts PowerShell objects (like hashtables) to their string representation as
        valid PowerShell script blocks. Preserves ordered dictionaries and properly formats
        key-value pairs.

    .PARAMETER Hashtable
        Hashtable or OrderedDictionary to convert.

    .PARAMETER HashtableName
        Variable name to use in the output script block.

    .OUTPUTS
        [String]. Script block representation of the object.

    .EXAMPLE
        ConvertTo-ScriptBlock -Hashtable @{Name="Value"} -HashtableName "myConfig"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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