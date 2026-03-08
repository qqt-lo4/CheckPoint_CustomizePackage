function Get-NetworkRangeRegex {
   Param(
        [switch]$IPv4,
        [switch]$IPv6,
        [switch]$FullLine,
        [switch]$DontIncludeSubpatternName
    )
    $bIPv4 = if ($IPv4) { $true } else { if ($IPv6) { $false } else { $true } }
    $bIPv6 = if ($IPv6) { $true } else { if ($IPv4) { $false } else { $true } }
    if ((-not $bIPv4) -and (-not $bIPv6)) {
        throw "At least one version of IP protocol is mandatory"
    }
    $sIP4Regex = Get-IPRegex -IPv4 -DontIncludeSubpatternName
    $sIP6Regex = Get-IPRegex -IPv6 -DontIncludeSubpatternName

    $sBaseRange4Regex = "$sIP4Regex-$sIP4Regex"
    $sBaseRange6Regex = "$sIP6Regex-$sIP6Regex"

    $sRange4Regex = if ($DontIncludeSubpatternName) { $sBaseRange4Regex } else { "(?<ipv4_range>$sBaseRange4Regex)" }
    $sRange6Regex = if ($DontIncludeSubpatternName) { $sBaseRange6Regex } else { "(?<ipv6_range>$sBaseRange6Regex)" }

    if ($FullLine) {
        $sRange4Regex = "^$sRange4Regex$"
        $sRange6Regex = "^$sRange6Regex$"
    }

    if ($bIPv4 -and $bIPv6) {
        return "$sRange4Regex|$sRange6Regex"
    } elseif ($bIPv4) {
        return $sRange4Regex
    } elseif ($bIPv6) {
        return $sRange6Regex
    } else {
        throw "Impossible case"
    }
}