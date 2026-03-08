function Write-ColoredString {
    <#
    .SYNOPSIS
        Writes a string to the console with regex-based color highlighting.

    .DESCRIPTION
        Outputs a string with selective color highlighting based on regex pattern matching.
        When a Pattern is provided, matching portions are displayed in MatchForegroundColor
        and non-matching portions in ForegroundColor. Supports selecting specific regex
        capture groups to color, coloring all matches, and NoNewLine mode. Without a
        pattern, the entire string is written in the match color.

    .PARAMETER InputObject
        The string to display. Accepts pipeline input.

    .PARAMETER Pattern
        Regex pattern for color highlighting. When omitted, the entire string
        is written in MatchForegroundColor.

    .PARAMETER ColorGroups
        Regex group names to colorize. Default: @("0") (entire match).

    .PARAMETER ForegroundColor
        Color for non-matching text portions. Defaults to current console foreground color.

    .PARAMETER BackgroundColor
        Background color for non-matching text. Defaults to current console background color.

    .PARAMETER MatchForegroundColor
        Color for matching text portions. Defaults to current console foreground color.

    .PARAMETER MatchBackgroundColor
        Background color for matching text. Defaults to current console background color.

    .PARAMETER AllMatches
        Color all regex matches, not just the first.

    .PARAMETER NoNewLine
        Suppress the trailing newline character.

    .OUTPUTS
        None. Writes colored output to the console via Write-Host.

    .EXAMPLE
        "Hello World" | Write-ColoredString -Pattern "World" -MatchForegroundColor Red

        Displays "Hello " in default color and "World" in red.

    .EXAMPLE
        Write-ColoredString -InputObject "Error: file not found" -Pattern "Error" -Color Yellow -AllMatches

        Highlights all occurrences of "Error" in yellow.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [Alias("Object")]
        [object]$InputObject,
        [string]$Pattern,
        [string[]]$ColorGroups = @("0"),
        [System.ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$BackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [Alias("Color")]
        [System.ConsoleColor]$MatchForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$MatchBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [switch]$AllMatches,
        [switch]$NoNewLine
    )
    Begin {}
    Process {
        $InputObject | . { 
            Process {
                if ($Pattern) {
                    $ss = Select-String -InputObject $_ -Pattern $Pattern -AllMatches:$AllMatches
                    if ($ss) {
                        $aCaptures = ($ss.Matches.Groups | Where-Object { $_.Name -in $ColorGroups }).Captures | Sort-Object -Property "Index"
                        $j = 0
                        for ($i = 0; $i -lt $aCaptures.Count; $i++) {
                            if ($aCaptures[$i].Index -gt $j) {
                                # not matching section
                                $iStart = $j
                                $iLength = ($aCaptures[$i].Index) -$j
                                $sSubString = $_.ToString().Substring($iStart, $iLength)
                                Write-Host -Object $sSubString -NoNewline -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
                                $j = $aCaptures[$i].Index
                            }
                            if ($j -lt $_.Length) {
                                $sSubString = $_.ToString().Substring($aCaptures[$i].Index, $aCaptures[$i].Length)
                                Write-Host -Object $sSubString -NoNewline -ForegroundColor $MatchForegroundColor -BackgroundColor $MatchBackgroundColor
                                $j = $aCaptures[$i].Index + $aCaptures[$i].Length
                            }
                        }
                        if (-not $NoNewLine) {
                            Write-Host ""
                        }
                    } else {
                        Write-Host $_ -NoNewline -ForegroundColor $ForegroundColor -BackgroundColor $BackgroundColor
                        if (-not $NoNewLine) {
                            Write-Host ""
                        }
                    }
                } else {
                    Write-Host -Object $_ -NoNewline:$NoNewLine -ForegroundColor $MatchForegroundColor -BackgroundColor $BackgroundColor
                }
            }
        }
    }
    End {}
}