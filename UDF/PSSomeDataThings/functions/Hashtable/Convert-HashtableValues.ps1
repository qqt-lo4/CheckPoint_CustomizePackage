function Convert-HashtableValue {
    <#
    .SYNOPSIS
        Transforms a specific property value in hashtables using a scriptblock

    .DESCRIPTION
        Applies a conversion function to a named property across an array of hashtables.
        Modifies the hashtables in-place.

    .PARAMETER InputObject
        One or more hashtables to process

    .PARAMETER Property
        The key name whose value should be transformed

    .PARAMETER Function
        A scriptblock that receives the current value and returns the new value

    .EXAMPLE
        @(@{ Size = "1024" }) | Convert-HashtableValue -Property "Size" -Function { [int]$args[0] }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [hashtable[]]$InputObject,
        [Parameter(Mandatory, Position = 1)]
        [string]$Property,
        [Parameter(Mandatory, Position = 2)]
        [scriptblock]$Function 
    )
    Begin{}
    Process{
        foreach ($item in $InputObject) {
            if ($Property -in $item.Keys) {
                $item[$Property] = Invoke-Command -ScriptBlock $Function -ArgumentList $item[$Property]
            }
        }
    }
    End{}
}