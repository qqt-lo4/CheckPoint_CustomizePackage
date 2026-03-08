function Get-HostPortRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching host:port combinations

    .DESCRIPTION
        Generates a regex pattern that matches IPv4, IPv6 (in brackets), or DNS
        hostnames with an optional port number. Includes named capture groups
        Host, IPv4Host, IPv6Host, DNSHost, and Port.

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "192.168.1.1:8080" -match (Get-HostPortRegex)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$FullLine
    )
    
    # Récupération des regex existantes
    $ipv4Regex = Get-IPRegex -IPv4
    $ipv6Regex = Get-IPRegex -IPv6
    $dnsRegex = Get-DNSRegex
    $portRegex = Get-PortRegex
    
    # Construction de la regex host avec support IPv6 entre crochets
    $ipv6WithBrackets = "\[(?<IPv6Host>" + $ipv6Regex.Replace('(?<ipv6>', '(?:')  + ")\]"
    $ipv4Host = "(?<IPv4Host>" + $ipv4Regex.Replace('(?<ipv4>', '(?:') + ")"
    $dnsHost = "(?<DNSHost>" + $dnsRegex.Replace('(?<dns>', '(?:') + ")"
   
    $sRegex = "(?<Host>$ipv6WithBrackets|$ipv4Host|$dnsHost)(?::(?<Port>$portRegex))?"
    
    if ($FullLine) {
        return "^$sRegex$"
    } else {
        return $sRegex
    }
}