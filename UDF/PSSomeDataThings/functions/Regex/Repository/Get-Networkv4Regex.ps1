function Get-Networkv4Regex {
    <#
    .SYNOPSIS
        Returns a regex pattern for matching IPv4 network notation

    .DESCRIPTION
        Generates a regex pattern for IPv4 CIDR notation (ip/mask or ip/length).
        Includes named capture groups: ip, mask, masklength.

    .PARAMETER FullLine
        Anchor the pattern to match the entire line

    .OUTPUTS
        System.String. The regex pattern.

    .EXAMPLE
        "192.168.1.0/24" -match (Get-Networkv4Regex)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [switch]$FullLine,
        [switch]$DontIncludeSubpatternName
    )
    $sIPRegex = Get-IPRegex -IPv4 -DontIncludeSubpatternName
    $sPossibleByte = "255|254|252|248|240|224|192|128|0"
    $sMaskRegex = "(((255\.){3}($sPossibleByte))|((255\.){2}($sPossibleByte)\.0)|((255\.)($sPossibleByte)(\.0){2})|(($sPossibleByte)(\.0){3}))"
    $sMaskLengthRegex = "3[0-2]|[1-2][0-9]|[1-9]"
    if ($DontIncludeSubpatternName) {
        $sResult = "$sIPRegex\/(($sMaskRegex)|($sMaskLengthRegex))"
    } else {
        $sResult = "(?<ip>$sIPRegex)\/((?<mask>$sMaskRegex)|(?<masklength>$sMaskLengthRegex))"
    }
    if ($FullLine) {
        return "^$sResult$"
    } else {
        return $sResult
    }
}