function Get-MacAddressRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching MAC addresses

    .DESCRIPTION
        Generates a regex pattern that matches MAC addresses in various formats
        (colon, dash, or no separator). Includes a named capture group "mac".

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "AA:BB:CC:DD:EE:FF" -match (Get-MacAddressRegex)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$FullLine
    )
    $symbols = "A-Fa-f0-9"
    $sResult = "(?<mac>((?<symbols>[$symbols]{2})[^$symbols]?){5}(?<symbols>[$symbols]{2}))"
    if ($FullLine) {
        return "^$sResult$"
    } else {
        return $sResult
    }
}
