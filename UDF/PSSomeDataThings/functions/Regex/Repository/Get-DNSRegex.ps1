function Get-DNSRegex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching DNS hostnames

    .DESCRIPTION
        Generates a regex pattern for DNS names with named capture groups.
        Supports optional wildcard matching and full-line anchoring.
        Enforces RFC 1123 label rules: labels must start and end with a letter
        or digit, and may contain hyphens/underscores in between. Each label
        is limited to 63 characters. At least one label must contain a letter,
        which prevents purely numeric strings (e.g. "1.1.2") from matching.

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .PARAMETER AllowWildcard
        Allow wildcard (*) as a standalone label in the DNS name

    .PARAMETER DontIncludeSubpatternName
        Omit named capture groups from the pattern

    .PARAMETER DontIncludeDnsPart
        Omit the dnspart capture group, keeping only the dns group

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "www.example.com" -match (Get-DNSRegex)

    .EXAMPLE
        "3com.example.com" -match (Get-DNSRegex)

    .EXAMPLE
        "1.1.2" -match (Get-DNSRegex)  # Returns False

    .NOTES
        Author  : Loïc Ade
        Version : 1.3.0
    #>
    Param(
        [switch]$FullLine,
        [switch]$AllowWildcard,
        [switch]$DontIncludeSubpatternName,
        [switch]$DontIncludeDnsPart
    )

    # Un label valide : commence et finit par une lettre ou un chiffre,
    # peut contenir des tirets/underscores au milieu, 63 caractères max
    $sEdgeChar  = "[\p{L}\p{Nd}]"
    $sInnerChar = "[\p{L}\p{Pc}\p{Pd}\p{Nd}]"
    $sBaseLabel = "(?:$sEdgeChar(?:$sInnerChar{0,61}$sEdgeChar)?)"
    $sBasePart  = if ($AllowWildcard) { "(?:\*|$sBaseLabel)" } else { $sBaseLabel }

    # Lookahead imposant qu'au moins une lettre soit présente dans le nom DNS
    # afin d'exclure les chaînes purement numériques comme "1.1.2"
    $sLetterLookahead = "(?=.*[\p{L}])"

    # Délimiteurs naturels entourant un hostname (début et fin de token)
    $sDelimiters    = "\s,;|\[\]()\{\}'`"<>"
    $sStartBoundary = "(?<![^$sDelimiters])"
    $sEndBoundary   = "(?=[$sDelimiters]|$)"

    $sResult = if ($DontIncludeSubpatternName) {
        "$sStartBoundary$sLetterLookahead$sBasePart(?:\.$sBasePart)*$sEndBoundary"
    } elseif ($DontIncludeDnsPart) {
        "$sStartBoundary$sLetterLookahead(?<dns>$sBasePart(?:\.$sBasePart)*)$sEndBoundary"
    } else {
        "$sStartBoundary$sLetterLookahead(?<dns>(?<dnspart>$sBasePart)(?:\.(?<dnspart>$sBasePart))*)$sEndBoundary"
    }

    if ($FullLine) {
        return "^$sResult$"
    } else {
        return $sResult
    }
}