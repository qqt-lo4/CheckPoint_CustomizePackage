function New-CLIDialogTextBox {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Header,
        [ValidateSet("Left", "Right")]
        [string]$HeaderAlign = "Left",
        [string]$HeaderSeparator = " : ",
        [System.ConsoleColor]$TextForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$TextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedTextForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedTextBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedHeaderForegroundColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$FocusedHeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [int]$SeparatorLocation,
        [object]$Text = "",
        [string]$Prefix,
        [string]$FocusedPrefix,
        [string]$Regex,
        [object]$ValidationScript,
        [System.ConsoleColor]$ValidationErrorColor = [System.ConsoleColor]::Red,
        [string]$ValidationErrorReason,
        [string]$FieldNameInErrorReason,
        [char]$PasswordChar,
        [string]$Name,
        [object]$ValueConvertFunction
    )
    $sText, $sPasswordChar = if (($Text -is [string]) -or ($Text -is [int])) {
        $sTextResult = $Text.ToString()
        $sPasswordCharResult = if ($PasswordChar) { $PasswordChar } else { $null }
        $sTextResult, $sPasswordCharResult
    } elseif ($Text -is [securestring]) {
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Text)
        $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) | Out-Null
        $sPasswordCharResult = if ($PasswordChar) { $PasswordChar } else { "*" }
        $UnsecurePassword, $sPasswordCharResult
    } else {
        throw [System.ArgumentException] "Unsupported `$Text type"
    }
    $hResult = @{
        Type = "textbox"
        Header = $Header
        HeaderAlign = $HeaderAlign
        HeaderSeparator = $HeaderSeparator
        TextBackgroundColor = $TextBackgroundColor
        TextForegroundColor = $TextForegroundColor
        HeaderBackgroundColor = $HeaderBackgroundColor
        HeaderForegroundColor = $HeaderForegroundColor
        FocusedTextBackgroundColor = $FocusedTextBackgroundColor
        FocusedTextForegroundColor = $FocusedTextForegroundColor
        FocusedHeaderBackgroundColor = $FocusedHeaderBackgroundColor
        FocusedHeaderForegroundColor = $FocusedHeaderForegroundColor
        SeparatorLocation = $SeparatorLocation
        Text = $sText
        OriginalText = $sText
        Prefix = $Prefix
        FocusedPrefix = $FocusedPrefix
        CursorPosition = if ($sText) { $sText.Length } else { 0 }
        Regex = $Regex
        ValidationScript = $ValidationScript
        ValidationErrorColor = $ValidationErrorColor
        FieldNameInErrorReason = $FieldNameInErrorReason
        ValidationErrorReason = $ValidationErrorReason
        LastValidation = $true
        PasswordChar = $sPasswordChar
        Name = if ($Name) { $Name } else { "textbox" + $Header.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "").Replace(" ", "") }
        ValueConvertFunction = $ValueConvertFunction
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsValidText" -Value {
        if ($this.Regex -or $this.ValidationScript) {
            if ($this.LastTestedText -eq $this.Text) {
                return $this.LastValidation
            } else {
                $this.LastValidation, $this.LastValidationDetails = if ($this.Regex) {
                    $bValidationResult = Select-String -InputObject $this.Text -Pattern $this.Regex -AllMatches
                    $bValidationResult -ne $null
                    $bValidationResult
                } else {
                    $bValidationResult = . $this.ValidationScript $this.Text
                    if ($bValidationResult) {
                        $true, $bValidationResult
                    } else {
                        $false, $false
                    }
                }
                $this.LastTestedText = $this.Text
                return $this.LastValidation
            }
        } else {
            return $true
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        $iAlign = if ($this.HeaderAlign -eq "Left") { -1 } else { 1 }
        $sHeader = ("" + $this.Prefix + ("{0,$($this.SeparatorLocation * $iAlign)}" -f $this.Header) + $this.HeaderSeparator)
        $oHeaderColor = if ($this.IsValidText()) {
            $this.HeaderForegroundColor
        } else {
            $this.ValidationErrorColor
        }
        Write-Host $sHeader -ForegroundColor $oHeaderColor -BackgroundColor $this.HeaderBackgroundColor -NoNewline
        $sPrintedTest = if ($this.PasswordChar) { $this.PasswordChar.ToString() * $this.Text.Length } else { $this.Text }
        Write-Host $sPrintedTest -ForegroundColor $this.TextForegroundColor -BackgroundColor $this.TextBackgroundColor -NoNewline
        $sRemainingSpace = " " * ($host.ui.RawUI.WindowSize.Width - $sHeader.Length - $this.Text.Length)
		Write-Host $sRemainingSpace
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DrawFocused" -Value {
        # Write Header
        $iAlign = if ($this.HeaderAlign -eq "Left") { -1 } else { 1 }
        $sPropertyToScreen = ("" + $this.FocusedPrefix + ("{0,$($this.SeparatorLocation * $iAlign)}" -f $this.Header) + $this.HeaderSeparator)
        $oHeaderColor = if ($this.IsValidText()) {
            $this.FocusedHeaderForegroundColor
        } else {
            $this.ValidationErrorColor
        }
        Write-Host $sPropertyToScreen -NoNewline -ForegroundColor $oHeaderColor -BackgroundColor $this.FocusedHeaderBackgroundColor
        # Write Text
        if ($this.Text.Length -gt 0) {
            if (($this.CursorPosition - 1) -ge 0) {
                $sTextBefore = ($this.Text[0..$($this.CursorPosition - 1)] -join "")
                if ($this.PasswordChar) {
                    $sTextBefore = $this.PasswordChar.ToString() * $sTextBefore.Length
                }
                Write-Host $sTextBefore -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
            }
            if ($this.Text[$this.CursorPosition]) {
                $sCharMiddle = if ($this.PasswordChar) { $this.PasswordChar.ToString() } else { $this.Text[$this.CursorPosition] }
                Write-Host $sCharMiddle -NoNewline -ForegroundColor $this.FocusedTextBackgroundColor -BackgroundColor $this.FocusedTextForegroundColor
            }
            if ($this.Text[$this.CursorPosition + 1]) {
                $sTextAfter = ($this.Text[$($this.CursorPosition + 1)..$($this.Text.Length)] -join "")
                if ($this.PasswordChar) {
                    $sTextAfter = $this.PasswordChar.ToString() * $sTextAfter.Length
                }
                Write-Host $sTextAfter -NoNewline -ForegroundColor $this.FocusedTextForegroundColor -BackgroundColor $this.FocusedTextBackgroundColor
            }
        }
        if ($this.CursorPosition -lt 0) {
            $this.CursorPosition = 0
        } elseif ($this.CursorPosition -gt $this.Text.Length) {
            $this.CursorPosition = $this.Text.Length
        } 
        if (($this.CursorPosition -eq $this.Text.Length) -or ($this.Text.Length -eq 0)) {
            Write-Host " " -ForegroundColor Black -BackgroundColor White -NoNewline
            $sRemainingSpace = " " * ($host.ui.RawUI.WindowSize.Width - $sPropertyToScreen.Length - $this.Text.Length - 1)
            Write-Host $sRemainingSpace
        } else {
            $sRemainingSpace = " " * ($host.ui.RawUI.WindowSize.Width - $sPropertyToScreen.Length - $this.Text.Length)
            Write-Host $sRemainingSpace
        }

    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressLeft" -Value {
        if ($this.CursorPosition -eq 0) {
            return [System.ConsoleKeyInfo]::LeftArrow
        } else {
            $this.CursorPosition--
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressRight" -Value {
        if ($this.CursorPosition -eq $this.Text.Length) {
            return [System.ConsoleKeyInfo]::RightArrow
        } else {
            $this.CursorPosition++
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressBackspace" -Value {
        if ($this.CursorPosition -gt 0) {
            $sPrefix = if ($this.CursorPosition -eq 1) {
                ""
            } else {
                $this.Text[0..$($this.CursorPosition - 2)] -join ""
            } 
            $sSuffix = $this.Text[$this.CursorPosition..$($this.Text.Length)] -join ""
            $this.Text = $sPrefix + $sSuffix
            $this.CursorPosition--
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressDelete" -Value {
        if ($this.CursorPosition -lt $this.Text.Length) {
            $sPrefix = if ($this.CursorPosition -gt 0) {
                $this.Text[0..$($this.CursorPosition - 1)] -join ""
            } else {
                ""
            } 
            $sSuffix = $this.Text[($this.CursorPosition + 1)..$($this.Text.Length)] -join ""
            $this.Text = $sPrefix + $sSuffix
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressHome" -Value {
        $this.CursorPosition = 0
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressEnd" -Value {
        $this.CursorPosition = $this.Text.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressUp" -Value {
        $hResult = @{
            Key = [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::UpArrow, $false, $false, $false)
            Options = $this.CursorPosition
        }
        return $hResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressDown" -Value {
        $hResult = @{
            Key = [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::DownArrow, $false, $false, $false)
            Options = $this.CursorPosition
        }
        return $hResult
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressKey" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        $this.LastTestedText = $this.Text
        if ([System.Char]::IsControl($KeyInfo.KeyChar)) {
            switch ($KeyInfo.Key) {
                ([System.ConsoleKey]::LeftArrow) { return $this.PressLeft() }
                ([System.ConsoleKey]::RightArrow) { return $this.PressRight() }
                ([System.ConsoleKey]::UpArrow) { return $this.PressUp() }
                ([System.ConsoleKey]::DownArrow) { return $this.PressDown() }
                ([System.ConsoleKey]::Home) { return $this.PressHome() }
                ([System.ConsoleKey]::End) { return $this.PressEnd() }
                ([System.ConsoleKey]::Backspace) { return $this.PressBackspace() }
                ([System.ConsoleKey]::Delete) { return $this.PressDelete() }
                default {
                    return $KeyInfo
                }
            }
        } else {
            # $press.Character is a real character, not a control character
            if ($this.CursorPosition -eq $this.Text.ToString().Length) {
                $this.Text += $KeyInfo.KeyChar
                $this.CursorPosition++
            } else {
                $sPrefix = if ($this.CursorPosition -eq 0) {
                    ""
                } else {
                    $this.Text[0..$($this.CursorPosition - 1)] -join ""
                }
                $sSuffix = $this.Text[$this.CursorPosition..$($this.Text.Length)] -join ""
                $this.Text = $sPrefix + $KeyInfo.KeyChar + $sSuffix
                $this.CursorPosition++
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "SetCursorPosition" -Value {
        Param(
            [int]$Position
        )
        if ($Position -lt 0) {
            $this.CursorPosition = 0
        } elseif ($Position -gt $this.Text.Length) {
            $this.CursorPosition = $this.Text.Length
        } else {
            $this.CursorPosition = $Position
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextHeight" -Value {
        return $this.Text.Split("`n").Count
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        return $this.Prefix.Length + $this.Header.Length + $this.HeaderSeparator.Length + $this.Text.Length
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Reset" -Value {
        $this.Text = $this.OriginalText
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetValue" -Value {
        if ($this.PasswordChar) {
            return $this.Text | ConvertTo-SecureString -AsPlainText -Force
        } else {
            if ($this.ValueConvertFunction) {
                return . $this.ValueConvertFunction $this.Text
            } else {
                return $this.Text
            }
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $true
    }

    return $hResult
}
