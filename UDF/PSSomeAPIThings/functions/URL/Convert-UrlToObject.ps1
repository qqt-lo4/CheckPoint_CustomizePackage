function Convert-UrlToObject {
    <#
    .SYNOPSIS
        Parses a URL string into a structured object

    .DESCRIPTION
        Uses regex to decompose a URL into its components: protocol, hostname,
        resource path, and query parameters. Query parameters are parsed into
        a hashtable of key-value pairs.

    .PARAMETER Url
        The URL string to parse.

    .OUTPUTS
        [hashtable]. Contains protocol, hostname, ressource, param (hashtable), and Url properties.

    .EXAMPLE
        Convert-UrlToObject -Url "https://api.example.com/v1/users?page=1&limit=10"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Url
    )
    $sRegex = "^(?<protocol>[a-zA-Z]+)://(?<hostname>[a-zA-Z0-9_.+]+)/(?<ressource>[^?]+)(\?((?<param>[^&]+)&?)+)?"
    $oSelectString = Select-String -InputObject $Url -Pattern $sRegex -AllMatches
    if ($oSelectString) {
        $hURLContent = Convert-MatchingGroupToHashtable $oSelectString
        $hURLContent.Url = $Url
        $hParameters = @{}
        foreach ($sParameter in $hURLContent.param) {
            $oSelectStringParam = Select-String -InputObject $sParameter -Pattern "^(?<key>[^=]+)=(?<value>.+)$"
            $sKey = ($oSelectStringParam.Matches.Groups | Where-Object { $_.Name -eq "key"}).Value
            $sValue = ($oSelectStringParam.Matches.Groups | Where-Object { $_.Name -eq "value"}).Value
            $hParameters.$sKey = $sValue
        }
        $hURLContent.param = $hParameters
    }
    return $hURLContent
}
