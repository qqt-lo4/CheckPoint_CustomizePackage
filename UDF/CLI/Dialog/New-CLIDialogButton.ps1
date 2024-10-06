function New-CLIDialogButton {
    [CmdletBinding(DefaultParameterSetName = "None")]
    Param(
        [Parameter(Mandatory, ParameterSetName = "Yes", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "No", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Cancel", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Back", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Exit", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "None", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Validate", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Previous", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Next", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Refresh", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "Other", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "DoNotSelect", Position = 0)]
        [Parameter(Mandatory, ParameterSetName = "GoTo", Position = 0)]
        [string]$Text,
        [Parameter(Position = 1)]
        [System.ConsoleKey]$Keyboard,
        [Parameter(ParameterSetName = "Yes")]
        [switch]$Yes,
        [Parameter(ParameterSetName = "No")]
        [switch]$No,
        [Parameter(ParameterSetName = "Cancel")]
        [switch]$Cancel,
        [Parameter(ParameterSetName = "Back")]
        [switch]$Back,
        [Parameter(ParameterSetName = "Exit")]
        [switch]$Exit,
        [Parameter(ParameterSetName = "Validate")]
        [switch]$Validate,
        [Parameter(ParameterSetName = "Previous")]
        [switch]$Previous,
        [Parameter(ParameterSetName = "Next")]
        [switch]$Next,
        [Parameter(ParameterSetName = "Refresh")]
        [switch]$Refresh,
        [Parameter(ParameterSetName = "Other")]
        [switch]$Other,
        [Parameter(ParameterSetName = "DoNotSelect")]
        [switch]$DoNotSelect,
        [Parameter(ParameterSetName = "GoTo")]
        [switch]$GoTo,
        [System.ConsoleColor]$BackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedBackgroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedForegroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [object]$Object,
        [object]$ObjectSelectedProperties,
        [switch]$AddNewLine,
        [int]$Underline = -1,
        [switch]$NoSpace,
        [string]$Name
    )
    $sText = $Text
    if ($sText.Contains("&")) {
        $iAmpersand = $sText.IndexOf("&")
        $sText = $sText.Remove($iAmpersand, 1)
        $sText = $sText | Set-StringUnderline -Position $iAmpersand
    } elseif ($Underline -ge 0) {
        if ($Underline -ge $Text.Length) {
            throw [System.ArgumentOutOfRangeException] "Can't underline a character greater than string length"
        }
        $sText = $sText | Set-StringUnderline -Position $Underline
    }
    $hResult = @{
        Type = "button"
        Text = $sText
        Keyboard = $Keyboard
        BackgroundColor = $BackgroundColor
        ForegroundColor = $ForegroundColor
        FocusedBackgroundColor = $FocusedBackgroundColor
        FocusedForegroundColor = $FocusedForegroundColor
        Object = $Object
        ObjectSelectedProperties = $ObjectSelectedProperties
        AddNewLine = $AddNewLine
        NoSpace = $NoSpace
        Name = $Name
    }

    if ($PSCmdlet.ParameterSetName -eq "None") {
        if ($Object -is [scriptblock]) {
            $hResult.ButtonType = "Scriptblock"
        } else {
            $hResult.ButtonType = "Value"
        }
    } else {
        $hResult.ButtonType = if ($Object -is [scriptblock]) {
            "Action_Scriptblock"
        } else {
            "Action"
        }
        $hResult.Action = $PSCmdlet.ParameterSetName
        $hResult.$($PSCmdlet.ParameterSetName) = ($PSBoundParameters[$PSCmdlet.ParameterSetName] -eq $true)
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        Param(
            [bool]$DrawUnderlinedChar = $true
        )
        $sButtonText = if ($DrawUnderlinedChar) { $this.Text } else { $this.GetText() }
        $sText = if ($this.NoSpace) {
            $sButtonText
        } else {
            " $sButtonText "
        }
        Write-Host $sText -ForegroundColor $this.ForegroundColor -BackgroundColor $this.BackgroundColor -NoNewline
        if ($this.AddNewLine) {
            Write-Host "" 
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DrawFocused" -Value {
        Param(
            [bool]$DrawUnderlinedChar = $true
        )
        $sButtonText = if ($DrawUnderlinedChar) { $this.Text } else { $this.GetText() }
        $sText = if ($this.NoSpace) {
            $sButtonText
        } else {
            " $sButtonText "
        }
        Write-Host $sText -ForegroundColor $this.FocusedForegroundColor -BackgroundColor $this.FocusedBackgroundColor -NoNewline
        if ($this.AddNewLine) {
            Write-Host "" 
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetText" -Value {
        $sResult = $this.Text -Replace "$([char]27)\[[^m]+m", ""
        return $sResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressKey" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        if ([System.Char]::IsControl($KeyInfo.KeyChar)) {
            if (($KeyInfo.Key -eq [System.ConsoleKey]::Enter) -and ($this.Object)) {
                return $this
            } else {
                return $KeyInfo
            }
        } else {
            switch ($KeyInfo.KeyChar.ToString().ToLower()) {
                " " {
                    return $this
                }
                default {
                    if (($this.Keyboard) -and ($this.Keyboard -eq $KeyInfo.KeyChar)) {
                        return $this
                    } else {
                        return $KeyInfo
                    }
                }
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return $this.GetText().Split("`n").Count
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        $iResult = 0
        $aText = $this.GetText().Split("`n")
        foreach ($sLine in $aText) {
            if ($sLine.Length -gt $iResult) {
                $iResult = $sLine.Length
            }
        }
        if ($this.NoSpace) {
            return $iResult
        } else {
            return $iResult + 2
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $true
    }

    return $hResult
}
