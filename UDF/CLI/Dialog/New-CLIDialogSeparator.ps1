function New-CLIDialogSeparator {
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
        $hResult.AutoLength = $AutoLength
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
