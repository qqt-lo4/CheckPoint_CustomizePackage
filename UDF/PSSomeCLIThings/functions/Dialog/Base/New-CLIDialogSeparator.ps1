function New-CLIDialogSeparator {
    <#
    .SYNOPSIS
        Creates a visual separator line for CLI dialog interfaces with optional pagination and interactivity.

    .DESCRIPTION
        This function creates a separator object that renders as a horizontal line in CLI dialogs.
        It supports various features including custom characters, automatic or fixed length, pagination
        indicators with arrows, centered text, and interactive "press key to continue" functionality.
        The separator can adapt to console width or use a fixed length.

    .PARAMETER Prefix
        A prefix string to display before the separator line. Default is empty string.

    .PARAMETER Char
        The character used to draw the separator line. Default is "-".
        Common alternatives include "=", "_", "─", or any other character.

    .PARAMETER Length
        The fixed length of the separator line in characters. This parameter is part of the "Length"
        parameter set. Cannot be used with -AutoLength.

    .PARAMETER AutoLength
        Switch parameter. When specified or by default, the separator automatically adjusts to the
        provided length when Draw() is called. This is the default behavior and part of the "Auto"
        parameter set.

    .PARAMETER DrawPageNumber
        Switch parameter. When specified, displays page numbers (e.g., " 2 / 5 ") in the center
        of the separator. Requires PageNumber and PageCount parameters.

    .PARAMETER DrawArrows
        Switch parameter. When specified with DrawPageNumber, displays navigation arrows (< and >)
        on the sides of the page number. Arrows are hidden on first/last pages.

    .PARAMETER PageNumber
        The current page number (zero-based). Used with DrawPageNumber. Must be less than PageCount.

    .PARAMETER PageCount
        The total number of pages. Used with DrawPageNumber. Must be greater than PageNumber.

    .PARAMETER LeftArrow
        The left arrow text to display. Default is "<--". Only visible when DrawArrows is set
        and not on the first page.

    .PARAMETER RightArrow
        The right arrow text to display. Default is "-->". Only visible when DrawArrows is set
        and not on the last page.

    .PARAMETER ForegroundColor
        The color of the separator line. Default is the current console foreground color.

    .PARAMETER PressKeyToContinue
        Switch parameter. When specified, displays a "press any key" message and waits for user input
        before drawing the separator. Useful for pagination or breakpoints.

    .PARAMETER PressKeyToContinueMessage
        The message to display when waiting for key press. Default is "Press any key to continue...".

    .PARAMETER Text
        Optional text to display centered in the separator line (e.g., "--- Section Title ---").
        Cannot be used with DrawPageNumber.

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, Char, Prefix, Length, AutoLength, DrawPageNumber, DrawArrows, PageNumber, PageCount, etc.
        - Methods: Draw([int]Length), GetFullLineText(), GetTextHeight(), GetTextWidth(), IsDynamicObject()

    .EXAMPLE
        $sep = New-CLIDialogSeparator -Length 50
        $sep.Draw()

        Creates a 50-character separator line with dashes.

    .EXAMPLE
        $sep = New-CLIDialogSeparator -Char "=" -AutoLength
        $sep.Draw(80)

        Creates an auto-length separator with equals signs, drawn at 80 characters wide.

    .EXAMPLE
        $sep = New-CLIDialogSeparator -DrawPageNumber -PageNumber 1 -PageCount 5 -DrawArrows
        $sep.Draw(60)

        Creates a separator displaying "2 / 5" (1+1 = page 2) with navigation arrows.

    .EXAMPLE
        $sep = New-CLIDialogSeparator -Text "Configuration" -Length 60 -Char "-"
        $sep.Draw()

        Creates a separator with centered text: "--- Configuration ---"

    .EXAMPLE
        $sep = New-CLIDialogSeparator -PressKeyToContinue -PressKeyToContinueMessage "Press Enter to continue..."
        $sep.Draw(50)

        Creates an interactive separator that waits for user input before displaying.

    .EXAMPLE
        $sep = New-CLIDialogSeparator -Prefix "  " -Char "─" -ForegroundColor Cyan
        $sep.Draw(70)

        Creates a cyan separator with 2-space prefix using box-drawing character.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: None

        This function is part of the CLI Dialog framework. It uses parameter sets to ensure
        either AutoLength or Length is used, but not both.

        PARAMETER SETS:
        - Auto: Default set, uses AutoLength (default behavior even if not specified)
        - Length: Uses fixed Length parameter

        METHODS:
        - Draw([int]Length): Renders the separator to the console with specified or automatic length
        - GetFullLineText(): Returns the complete separator text including page numbers/arrows/text
        - GetTextHeight(): Always returns 1 (separators are single-line)
        - GetTextWidth(): Returns the width of the separator line
        - IsDynamicObject(): Returns $false (separator is static)

        NOTES ON USAGE:
        - PageNumber is zero-based internally but displayed as 1-based (PageNumber=0 shows "1")
        - When AutoLength is used, must provide Length parameter to Draw() method
        - PressKeyToContinue only prompts once per object instance
        - Separator automatically adjusts if Length exceeds console width

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Support for fixed and automatic length
            - Pagination with page numbers and arrows
            - Centered text support
            - Interactive press-key-to-continue functionality
            - Custom character and color support
            - Automatic console width adjustment
    #>
    [CmdletBinding(DefaultParameterSetName = "Auto")]
    Param(
        [string]$Prefix = "",
        [string]$Char = "-",
        [Parameter(ParameterSetName = "Length")]
        [int]$Length,
        [Parameter(ParameterSetName = "Auto")]
        [switch]$AutoLength,
        [switch]$DrawPageNumber,
        [switch]$DrawArrows,
        [int]$PageNumber,
        [int]$PageCount,
        [string]$LeftArrow = "<--",
        [string]$RightArrow = "-->",
        [System.ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$PressKeyToContinue,
        [string]$PressKeyToContinueMessage = "Press any key to continue...",
        [string]$Text
    )
    if ($DrawPageNumber -and ($PageNumber -ge $PageCount)) {
        throw [System.ArgumentOutOfRangeException] "Page number too high"
    }
    if ($DrawPageNumber -and ($PageNumber -lt 0)) {
        throw [System.ArgumentOutOfRangeException] "Page number must be greater or equals 0"
    }
    $hResult = @{
        Type = "separator"
        Char = $Char
        Prefix = $Prefix
        DrawPageNumber = $DrawPageNumber
        DrawArrows = $DrawArrows
        LeftArrow = $LeftArrow
        RightArrow = $RightArrow
        ForegroundColor = $ForegroundColor
        PressKeyToContinue = $PressKeyToContinue
        PressKeyToContinueDone = $false
        PressKeyToContinueMessage = $PressKeyToContinueMessage
        Text = $Text
    }
    if ($PSCmdlet.ParameterSetName -eq "Length") {
        $hResult.Length = $Length
        $hResult.AutoLength = $false
    } else {
        if ($AutoLength.IsPresent) {
            $hResult.AutoLength = $AutoLength
        } else {
            $hResult.AutoLength = $true
        }
    }
    if ($DrawPageNumber) {
        $hResult.PageNumber = $PageNumber + 1
        $hResult.PageCount = $PageCount
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        Param(
            [int]$Length = -1
        )
        if ($this.AutoLength -and ($Length -le 0)) {
            throw [System.ArgumentOutOfRangeException] "Can't draw a separator with length equals $Length"
        }
        $iLength = if ($this.AutoLength) {
            $Length
        } else {
            $this.Length
        }
        $oHostUI = (Get-Host).UI.RawUI
        if ($iLength -gt $oHostUI.WindowSize.Width) {
            $iLength = $oHostUI.WindowSize.Width
        }
        Write-Host $this.Prefix -NoNewline
        if ($this.PressKeyToContinue) {
            $LineMessage = ""
            if (-not $this.PressKeyToContinueDone) {
                Write-Host $this.PressKeyToContinueMessage -NoNewline -ForegroundColor $this.ForegroundColor
                $LineMessage = "`r"
                [void][System.Console]::ReadKey($true)
                $this.PressKeyToContinueDone = $true
            }
            $LineMessage += ($this.Char * $iLength)
            Write-Host $LineMessage -ForegroundColor $this.ForegroundColor
        } else {
            $sFullLineText = $this.GetFullLineText()
            Write-Host $sFullLineText -ForegroundColor $this.ForegroundColor
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetFullLineText" -Value {
        if ((-not $this.DrawPageNumber) -and (-not $this.DrawArrows)) {
            if ($this.Text) {
                $sLineContent = " " + $this.Text + " " 
                $iMissingCharNumber = $iLength - $sLineContent.Length
                $iLeftSeparatorLength = [Math]::Ceiling($iMissingCharNumber / 2) 
                if ($iLeftSeparatorLength -lt 1) { $iLeftSeparatorLength = 1 }
                $sLeftSeparator = $this.Char * $iLeftSeparatorLength
                $iRightSeparatorLength = [Math]::Floor($iMissingCharNumber / 2) 
                if ($iRightSeparatorLength -lt 1) { $iRightSeparatorLength = 1 }
                $sRightSeparator = $this.Char * $iRightSeparatorLength
                $sFullLine = $sLeftSeparator + $sLineContent + $sRightSeparator
                return $sFullLine
            } else {
                # no page number or arrows, draw the full line
                return ($this.Char * $iLength)
            }
        } else {
            $sPageText = " $($this.PageNumber) / $($this.PageCount) "
            $sLeftArrow = if ($this.PageNumber -eq 1) { $this.Char * 4 } else { "$($this.LeftArrow) " }
            $sRightArrow = if ($this.PageNumber -eq $this.PageCount) { $this.Char * 4 } else { " $($this.RightArrow)" }
            $iMissingCharNumber = $iLength - $sPageText.Length - $sLeftArrow.Length - $sRightArrow.Length
            $iLeftSeparatorLength = [Math]::Ceiling($iMissingCharNumber / 2) 
            if ($iLeftSeparatorLength -lt 1) { $iLeftSeparatorLength = 1 }
            $sLeftSeparator = $this.Char * $iLeftSeparatorLength
            $iRightSeparatorLength = [Math]::Floor($iMissingCharNumber / 2) 
            if ($iRightSeparatorLength -lt 1) { $iRightSeparatorLength = 1 }
            $sRightSeparator = $this.Char * $iRightSeparatorLength
            $sFullLine = $sLeftArrow + $sLeftSeparator + $sPageText + $sRightSeparator + $sRightArrow
            return $sFullLine
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return 1
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        $sFullLineText = $this.GetFullLineText()
        return $sFullLineText.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $false
    }

    return $hResult
}
