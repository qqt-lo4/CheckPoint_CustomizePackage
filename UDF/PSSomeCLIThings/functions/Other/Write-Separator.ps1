function Write-Separator {
    <#
    .SYNOPSIS
        Writes a separator line with optional pagination indicators.

    .DESCRIPTION
        Renders a separator line made of a repeated character, with optional pagination
        indicators (e.g., "<-- ==== 2 / 5 ==== -->"). When PageCount is 0, outputs a
        simple full line. When pagination is active, displays left/right arrows (or filler
        characters at first/last page), a centered page indicator, and separator characters
        filling the remaining width. Supports returning as a string or writing directly
        to the console.

    .PARAMETER Char
        The character to repeat for the separator line.

    .PARAMETER Length
        Total length of the separator line.

    .PARAMETER PageNumber
        Current page number (1-based). Must be greater than 0 when PageCount is set.

    .PARAMETER PageCount
        Total number of pages. Set to 0 for a simple separator without pagination.

    .PARAMETER ReturnString
        Returns the separator as a string instead of writing to the console.

    .PARAMETER ForegroundColor
        Color for the separator line. Defaults to current console foreground color.

    .OUTPUTS
        [string] when -ReturnString is specified.
        None otherwise (writes to console via Write-Host).

    .EXAMPLE
        Write-Separator -Char "=" -Length 80

        Writes a line of 80 equal signs.

    .EXAMPLE
        Write-Separator -Char "-" -Length 60 -PageNumber 2 -PageCount 5 -ForegroundColor Cyan

        Writes a paginated separator: "<-- -------- 2 / 5 -------- -->" in cyan.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$Char,
        [int]$Length,
        [ValidateScript({$_ -ge 0})]
        [int]$PageNumber = 0,
        [ValidateScript({$_ -ge 0})]
        [int]$PageCount = 0,
        [switch]$ReturnString,
        [System.ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor
    )
    if ($PageCount -eq 0) {
        $sFullLine = $Char * $Length
        if ($ReturnString.IsPresent) {
            return "$sFullLine`n"
        } else {
            Write-Host $sFullLine -ForegroundColor $ForegroundColor
        }
    } else {
        if ($PageNumber -eq 0) {
            throw "Page number can't be 0"
        }
        if ($PageNumber -gt $PageCount) {
            throw "Page number can't be grater than page count"
        }
        $sPageText = " $PageNumber / $PageCount "
        $sLeftArrow = if ($PageNumber -eq 1) { $Char * 4 } else { "<-- " }
        $sRightArrow = if ($PageNumber -eq $PageCount) { $Char * 4 } else { " -->" }
        $iMissingCharNumber = $Length - $sPageText.Length - $sLeftArrow.Length - $sRightArrow.Length
        $iLeftSeparatorLength = [Math]::Ceiling($iMissingCharNumber / 2) 
        if ($iLeftSeparatorLength -lt 1) { $iLeftSeparatorLength = 1 }
        $sLeftSeparator = $Char * $iLeftSeparatorLength
        $iRightSeparatorLength = [Math]::Floor($iMissingCharNumber / 2) 
        if ($iRightSeparatorLength -lt 1) { $iRightSeparatorLength = 1 }
        $sRightSeparator = $Char * $iRightSeparatorLength
        $sFullLine = $sLeftArrow + $sLeftSeparator + $sPageText + $sRightSeparator + $sRightArrow
        if ($ReturnString.IsPresent) {
            return "$sFullLine`n"
        } else {
            Write-Host $sFullLine -ForegroundColor $ForegroundColor
        }
    }
}
