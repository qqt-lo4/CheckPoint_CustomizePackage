function Get-ItemIndex {
    <#
    .SYNOPSIS
        Finds the index of an item in an array matching a condition

    .DESCRIPTION
        Searches an array using a scriptblock condition and returns the index
        of the first matching item, or all matching indexes with -All.

    .PARAMETER InputObject
        The array of objects to search through (supports pipeline)

    .PARAMETER Condition
        A scriptblock that receives each item and returns $true for a match

    .PARAMETER All
        If specified, returns all matching indexes instead of just the first

    .OUTPUTS
        Int or Int[]. Index of the matching item(s), or -1 if not found.

    .EXAMPLE
        @("a","b","c") | Get-ItemIndex -Condition { $args[0] -eq "b" }
        # Returns: 1

    .EXAMPLE
        1..10 | Get-ItemIndex -Condition { $args[0] % 3 -eq 0 } -All
        # Returns: 2, 5, 8

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory = $false)]
        [switch]$All
    )
    
    begin {
        $array = @()
    }
    
    process {
        $array += $InputObject
    }
    
    end {
        if ($All) {
            $indexes = @()
            for ($i = 0; $i -lt $array.Count; $i++) {
                if (& $Condition $array[$i]) {
                    $indexes += $i
                }
            }
            return $indexes
        }
        else {
            for ($i = 0; $i -lt $array.Count; $i++) {
                if (& $Condition $array[$i]) {
                    return $i
                }
            }
            return -1
        }
    }
}
