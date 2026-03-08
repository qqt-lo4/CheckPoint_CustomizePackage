function New-CLIDialogCheckBox {
    <#
    .SYNOPSIS
        Creates a checkbox control for CLI dialog interfaces.

    .DESCRIPTION
        This function creates an interactive checkbox object for use in CLI dialogs.
        Checkboxes allow multiple independent selections - each can be toggled on or off
        without affecting others. The control supports keyboard shortcuts, underlined characters,
        focus states with color inversion, custom object association for data binding, and
        flexible spacing options.

    .PARAMETER Text
        The label text displayed next to the checkbox. This parameter is mandatory and can be
        used at position 0. Use "&" before a character to auto-underline it and set it as the
        keyboard shortcut (e.g., "&Enable" displays as "Enable" with underlined E).

    .PARAMETER Enabled
        Boolean value indicating if the checkbox is initially checked ($true) or unchecked ($false).
        This parameter can be used at position 1.

    .PARAMETER Keyboard
        The keyboard shortcut key for this checkbox. If not specified and Text contains "&",
        the character after "&" is used as the shortcut. Press Space to toggle the focused checkbox.

    .PARAMETER BackgroundColor
        The background color when the checkbox is not focused. Default is the current console
        background color.

    .PARAMETER ForegroundColor
        The foreground (text) color when the checkbox is not focused. Default is the current
        console foreground color.

    .PARAMETER FocusedBackgroundColor
        The background color when the checkbox is focused. Default is the current console
        foreground color (inverted).

    .PARAMETER FocusedForegroundColor
        The foreground color when the checkbox is focused. Default is the current console
        background color (inverted).

    .PARAMETER Name
        A unique identifier for the checkbox. If not specified, generates a name based on
        the text (e.g., "checkboxEnable"). Used for identification and retrieval.

    .PARAMETER Object
        An optional custom object to associate with this checkbox. Useful for data binding
        and retrieving associated data when the checkbox is checked. When an object is present,
        toggling the checkbox triggers dialog array updates.

    .PARAMETER AddNewLine
        Switch parameter. If specified, adds a newline after the checkbox is drawn. Useful
        for vertical layouts.

    .PARAMETER Underline
        The zero-based position of the character to underline in the text. Use -1 for no
        underline (default). Ignored if "&" is present in the text.

    .PARAMETER NoSpace
        Switch parameter. If specified, removes the leading and trailing spaces around the
        checkbox. Format becomes "[x] Text" instead of " [x] Text ".

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, Text, Enabled, OriginalEnabled, Keyboard, Colors, Name, Object, AddNewLine, NoSpace
        - Methods: Draw(), DrawFocused(), GetText(), ToggleValue(), PressKey(), GetTextHeight(),
                   GetTextWidth(), Reset(), GetValue(), IsDynamicObject()

    .EXAMPLE
        $chk = New-CLIDialogCheckBox -Text "&Enable logging" -Enabled $true
        $chk.Draw()

        Creates a checked checkbox with "Enable logging" text and "E" as keyboard shortcut.

    .EXAMPLE
        $options = @(
            New-CLIDialogCheckBox -Text "Option 1" -Enabled $true
            New-CLIDialogCheckBox -Text "Option 2" -Enabled $false
            New-CLIDialogCheckBox -Text "Option 3" -Enabled $true
        )

        Creates three independent checkboxes with Options 1 and 3 checked.

    .EXAMPLE
        $chk = New-CLIDialogCheckBox -Text "Accept terms" -Enabled $false `
            -ForegroundColor Yellow -FocusedBackgroundColor Red -AddNewLine
        $chk.ToggleValue()  # Checks the checkbox

        Creates a checkbox with custom colors and newline, then toggles its value.

    .EXAMPLE
        $file = [PSCustomObject]@{ Name = "document.txt"; Size = 1024 }
        $chk = New-CLIDialogCheckBox -Text "document.txt" -Object $file
        # Later retrieve: if ($chk.Enabled) { $selectedFile = $chk.Object }

        Creates a checkbox associated with a file object for selection tracking.

    .EXAMPLE
        $chk = New-CLIDialogCheckBox -Text "Compact" -NoSpace -Underline 0
        $width = $chk.GetTextWidth()  # Returns text width + 4 for "[x] "

        Creates a compact checkbox with manual underline positioning.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: Set-StringUnderline

        This function is part of the CLI Dialog framework. Unlike radio buttons, checkboxes
        are independent and multiple checkboxes can be selected simultaneously.

        CHECKBOX BEHAVIOR:
        - Each checkbox can be toggled independently
        - Multiple checkboxes can be checked at the same time
        - Display format: " [x] Text " when checked, " [ ] Text " when unchecked
        - With NoSpace: "[x] Text" or "[ ] Text"

        KEYBOARD SHORTCUTS:
        - Use "&" in text for automatic shortcut (e.g., "&Save" -> "S" key)
        - Explicit Keyboard parameter sets custom shortcut key
        - Space bar always toggles the focused checkbox
        - Shortcuts are case-insensitive

        OBJECT ASSOCIATION:
        - When Object is set, toggling the checkbox returns the key press to the dialog
        - This triggers the dialog to update its internal array with the associated object
        - Useful for building arrays of selected items

        METHODS:
        - Draw([bool]DrawUnderlinedChar): Renders the checkbox in normal state
        - DrawFocused([bool]DrawUnderlinedChar): Renders with focus colors
        - GetText(): Returns text without ANSI underline codes
        - ToggleValue(): Toggles between checked and unchecked state
        - PressKey([ConsoleKeyInfo]KeyInfo): Handles keyboard input
        - GetTextHeight(): Returns number of lines in text
        - GetTextWidth(): Returns width including "[x] " prefix (adds 4-6 characters)
        - Reset(): Restores to OriginalEnabled state
        - GetValue(): Returns current Enabled state
        - IsDynamicObject(): Returns $true (checkbox is interactive)

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Independent multi-selection checkbox functionality
            - Keyboard shortcut support with "&" notation
            - Focus state with color inversion
            - Custom object association with dialog integration
            - Optional newline support for vertical layouts
            - NoSpace option for compact display
            - Reset functionality to original state
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
        [object]$Object,
        [switch]$AddNewLine,
        [int]$Underline = -1,
        [switch]$NoSpace
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
        Type = "checkbox"
        Text = $sText
        Enabled = $Enabled
        OriginalEnabled = $Enabled
        Keyboard = $Keyboard
        BackgroundColor = $BackgroundColor
        ForegroundColor = $ForegroundColor
        FocusedBackgroundColor = $FocusedBackgroundColor
        FocusedForegroundColor = $FocusedForegroundColor
        Name = if ($Name) { $Name } else { "checkbox" + $Text.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "").Replace(" ", "") }
        Object = $Object
        NoSpace = $NoSpace
        AddNewLine = $AddNewLine
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "Draw" -Value {
        Param(
            [bool]$DrawUnderlinedChar = $true
        )
        $sEnabled = if ($this.Enabled) { "x" } else { " " }
        $sButtonText = if ($DrawUnderlinedChar) { $this.Text } else { $this.GetText() }
        $sText = if ($this.NoSpace) {
            "[$sEnabled] $sButtonText"
        } else {
            " [$sEnabled] $sButtonText "
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
        $sEnabled = if ($this.Enabled) { "x" } else { " " }
        $sButtonText = if ($DrawUnderlinedChar) { $this.Text } else { $this.GetText() }
        $sText = if ($this.NoSpace) {
            "[$sEnabled] $sButtonText"
        } else {
            " [$sEnabled] $sButtonText "
        }
        Write-Host $sText -ForegroundColor $this.FocusedForegroundColor -BackgroundColor $this.FocusedBackgroundColor -NoNewline
        if ($this.AddNewLine) {
            Write-Host "" 
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetText" -Value {
        return $this.Text.Replace("$([char]27)[4m", "").Replace("$([char]27)[24m", "")
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "ToggleValue" -Value {
        $this.Enabled = -not $this.Enabled
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressKey" -Value {
        Param(
            [System.ConsoleKeyInfo]$KeyInfo
        )
        if (-not [System.Char]::IsControl($KeyInfo.KeyChar)) {
            if (($this.Keyboard -ne $null) -and ($KeyInfo.KeyChar.ToString().ToLower() -eq $this.Keyboard)) {
                $this.ToggleValue()
                # if the checkbox contains an object, return the pressed key so the 
                #dialog object will update the array with this object
                if ($this.Object) {
                    return $KeyInfo
                }
            } else {
                if ($KeyInfo.KeyChar.ToString().ToLower() -eq " ") {
                    $this.ToggleValue()
                    # if the checkbox contains an object, return the pressed key so the 
                    #dialog object will update the array with this object
                    if ($this.Object) {
                        return $KeyInfo
                    }
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
        $iResult += 4 # size of the checkbox and space
        if ($this.NoSpace) {
            return $iResult
        } else {
            return $iResult + 2
        }
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
