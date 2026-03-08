function Measure-TextStats {
    <#
    .SYNOPSIS
        Measures statistics about a text string

    .DESCRIPTION
        Analyzes a text string and returns statistics. Currently supports measuring
        the maximum line width (longest line length) of multiline text.

    .PARAMETER InputObject
        The text string to analyze. Accepts pipeline input.

    .PARAMETER Width
        If specified, returns the maximum line width (length of the longest line).

    .OUTPUTS
        System.Int32. The measured statistic value.

    .EXAMPLE
        $text = "Short`nA longer line`nMid"
        $text | Measure-TextStats -Width
        # Returns 13 (length of "A longer line")

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string]$InputObject,
        [switch]$Width
    )
    if ($Width.IsPresent) {
        $aAllMatches = $InputObject | Select-String -Pattern "((?<line>.+)`r`n)|((?<line>.+)`n)|(?<line>.+)" -AllMatches
        $aLines = $aAllMatches.Matches.Groups | Where-Object {$_.Name -eq "line" }
        $iMax = 0
        foreach ($sLine in $aLines) {
            if ($sLine.Length -gt $iMax) {
                $iMax = $sLine.Length
            }
        }
        return $iMax
    }
}
