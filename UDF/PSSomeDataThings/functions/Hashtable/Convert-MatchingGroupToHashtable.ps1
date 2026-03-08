function Convert-MatchingGroupToHashtable {
    <#
    .SYNOPSIS
        Converts Select-String named capture groups to a hashtable

    .DESCRIPTION
        Extracts named matching group values from a Select-String result
        and creates a hashtable with group names as keys and captured values.

    .PARAMETER MatchInfo
        The MatchInfo object returned by Select-String

    .OUTPUTS
        Hashtable. Named capture groups as key-value pairs.

    .EXAMPLE
        $result = "http://www.google.com" | Select-String -Pattern "^(?<protocol>[a-zA-Z]+)://(?<hostname>[^/]+)/?" -AllMatches
        Convert-MatchingGroupToHashtable $result
        # Returns: @{ protocol = "http"; hostname = "www.google.com" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        Version 1.0: First version (2023-09-09)
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [Microsoft.PowerShell.Commands.MatchInfo]$MatchInfo
    )
    $hResult = @{}
    foreach ($CaptureGroup in $MatchInfo.Matches.Groups.Name) {
        if ($CaptureGroup -notmatch "[0-9]+") {
            $hResult.$CaptureGroup = ($MatchInfo.Matches.Groups | Where-Object { $_.name -eq $CaptureGroup }).Captures.Value
        }
    }
    return $hResult
}