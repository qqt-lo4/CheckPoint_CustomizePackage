function Format-ArrayHashtable {
    <#
    .SYNOPSIS
        Formats an array of hashtables as a table.

    .DESCRIPTION
        Converts an array of hashtables into PSCustomObjects and displays them
        as a formatted table using Format-Table -AutoSize.

    .PARAMETER array
        The array of hashtables to format. Accepts pipeline input.

    .OUTPUTS
        Formatted table output to the console.

    .EXAMPLE
        @(@{Name="A"; Value=1}, @{Name="B"; Value=2}) | Format-ArrayHashtable

        Displays the hashtable array as a formatted table.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [hashtable[]]$array
    )
    $array | ForEach-Object {[PSCustomObject]$_} | Format-Table -AutoSize
}
