function Set-Property {
    <#
    .SYNOPSIS
        Sets or adds a property on a hashtable or PSObject

    .DESCRIPTION
        Unified property setter that works with both hashtables and PSObjects.
        Updates existing properties or adds new ones as NoteProperty.

    .PARAMETER InputObject
        The object to modify.

    .PARAMETER Name
        Property name to set or add.

    .PARAMETER Value
        Value to assign to the property.

    .OUTPUTS
        [Object]. The modified input object.

    .EXAMPLE
        $obj | Set-Property "Status" "Active"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,
        
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,
        
        [Parameter(Mandatory = $true, Position = 1)]
        $Value
    )
    
    process {
        if (($InputObject -is [hashtable]) -or ($InputObject -is [System.Collections.Specialized.OrderedDictionary])) {
            $InputObject.$Name = $Value
        } elseif ($InputObject.PSObject.Properties.Name -contains $Name) {
            $InputObject.$Name = $Value
        } else {
            $InputObject | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
        }
        return $InputObject
    }
}
