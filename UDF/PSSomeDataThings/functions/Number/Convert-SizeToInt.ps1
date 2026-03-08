function Convert-SizeToInt {
    <#
    .SYNOPSIS
        Converts a human-readable size string to bytes

    .DESCRIPTION
        Parses size strings like "10MB", "1 GB", "500KB" and converts them
        to their byte equivalent using PowerShell's built-in size suffixes.

    .PARAMETER Size
        Size string with unit suffix (KB, MB, GB, TB, PB)

    .OUTPUTS
        System.Int64. The size in bytes.

    .EXAMPLE
        Convert-SizeToInt "10MB"
        # Returns: 10485760

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Size
    )
    if ($Size -match "^([0-9]+) ?((K|k|M|m|G|g|T|t|P|p)(B|b))$") {
        Invoke-Expression $Size
    } else {
        throw [System.ArgumentOutOfRangeException] "`$Size is not valid"
    }
}