function New-CLIDialogObjectsRow {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object[]]$Row,
        [int]$FocusedItem = 0,
        [Alias("Text")]
        [string]$Header = "",
        [ValidateSet("Left", "Right")]
        [string]$HeaderAlign = "Left",
        [string]$HeaderSeparator = " : ",
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedHeaderForegroundColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$FocusedHeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [int]$SeparatorLocation,
        [string]$Prefix = "",
        [string]$FocusedPrefix = "",
        [string]$Name,
        [switch]$MandatoryRadioButtonValue,
        [switch]$InvisibleHeader
    )
    $bValid = $true
    $aItems = @()
    for ($i = 0; $i -lt $Row.Count; $i++) {
        if ($Row[$i].Type -in @("button", "checkbox", "space", "radiobutton")) {
            if ($Row[$i].Type -ne "space") {
                $aItems += $i
            }
        } else {
            $bValid = ($Row[$i].Type)
        }
    }
    if (-not $bValid) {
        throw "Row contains things that are not supported"
    }

    $hKeyboardObjects = @{}
    $hKeyboardToInt = @{}
    for ($i = 0; $i -lt $Row.Count; $i++) {
        if ($Row[$i].Keyboard) {
            $hKeyboardObjects.$($Row[$i].Keyboard.ToString().ToLower()) = $Row[$i]
            $hKeyboardToInt.$($Row[$i].Keyboard) = $aItems.IndexOf($i)
        }
    }

    $hResult = @{
        Type = "row"
        RowContent = $Row
        ObjectsIndex = $aItems
        FocusedItem = $FocusedItem
        KeyboardObjects = $hKeyboardObjects
        KeyboardToInt = $hKeyboardToInt
        Header = $Header
        HeaderAlign = $HeaderAlign
        HeaderSeparator = $HeaderSeparator
        HeaderBackgroundColor = $HeaderBackgroundColor
        HeaderForegroundColor = $HeaderForegroundColor
        FocusedHeaderBackgroundColor = $FocusedHeaderBackgroundColor
        FocusedHeaderForegroundColor = $FocusedHeaderForegroundColor
        SeparatorLocation = $SeparatorLocation
        Prefix = $Prefix
        FocusedPrefix = $FocusedPrefix
        Name = if ($Name) { $Name } else { "row" + $Header.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "").Replace(" ", "") }
        MandatoryRadioButtonValue = $MandatoryRadioButtonValue
        InvisibleHeader = $InvisibleHeader
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        Param(
            [bool]$DrawUnderlinedChar = $true
        )
        if ($this.Prefix) {
            Write-Host $this.Prefix -NoNewline -ForegroundColor $this.HeaderForegroundColor -BackgroundColor $this.HeaderBackgroundColor
        }
        if ($this.Header) {
            $iAlign = if ($this.HeaderAlign -eq "Left") { -1 } else { 1 }
            Write-Host (("{0,$($this.SeparatorLocation * $iAlign)}" -f $this.Header) + $this.HeaderSeparator) -NoNewline -ForegroundColor $this.HeaderForegroundColor -BackgroundColor $this.HeaderBackgroundColor
        }
        if ($this.InvisibleHeader) {
            Write-Host -NoNewline (" " * ($this.SeparatorLocation + $this.HeaderSeparator.Length))
        }
        for ($i = 0; $i -lt $this.RowContent.Count; $i++) {
            if ($this.RowContent[$i].Type -eq "space") {
                $this.RowContent[$i].Draw()
            } else {
                $this.RowContent[$i].Draw($DrawUnderlinedChar)
            }
        }
        Write-Host ""
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DrawFocused" -Value {
        Param(
            [bool]$DrawUnderlinedChar = $true
        )
        if ($this.FocusedPrefix) {
            Write-Host $this.FocusedPrefix -NoNewline -ForegroundColor $this.FocusedHeaderForegroundColor -BackgroundColor $this.FocusedHeaderBackgroundColor
        }
        if ($this.Header) {
            # Write Header
            $iAlign = if ($this.HeaderAlign -eq "Left") { -1 } else { 1 }
            $sPropertyToScreen = (("{0,$($this.SeparatorLocation * $iAlign)}" -f $this.Header) + $this.HeaderSeparator)
            Write-Host $sPropertyToScreen -NoNewline -ForegroundColor $this.FocusedHeaderForegroundColor -BackgroundColor $this.FocusedHeaderBackgroundColor
        }
        if ($this.InvisibleHeader) {
            Write-Host -NoNewline (" " * ($this.SeparatorLocation + $this.HeaderSeparator.Length))
        }
        for ($i = 0; $i -lt $this.RowContent.Count; $i++) {
            if ($this.RowContent[$i].Type -eq "space") {
                $this.RowContent[$i].Draw()
            } else {
                if ($this.ObjectsIndex.IndexOf($i) -eq $this.FocusedItem) {
                    $this.RowContent[$i].DrawFocused($DrawUnderlinedChar)
                } else {
                    $this.RowContent[$i].Draw($DrawUnderlinedChar)
                }
            }
        }
        Write-Host ""
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressLeft" -Value {
        if ($this.FocusedItem -le 0) {
            return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::LeftArrow, $false, $false, $false)
        } else {
            $this.FocusedItem--
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressRight" -Value {
        if ($this.FocusedItem -ge ($this.ObjectsIndex.Count - 1)) {
            return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::RightArrow, $false, $false, $false)
        } else {
            $this.FocusedItem++
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressTab" -Value {
        Param(
            [bool]$ShiftPressed = $false
        )
        if ($ShiftPressed) {
            $this.FocusedItem--
            if ($this.FocusedItem -lt 0) {
                $this.FocusedItem = 0
                return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::Tab, $true, $false, $false)
            }
        } else {
            $this.FocusedItem++
            if ($this.FocusedItem -ge $this.ObjectsIndex.Count) {
                $this.FocusedItem = $this.ObjectsIndex.Count - 1
                return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::Tab, $false, $false, $false)
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressKey" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        $oSelectedObject = $this.RowContent[$this.ObjectsIndex[$this.FocusedItem]]
        $oPressedKeyReturn = $oSelectedObject.PressKey($KeyInfo)
        if ($oPressedKeyReturn -is [System.ConsoleKeyInfo]) {
            switch ($KeyInfo.Key) {
                ([System.ConsoleKey]::LeftArrow) {
                    return $this.PressLeft()
                }
                ([System.ConsoleKey]::RightArrow) {
                    return $this.PressRight()
                }
                ([System.ConsoleKey]::Tab) {
                    if ($KeyInfo.Modifiers -eq [System.ConsoleModifiers]::Shift) {
                        return $this.PressTab($true)
                    } else {
                        return $this.PressTab($false)
                    }
                }
                default {
                    if (($KeyInfo.KeyChar) -and ($this.KeyboardObjects[$KeyInfo.KeyChar.ToString().ToLower()])) {
                        #$this.FocusedItem = $this.KeyboardToInt[$KeyInfo.KeyChar.ToString().ToLower()]
                        $oObject = $this.KeyboardObjects[$KeyInfo.KeyChar.ToString().ToLower()]
                        if ($oObject.Type -in @("checkbox", "radiobutton")) {
                            $oObject.ToggleValue()
                        } else {
                            return $oObject
                        }
                    } else {
                        return $KeyInfo
                    }
                }
            }
        } else {
            return $oPressedKeyReturn
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        $iMaxHeight = 0
        foreach ($item in $this.RowContent) {
            if (($item.GetTextHeight()) -and ($item.GetTextHeight() -gt $iMaxHeight)) {
                $iMaxHeight = $item.GetTextHeight()
            }
        }
        return $iMaxHeight
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        Param(
            [bool]$Verbose = $false
        )
        $iResult = 0
        if (($this.Header) -or ($this.InvisibleHeader)) {
            $iResult = $this.HeaderSeparator.Length + $this.SeparatorLocation + $this.Prefix.Length
        }
        foreach ($item in $this.RowContent) {
            $iResult += $item.GetTextWidth()
        }
        return $iResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Reset" -Value {
        foreach ($item in $this.RowContent) {
            if ("Reset" -in $item.PSObject.Members.Name) {
                $item.Reset()
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetText" -Value {
        return $this.Header.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "")
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsRadioButtonRow" -Value {
        $aObjectsWithoutSpace = $this.RowContent | Where-Object { $_.Type -ne "space"}
        $aRadioButtons = $this.RowContent | Where-Object { $_.Type -eq "radiobutton"}
        return ($aObjectsWithoutSpace.Count -eq $aRadioButtons.Count)
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetValue" -Value {
        if ($this.IsRadioButtonRow()) {
            $oSelectedRadioButton = $this.RowContent | Where-Object { ($_.Type -eq "radiobutton") -and $_.Enabled }
            if ($oSelectedRadioButton) {
                return $oSelectedRadioButton.GetText()
            } else {
                return $null
            }
        } else {
            return $null
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        foreach ($oItem in $this.RowContent) {
            if ($oItem.IsDynamicObject()) {
                return $true
            }
        }
        return $false
    }

    return $hResult
}
