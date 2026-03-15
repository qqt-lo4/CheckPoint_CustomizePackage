function Get-DNRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching X.500 Distinguished Names (DN)

    .DESCRIPTION
        Generates a regex pattern for certificate-style Distinguished Names.
        Supports common RDN attributes: CN, OU, O, L, ST, C, E, DC.
        Handles escaped commas, quoted values, and wildcard characters.

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .PARAMETER DontIncludeSubpatternName
        Omit named capture groups from the pattern

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "CN=server.example.com" -match (Get-DNRegex)

    .EXAMPLE
        "CN=*.example.com,O=MyOrg,C=FR" -match (Get-DNRegex -FullLine)

    .EXAMPLE
        'CN=server,OU=IT,O=Company,L=Paris,ST=IDF,C=FR' -match (Get-DNRegex)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-14)
            - Initial version
    #>
    Param(
        [switch]$FullLine,
        [switch]$DontIncludeSubpatternName
    )

    # RDN attribute types
    $sAttrType = "(?:CN|OU|O|L|ST|C|E|DC)"

    # RDN value: quoted string or unquoted (with escaped commas allowed)
    $sAttrValue = '(?:"[^"]*"|(?:\\,|[^,])+)'

    # Single RDN: type=value
    $sRDN = "$sAttrType\s*=\s*$sAttrValue"

    # Full DN: one or more RDNs separated by commas
    $sResult = if ($DontIncludeSubpatternName) {
        "$sRDN(?:\s*,\s*$sRDN)*"
    } else {
        "(?<dn>$sRDN(?:\s*,\s*$sRDN)*)"
    }

    if ($FullLine) {
        return "^$sResult$"
    } else {
        return $sResult
    }
}
