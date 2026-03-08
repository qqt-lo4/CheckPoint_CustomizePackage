function Get-NetworkRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching IPv4 or IPv6 network CIDR notation

    .DESCRIPTION
        Combines Get-Networkv4Regex and Get-Networkv6Regex to generate a pattern
        matching either IPv4 CIDR notation (ip/mask or ip/length) or IPv6 CIDR
        notation (address/prefix-length). Includes all named capture groups from
        both patterns.

    .PARAMETER IPv4
        Return only IPv4 pattern

    .PARAMETER IPv6
        Return only IPv6 pattern

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .PARAMETER DontIncludeSubpatternName
        Omit named capture groups from the pattern

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "192.168.1.0/24" -match (Get-NetworkRegex -IPv4)

    .EXAMPLE
        "fe80::1/64" -match (Get-NetworkRegex -IPv6)

    .EXAMPLE
        "192.168.1.0/255.255.255.0" -match (Get-NetworkRegex)

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0
    #>
    Param(
        [switch]$IPv4,
        [switch]$IPv6,
        [switch]$FullLine,
        [switch]$DontIncludeSubpatternName
    )
    $bIPv4 = $IPv4 -or ((-not $IPv4) -and (-not $IPv6))
    $bIPv6 = $IPv6 -or ((-not $IPv4) -and (-not $IPv6))

    $sBaseRange4Regex = Get-Networkv4Regex -DontIncludeSubpatternName
    $sBaseRange6Regex = Get-Networkv6Regex -DontIncludeSubpatternName

    $sRange4Regex = if ($DontIncludeSubpatternName) { $sBaseRange4Regex } else { "(?<ipv4_network>$sBaseRange4Regex)" }
    $sRange6Regex = if ($DontIncludeSubpatternName) { $sBaseRange6Regex } else { "(?<ipv6_network>$sBaseRange6Regex)" }

    if ($bIPv4 -and $bIPv6) {
        $sResult = "$sRange4Regex|$sRange6Regex"
    } elseif ($bIPv4) {
        $sResult = $sRange4Regex
    } elseif ($bIPv6) {
        $sResult = $sRange6Regex
    } else {
        throw [System.ArgumentException] "Impossible state"
    }

    if ($FullLine) {
        return "^$sResult$"
    } else {
        return $sResult
    }
}