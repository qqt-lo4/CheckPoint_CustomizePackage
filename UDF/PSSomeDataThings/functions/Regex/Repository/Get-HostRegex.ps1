function Get-HostRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching hosts (IP or DNS)

    .DESCRIPTION
        Combines IP address and DNS hostname regex patterns into a single
        alternation pattern.

    .PARAMETER IPv4
        Include only IPv4 in the IP portion

    .PARAMETER IPv6
        Include only IPv6 in the IP portion

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .OUTPUTS
        System.String. The regex pattern.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$IPv4,
        [switch]$IPv6,
        [switch]$FullLine
    )
    $sIPRegex = Get-IPRegEx @PSBoundParameters
    $sDNSRegex = Get-DNSRegex -FullLine:$FullLine
    return "$sIPRegex|$sDNSRegex"
}
