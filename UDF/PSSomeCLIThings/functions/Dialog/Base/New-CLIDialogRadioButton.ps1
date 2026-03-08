function New-CLIDialogRadioButton {
    <#
    .SYNOPSIS
        Creates a radio button control for CLI dialog interfaces.

    .DESCRIPTION
        This function creates an interactive radio button object for use in CLI dialogs.
        Radio buttons allow single selection within a group - when one is selected, others
        in the same row are automatically deselected. The control supports keyboard shortcuts,
        underlined characters, focus states with color inversion, and can be associated with
        custom objects for data binding.

    .PARAMETER Text
        The label text displayed next to the radio button. This parameter is mandatory and
        can be used at position 0. Use "&" before a character to auto-underline it and set
        it as the keyboard shortcut (e.g., "&Yes" displays as "Yes" with underlined Y).

    .PARAMETER Enabled
        Boolean value indicating if the radio button is initially selected ($true) or not ($false).
        This parameter can be used at position 1.

    .PARAMETER Keyboard
        The keyboard shortcut key for this radio button. If not specified and Text contains "&",
        the character after "&" is used as the shortcut. Press Space to toggle the focused button.

    .PARAMETER BackgroundColor
        The background color when the radio button is not focused. Default is the current
        console background color.

    .PARAMETER ForegroundColor
        The foreground (text) color when the radio button is not focused. Default is the
        current console foreground color.

    .PARAMETER FocusedBackgroundColor
        The background color when the radio button is focused. Default is the current console
        foreground color (inverted).

    .PARAMETER FocusedForegroundColor
        The foreground color when the radio button is focused. Default is the current console
        background color (inverted).

    .PARAMETER Name
        A unique identifier for the radio button. If not specified, generates a name based on
        the text (e.g., "radiobuttonYes"). Used for grouping and identification.

    .PARAMETER Underline
        The zero-based position of the character to underline in the text. Use -1 for no
        underline (default). Ignored if "&" is present in the text.

    .PARAMETER Object
        An optional custom object to associate with this radio button. Useful for data binding
        and retrieving the associated data when the button is selected.

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, Text, Enabled, OriginalEnabled, Keyboard, Colors, Name, Object, Row
        - Methods: Draw(), DrawFocused(), GetText(), ToggleValue(), PressKey(), GetTextHeight(),
                   GetTextWidth(), Reset(), GetValue(), IsDynamicObject()

    .EXAMPLE
        $radio1 = New-CLIDialogRadioButton -Text "&Yes" -Enabled $true
        $radio2 = New-CLIDialogRadioButton -Text "&No" -Enabled $false
        $radio1.Draw()

        Creates two radio buttons with "Yes" initially selected and "Y"/"N" as shortcuts.

    .EXAMPLE
        $options = @(
            New-CLIDialogRadioButton -Text "Option 1" -Enabled $true
            New-CLIDialogRadioButton -Text "Option 2" -Enabled $false
            New-CLIDialogRadioButton -Text "Option 3" -Enabled $false
        )

        Creates a group of three radio buttons with the first one selected.

    .EXAMPLE
        $radio = New-CLIDialogRadioButton -Text "Enable feature" -Enabled $false `
            -ForegroundColor Green -FocusedBackgroundColor Blue
        $radio.ToggleValue()  # Selects the radio button

        Creates a radio button with custom colors and toggles its value.

    .EXAMPLE
        $server1 = [PSCustomObject]@{ Name = "Server1"; IP = "192.168.1.1" }
        $radio = New-CLIDialogRadioButton -Text "Server1" -Object $server1
        # Later retrieve: $radio.Object

        Creates a radio button associated with a server object.

    .EXAMPLE
        $radio = New-CLIDialogRadioButton -Text "Primary" -Underline 0 -Keyboard ([ConsoleKey]::P)
        $width = $radio.GetTextWidth()  # Returns text width + 6 for " (x) "

        Creates a radio button with manual underline and keyboard shortcut.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: Set-StringUnderline

        This function is part of the CLI Dialog framework. Radio buttons are typically grouped
        in rows using New-CLIDialogObjectsRow, which automatically handles mutual exclusion.

        RADIO BUTTON BEHAVIOR:
        - Only one radio button per row can be selected at a time
        - Selecting a radio button automatically deselects others in the same row
        - If Row.MandatoryRadioButtonValue is true, at least one must remain selected
        - Display format: " (x) Text " when enabled, " ( ) Text " when disabled

        KEYBOARD SHORTCUTS:
        - Use "&" in text for automatic shortcut (e.g., "&Save" -> "S" key)
        - Explicit Keyboard parameter overrides "&" shortcut
        - Space bar always toggles the focused radio button
        - Shortcuts are case-insensitive

        METHODS:
        - Draw([bool]DrawUnderlinedChar): Renders the radio button in normal state
        - DrawFocused([bool]DrawUnderlinedChar): Renders with focus colors
        - GetText(): Returns text without ANSI underline codes
        - ToggleValue(): Toggles this button and deselects others in the row
        - PressKey([ConsoleKeyInfo]KeyInfo): Handles keyboard input
        - GetTextHeight(): Returns number of lines in text
        - GetTextWidth(): Returns width including " (x) " prefix (adds 6 characters)
        - Reset(): Restores to OriginalEnabled state
        - GetValue(): Returns current Enabled state
        - IsDynamicObject(): Returns $true (radio button is interactive)

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Single-selection radio button functionality
            - Automatic mutual exclusion within row
            - Keyboard shortcut support with "&" notation
            - Focus state with color inversion
            - Custom object association
            - Mandatory selection support
            - Reset functionality
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Text,
        [Parameter(Position = 1)]
        [bool]$Enabled,
        [System.ConsoleKey]$Keyboard,
        [System.ConsoleColor]$BackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedBackgroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$FocusedForegroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [string]$Name,
        [int]$Underline = -1,
        [object]$Object
    )
    $sText = $Text
    $oKeyboard = if ($Keyboard) { $Keyboard } else { $null }
    
    if ($sText.Contains("&")) {
        $iAmpersand = $sText.IndexOf("&")
        if ($oKeyboard -eq $null) {
            $oKeyboard = $sText[$iAmpersand + 1]
        }
        $sText = $sText.Remove($iAmpersand, 1)
        $sText = $sText | Set-StringUnderline -Position $iAmpersand
    } elseif ($Underline -ge 0) {
        if ($Underline -ge $Text.Length) {
            throw [System.ArgumentOutOfRangeException] "Can't underline a character greater than string length"
        }
        $sText = $sText | Set-StringUnderline -Position $Underline
    }

    $hResult = @{
        Type = "radiobutton"
        Text = $sText
        Enabled = $Enabled
        OriginalEnabled = $Enabled
        Keyboard = $oKeyboard
        BackgroundColor = $BackgroundColor
        ForegroundColor = $ForegroundColor
        FocusedBackgroundColor = $FocusedBackgroundColor
        FocusedForegroundColor = $FocusedForegroundColor
        Name = if ($Name) { $Name } else { "radiobutton" + $Text.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "").Replace(" ", "") }
        Object = $Object
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        Param(
            [bool]$DrawUnderlinedChar = $true
        )
        $sEnabled = if ($this.Enabled) { "x" } else { " " }
        $sButtonText = if ($DrawUnderlinedChar) { $this.Text } else { $this.GetText() }
        Write-Host " ($sEnabled) $sButtonText " -ForegroundColor $this.ForegroundColor -BackgroundColor $this.BackgroundColor -NoNewline
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "DrawFocused" -Value {
        Param(
            [bool]$DrawUnderlinedChar = $true
        )
        $sEnabled = if ($this.Enabled) { "x" } else { " " }
        $sButtonText = if ($DrawUnderlinedChar) { $this.Text } else { $this.GetText() }
        Write-Host " ($sEnabled) $sButtonText " -ForegroundColor $this.FocusedForegroundColor -BackgroundColor $this.FocusedBackgroundColor -NoNewline
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetText" -Value {
        return $this.Text.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "")
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "ToggleValue" -Value {
        if ($this.Enabled) {
            if (-not ($this.Enabled -and $this.Row.MandatoryRadioButtonValue)) {
                $this.Enabled = $false
            }
        } else {
            if ($this.Row) {
                $this.Row.RowContent | Where-Object { $_.Type -eq "radiobutton" } | ForEach-Object { $_.Enabled = $false }
            }
            $this.Enabled = $true
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressKey" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        if (-not [System.Char]::IsControl($KeyInfo.KeyChar)) {
            if (($this.Keyboard -ne $null) -and ($KeyInfo.KeyChar.ToString().ToLower() -eq $this.Keyboard)) {
                $this.ToggleValue()
            } else {
                if ($KeyInfo.KeyChar.ToString().ToLower() -eq " ") {
                    $this.ToggleValue()
                } else {
                    return $KeyInfo
                }
            }
        } else {
            return $KeyInfo
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
        return $iResult + 6
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Reset" -Value {
        $this.Enabled = $this.OriginalEnabled
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetValue" -Value {
        return $this.Enabled
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "IsDynamicObject" -Value {
        return $true
    }

    return $hResult
}
