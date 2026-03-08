function Get-NetworkObjectRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching network objects

    .DESCRIPTION
        Combines IP addresses, IP ranges, network CIDR notations, and DNS hostnames
        into a single regex pattern. Each object type can be individually toggled
        via switch parameters. When no switch is specified, all types are included.
        Includes named capture groups from all underlying patterns.

    .PARAMETER IP
        Include IP address pattern (IPv4 and/or IPv6)

    .PARAMETER Range
        Include IP range pattern (IPv4 and/or IPv6)

    .PARAMETER Network
        Include network CIDR pattern (IPv4 and/or IPv6)

    .PARAMETER DNS
        Include DNS hostname pattern

    .PARAMETER IPv4
        Restrict IP/Range/Network patterns to IPv4 only

    .PARAMETER IPv6
        Restrict IP/Range/Network patterns to IPv6 only

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .PARAMETER AllowWildcard
        Allow wildcard (*) in DNS patterns (only relevant when DNS is included)

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "192.168.1.1" -match (Get-NetworkObjectRegex -IP)

    .EXAMPLE
        "192.168.1.1-192.168.1.254" -match (Get-NetworkObjectRegex -Range -IPv4)

    .EXAMPLE
        "fe80::1/64" -match (Get-NetworkObjectRegex -Network -IPv6)

    .EXAMPLE
        "www.example.com" -match (Get-NetworkObjectRegex -DNS)

    .EXAMPLE
        "192.168.1.1" -match (Get-NetworkObjectRegex)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$IP,
        [switch]$Range,
        [switch]$Network,
        [switch]$DNS,
        [switch]$IPv4,
        [switch]$IPv6,
        [switch]$FullLine,
        [switch]$AllowWildcard
    )

    # Si aucun type d'objet n'est spécifié, on les inclut tous
    $bIP      = $IP      -or ((-not $IP) -and (-not $Range) -and (-not $Network) -and (-not $DNS))
    $bRange   = $Range   -or ((-not $IP) -and (-not $Range) -and (-not $Network) -and (-not $DNS))
    $bNetwork = $Network -or ((-not $IP) -and (-not $Range) -and (-not $Network) -and (-not $DNS))
    $bDNS     = $DNS     -or ((-not $IP) -and (-not $Range) -and (-not $Network) -and (-not $DNS))

    # Construction des paramètres communs pour les fonctions IP/Range/Network
    $ipVersionParams = @{}
    if ($IPv4 -and -not $IPv6) { $ipVersionParams['IPv4'] = $true }
    elseif ($IPv6 -and -not $IPv4) { $ipVersionParams['IPv6'] = $true }

    $patterns = @()

    if ($bNetwork) {
        $patterns += Get-NetworkRegex @ipVersionParams -DontIncludeSubpatternName:$false
    }
    if ($bRange) {
        $patterns += Get-NetworkRangeRegex @ipVersionParams -DontIncludeSubpatternName:$false
    }
    if ($bIP) {
        $patterns += Get-IPRegex @ipVersionParams -DontIncludeSubpatternName:$false
    }
    if ($bDNS) {
        $patterns += Get-DNSRegex -AllowWildcard:$AllowWildcard -DontIncludeSubpatternName:$false -DontIncludeDnsPart
    }

    $sResult = $patterns -join "|"

    if ($FullLine) {
        return "^$sResult$"
    } else {
        return $sResult
    }
}