function New-CLIDialogText {
    Param(
        [Parameter(Position = 0)]
        [AllowEmptyString()]
        [string]$Text,
        [System.ConsoleColor]$BackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [switch]$AddNewLine,
        [scriptblock]$TextFunction,
        [object]$TextFunctionArguments
    )
    $hResult = @{
        Type = "text"
        Text = $Text
        BackgroundColor = $BackgroundColor
        ForegroundColor = $ForegroundColor
        AddNewLine = $AddNewLine
        TextFunction = $TextFunction
        TextFunctionArguments = $TextFunctionArguments
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        $sText = $this.GetText()
        if (($sText -eq $null) -or ($sText -eq "")) {
            if ($this.AddNewLine) {
                Write-Host ""
            } else {
                Write-Host "" -NoNewline
            }
        } else {
            $aText = $sText.Split("`n")
            if ($aText.Count -gt 1) {
                foreach ($sLine in $aText) {
                    Write-Host $sLine -ForegroundColor $this.ForegroundColor -BackgroundColor $this.BackgroundColor
                }    
            } else {
                if ($this.AddNewLine) {
                    Write-Host $aText -ForegroundColor $this.ForegroundColor -BackgroundColor $this.BackgroundColor
                } else {
                    Write-Host $aText -NoNewline -ForegroundColor $this.ForegroundColor -BackgroundColor $this.BackgroundColor
                }
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetText" -Value {
        if ($this.TextFunction) {
            if ($null -ne $this.TextFunctionArguments) {
                $hArgs = $this.TextFunctionArguments
                $sResult = . $this.TextFunction @hArgs
            } else {
                $sResult = . $this.TextFunction 
            }
        } else {
            $sResult = $this.Text
        }
        return $sResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return $this.Text.Split("`n").Count
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        $iResult = 0
        $aText = $this.GetText().Split("`n")
        foreach ($sLine in $aText) {
            $sFilteredLine = $sLine -Replace "$([char]27)\[[^m]+m", ""
            if ($sFilteredLine.Length -gt $iResult) {
                $iResult = $sFilteredLine.Length
            }
        }
        return $iResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $false
    }

    return $hResult
}
