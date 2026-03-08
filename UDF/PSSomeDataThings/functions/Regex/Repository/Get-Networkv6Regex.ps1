function Get-Networkv6Regex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching IPv6 network CIDR notation

    .DESCRIPTION
        Generates a regex pattern for IPv6 CIDR notation (address/prefix-length).
        Includes named capture groups: ipv6, prefixlength (0-128).

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "fe80::1/64" -match (Get-Networkv6Regex)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$FullLine,
        [switch]$DontIncludeSubpatternName
    )

    # Obtenir la regex IPv6 de base (sans groupes nommés pour éviter les imbrications)
    $sIPv6Regex = Get-IPRegex -IPv6 -DontIncludeSubpatternName

    # Regex pour la longueur de préfixe IPv6 (0 à 128)
    $sPrefixLengthRegex = "([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8])"

    # En IPv6, on utilise uniquement la notation CIDR avec longueur de préfixe
    # Pas de masque en notation décimale comme en IPv4
    if ($DontIncludeSubpatternName) {
        $sResult = "$sIPv6Regex\/($sPrefixLengthRegex)"
    } else {
        $sResult = "(?<ipv6>$sIPv6Regex)\/(?<prefixlength>$sPrefixLengthRegex)"
    }
    
    if ($FullLine) {
        return "^$sResult$"
    } else {
        return $sResult
    }
}
