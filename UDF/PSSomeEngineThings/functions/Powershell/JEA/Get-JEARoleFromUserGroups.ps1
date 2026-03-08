function Get-JEARoleFromUserGroups {
    <#
    .SYNOPSIS
        Gets JEA roles from user group memberships

    .DESCRIPTION
        Extracts JEA role names from user's group memberships using regex pattern matching.
        Filters groups to identify JEA-related groups and extracts role names.

    .PARAMETER Credential
        Credentials to use when retrieving user groups.

    .PARAMETER Filter
        Regex pattern to match JEA groups (default: "^(.+)\\ps_jea_(.+)$").

    .PARAMETER ResultPatternIndex
        Index of regex match group to extract (-1 for last match group).

    .OUTPUTS
        [String[]]. Array of JEA role names extracted from group memberships.

    .EXAMPLE
        Get-JEARoleFromUserGroups -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [pscredential]$Credential,
        [string]$Filter = "^(.+)\\ps_jea_(.+)$",
        [int]$ResultPatternIndex = -1
    )
    $aCurrentDomainGroups = Get-CurrentUserGroups @PSBoundParameters -Regex
    $aResult = @()
    foreach ($itemGroup in $aCurrentDomainGroups) {
        if ($itemGroup."Domain Object Name" -match $Filter) {
            $iIndex = if (($ResultPatternIndex -lt $Matches.Keys.Count) -and ($ResultPatternIndex -ge (- $Matches.Keys.Count))) {
                if ($ResultPatternIndex -ge 0) {
                    $ResultPatternIndex
                } else {
                    $Matches.Keys.Count + $ResultPatternIndex
                }
            } else {
                throw [System.ArgumentOutOfRangeException] "Index out of range"
            }
            $aResult += $Matches.$iIndex
        }
    }
    return $aResult
}