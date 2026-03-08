function Get-PortRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching TCP/UDP port numbers (0-65535)

    .DESCRIPTION
        Generates a regex pattern that matches valid port numbers in the range 0-65535.

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .OUTPUTS
        System.String. The regex pattern.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$FullLine
    )
    if ($FullLine) {
        return "^6553[0-5]$|^655[0-2][0-9]$|^65[0-4][0-9][0-9]$|^6[0-4][0-9][0-9][0-9]$|^[1-5][0-9][0-9][0-9][0-9]$|^[1-9][0-9][0-9][0-9]$|^[1-9][0-9][0-9]$|^[1-9][0-9]$|^[0-9]$"
    } else {
        "6553[0-5]|655[0-2][0-9]|65[0-4][0-9][0-9]|6[0-4][0-9][0-9][0-9]|[1-5][0-9][0-9][0-9][0-9]|[1-9][0-9][0-9][0-9]|[1-9][0-9][0-9]|[1-9][0-9]|[0-9]"
    }
}