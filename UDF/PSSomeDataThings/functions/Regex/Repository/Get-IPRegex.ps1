function Get-IPRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching IP addresses

    .DESCRIPTION
        Generates regex patterns for IPv4, IPv6, or both. Patterns include
        named capture groups (ipv4, ipv6). Optionally anchored to full line.

    .PARAMETER IPv4
        Return only IPv4 pattern

    .PARAMETER IPv6
        Return only IPv6 pattern

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "192.168.1.1" -match (Get-IPRegex -IPv4)

    .NOTES
        Author  : Loïc Ade
        Version : 1.2.0
    #>
    Param(
        [switch]$IPv4,
        [switch]$IPv6,
        [switch]$FullLine,
        [switch]$DontIncludeSubpatternName
    )

    $sBaseIPv4Regex = "(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])"
    $sBaseIPv6Regex = "(?:(?:[0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){6}:[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){5}:(?:[0-9A-Fa-f]{1,4}:)?[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){4}:(?:[0-9A-Fa-f]{1,4}:){0,2}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){3}:(?:[0-9A-Fa-f]{1,4}:){0,3}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){2}:(?:[0-9A-Fa-f]{1,4}:){0,4}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){6}(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])|(?:[0-9A-Fa-f]{1,4}:){0,5}:(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])|::(?:[0-9A-Fa-f]{1,4}:){0,5}(?:(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])|[0-9A-Fa-f]{1,4}::(?:[0-9A-Fa-f]{1,4}:){0,5}[0-9A-Fa-f]{1,4}|::(?:[0-9A-Fa-f]{1,4}:){0,6}[0-9A-Fa-f]{1,4}|(?:[0-9A-Fa-f]{1,4}:){1,7}:)"

    $sIPv4Regex = if ($DontIncludeSubpatternName) {
        $sBaseIPv4Regex
    } else {
        "(?<ipv4>$sBaseIPv4Regex)"
    }
    $sIPv6Regex = if ($DontIncludeSubpatternName) {
        $sBaseIPv6Regex
    } else {
        "(?<ipv6>$sBaseIPv6Regex)"
    }

    $b4 = $IPv4 -or ((-not $IPv4) -and (-not $IPv6))
    $b6 = $IPv6 -or ((-not $IPv4) -and (-not $IPv6))
    if ($FullLine) {
        $sIPv4Regex = "^$sIPv4Regex$"
        $sIPv6Regex = "^$sIPv6Regex$"
    } 
    $sResult = if ($b4 -and $b6) {
        $sIPv4Regex + "|" + $sIPv6Regex
    } elseif ($b4 -and -not $b6) {
        $sIPv4Regex
    } elseif (-not $b4 -and $b6) {
        $sIPv6Regex
    } else {
        throw [System.ArgumentException] "Impossible state"
    }
    return $sResult
}