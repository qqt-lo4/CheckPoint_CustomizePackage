function New-CLIDialogObjectsRow {
    <#
    .SYNOPSIS
        Creates a container row for organizing multiple interactive controls in CLI dialogs.

    .DESCRIPTION
        This function creates a row object that groups and manages multiple interactive controls
        (buttons, checkboxes, radio buttons, spaces) in either horizontal or vertical layouts.
        It handles keyboard navigation between controls (arrows, Tab), focus management, keyboard
        shortcuts, radio button mutual exclusion, and provides an optional labeled header. Rows are
        the primary organizational unit for grouping controls in CLI dialogs.

    .PARAMETER Row
        An array of dialog control objects to arrange in this row. This parameter is mandatory
        and can be used at position 0. Supported control types: button, checkbox, radiobutton, space.
        Other control types will throw an error.

    .PARAMETER FocusedItem
        The zero-based index of the initially focused control within the row. Default is 0
        (first interactive item). Spaces are not counted as focusable items.

    .PARAMETER Header
        An optional label text displayed before the row content. Alias: "Text".
        Example: "Options", "Select server", "Configuration".

    .PARAMETER HeaderAlign
        The alignment of the header label. Valid values are "Left" or "Right". Default is "Left".
        Right alignment is useful for form-like layouts.

    .PARAMETER HeaderSeparator
        The separator text between the header and row content. Default is " : ".

    .PARAMETER HeaderForegroundColor
        The foreground color of the header label when the row is not focused. Default is Green.

    .PARAMETER HeaderBackgroundColor
        The background color of the header label when not focused. Default is the current
        console background color.

    .PARAMETER FocusedHeaderForegroundColor
        The foreground color of the header label when the row is focused. Default is Blue.

    .PARAMETER FocusedHeaderBackgroundColor
        The background color of the header label when focused. Default is the current console
        background color.

    .PARAMETER SeparatorLocation
        The column position where the separator should be located. Used for aligning multiple
        rows in a form layout.

    .PARAMETER Prefix
        A prefix string displayed before the header when not focused. Used for indentation
        or visual hierarchy.

    .PARAMETER FocusedPrefix
        A prefix string displayed before the header when focused. Typically used to indicate
        focus (e.g., "> " to show current row).

    .PARAMETER Name
        A unique identifier for the row. If not specified, generates a name based on the header
        (e.g., "rowOptions"). Used for identification.

    .PARAMETER MandatoryRadioButtonValue
        Switch parameter. When specified for a radio button row, ensures at least one radio
        button must remain selected (prevents deselecting the last selected button).

    .PARAMETER InvisibleHeader
        Switch parameter. When specified, reserves space for the header but doesn't display it.
        Useful for alignment when some rows have headers and others don't.

    .PARAMETER Vertical
        Switch parameter. When specified, arranges controls vertically (stacked) instead of
        horizontally (side-by-side). In vertical mode, Up/Down arrows navigate between controls.

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, RowContent, ObjectsIndex, FocusedItem, KeyboardObjects, KeyboardToInt,
                     Header, HeaderAlign, HeaderSeparator, Colors, SeparatorLocation, Prefix,
                     FocusedPrefix, Name, MandatoryRadioButtonValue, InvisibleHeader, Vertical
        - Methods: Draw(), DrawFocused(), PressLeft(), PressRight(), PressUp(), PressDown(),
                   PressTab(), PressKey(), GetTextHeight(), GetTextWidth(), Reset(), GetText(),
                   IsRadioButtonRow(), GetValue(), IsDynamicObject()

    .EXAMPLE
        $btnRow = New-CLIDialogObjectsRow -Row @(
            New-CLIDialogButton -Text "&OK" -Validate
            New-CLIDialogSpace -Length 3
            New-CLIDialogButton -Text "&Cancel" -Cancel
        )
        $btnRow.DrawFocused()

        Creates a horizontal row with OK and Cancel buttons separated by space.

    .EXAMPLE
        $radioRow = New-CLIDialogObjectsRow -Header "Choose option" -Row @(
            New-CLIDialogRadioButton -Text "&Yes" -Enabled $true
            New-CLIDialogRadioButton -Text "&No" -Enabled $false
        ) -MandatoryRadioButtonValue
        $selected = $radioRow.GetValue()  # Returns selected radio button value

        Creates a labeled radio button row with mandatory selection.

    .EXAMPLE
        $checkboxRow = New-CLIDialogObjectsRow -Row @(
            New-CLIDialogCheckBox -Text "Option &1" -Enabled $true
            New-CLIDialogCheckBox -Text "Option &2" -Enabled $false
            New-CLIDialogCheckBox -Text "Option &3" -Enabled $true
        ) -Vertical -Header "Features" -FocusedPrefix "> "

        Creates a vertical checkbox list with header and focus indicator.

    .EXAMPLE
        $alignedRow = New-CLIDialogObjectsRow -Header "Server" -SeparatorLocation 15 -Row @(
            New-CLIDialogButton -Text "Server1"
            New-CLIDialogButton -Text "Server2"
            New-CLIDialogButton -Text "Server3"
        ) -Prefix "  "

        Creates an indented, aligned row with multiple buttons.

    .EXAMPLE
        $invisibleHeaderRow = New-CLIDialogObjectsRow -InvisibleHeader -SeparatorLocation 15 -Row @(
            New-CLIDialogButton -Text "Submit"
            New-CLIDialogButton -Text "Reset"
        )

        Creates a row with invisible header space for alignment with other labeled rows.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: None

        This function is part of the CLI Dialog framework. Rows are container objects that
        manage groups of interactive controls and handle navigation between them.

        SUPPORTED CONTROL TYPES:
        - button: Interactive buttons (New-CLIDialogButton)
        - checkbox: Independent toggle controls (New-CLIDialogCheckBox)
        - radiobutton: Mutually exclusive selection (New-CLIDialogRadioButton)
        - space: Non-interactive spacing (New-CLIDialogSpace)

        KEYBOARD NAVIGATION:
        - Left/Right Arrow: Navigate between controls in horizontal layout
        - Up/Down Arrow: Navigate between controls in vertical layout
        - Tab: Move forward to next control
        - Shift+Tab: Move backward to previous control
        - Character keys: Activate control with matching keyboard shortcut
        - Space/Enter: Activate focused control

        RADIO BUTTON BEHAVIOR:
        - IsRadioButtonRow() returns true if row contains only radio buttons (and spaces)
        - Radio buttons in the same row are mutually exclusive
        - GetValue() returns the selected radio button's object or text
        - MandatoryRadioButtonValue ensures at least one remains selected

        LAYOUT MODES:
        - Horizontal (default): Controls arranged left-to-right, navigate with Left/Right
        - Vertical: Controls arranged top-to-bottom, navigate with Up/Down
        - Header appears once at the beginning
        - Vertical mode auto-indents items to align with first item

        KEYBOARD SHORTCUT HANDLING:
        - Automatically builds KeyboardObjects hashtable mapping keys to controls
        - KeyboardToInt maps keys to control indices
        - Pressing shortcut key directly toggles checkboxes/radio buttons or activates buttons
        - Shortcuts are case-insensitive

        METHODS:
        - Draw([bool]DrawUnderlinedChar): Renders all controls in normal state
        - DrawFocused([bool]DrawUnderlinedChar): Renders with current FocusedItem highlighted
        - PressLeft/Right/Up/Down(): Navigate between controls (returns KeyInfo if at boundary)
        - PressTab([bool]ShiftPressed): Tab navigation (returns KeyInfo if at boundary)
        - PressKey([ConsoleKeyInfo]): Main keyboard handler, dispatches to focused control
        - GetTextHeight(): Returns height (max height in horizontal, sum in vertical)
        - GetTextWidth([bool]Verbose): Returns total width (sum in horizontal, max in vertical)
        - Reset(): Calls Reset() on all controls that support it
        - GetText(): Returns header text without ANSI codes
        - IsRadioButtonRow(): Returns true if row contains only radio buttons
        - GetValue(): Returns selected radio button's value (if radio button row)
        - IsDynamicObject(): Returns true if any control is interactive

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Horizontal and vertical layout modes
            - Keyboard navigation (arrows, Tab)
            - Focus management across multiple controls
            - Radio button mutual exclusion and mandatory selection
            - Keyboard shortcut mapping and dispatch
            - Optional labeled header with alignment
            - Invisible header for alignment purposes
            - Delegated drawing and key handling to child controls
            - GetValue() for radio button row results
    #>
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
        [switch]$InvisibleHeader,
        [switch]$Vertical
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
        Vertical = $Vertical
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
        if ($this.Vertical) {
            $this.RowContent[0].Draw($DrawUnderlinedChar)
            Write-Host ""
            for ($i = 1; $i -lt $this.RowContent.Count; $i++) {
                if ($this.RowContent[$i].Type -ne "space") {
                    Write-Host -NoNewline (" " * ($this.SeparatorLocation + $this.HeaderSeparator.Length))
                    $this.RowContent[$i].Draw($DrawUnderlinedChar)
                    Write-Host ""
                }
            }    
        } else {
            for ($i = 0; $i -lt $this.RowContent.Count; $i++) {
                if ($this.RowContent[$i].Type -eq "space") {
                    $this.RowContent[$i].Draw()
                } else {
                    $this.RowContent[$i].Draw($DrawUnderlinedChar)
                }
            }    
            Write-Host ""
        }
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
        if ($this.Vertical) {
            if ($this.ObjectsIndex.IndexOf(0) -eq $this.FocusedItem) {
                $this.RowContent[0].DrawFocused($DrawUnderlinedChar)
            } else {
                $this.RowContent[0].Draw($DrawUnderlinedChar)
            }
            Write-Host ""
            for ($i = 1; $i -lt $this.RowContent.Count; $i++) {
                if ($this.RowContent[$i].Type -ne "space") {
                    Write-Host -NoNewline (" " * ($this.SeparatorLocation + $this.HeaderSeparator.Length))
                    if ($this.ObjectsIndex.IndexOf($i) -eq $this.FocusedItem) {
                        $this.RowContent[$i].DrawFocused($DrawUnderlinedChar)
                    } else {
                        $this.RowContent[$i].Draw($DrawUnderlinedChar)
                    }
                    Write-Host ""
                }
            }    
        } else {
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

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressUp" -Value {
        if ($this.Vertical) {
            if ($this.FocusedItem -le 0) {
                return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::UpArrow, $false, $false, $false)
            } else {
                $this.FocusedItem--
            }
        } else {
            return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::UpArrow, $false, $false, $false)
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "PressDown" -Value {
        if ($this.Vertical) {
            if ($this.FocusedItem -ge ($this.ObjectsIndex.Count - 1)) {
                return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::DownArrow, $false, $false, $false)
            } else {
                $this.FocusedItem++
            }
        } else {
            return [System.ConsoleKeyInfo]::new(0, [System.ConsoleKey]::DownArrow, $false, $false, $false)
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
                ([System.ConsoleKey]::UpArrow) {
                    return $this.PressUp()
                }
                ([System.ConsoleKey]::RightArrow) {
                    return $this.PressRight()
                }
                ([System.ConsoleKey]::DownArrow) {
                    return $this.PressDown()
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
        if ($this.Vertical) {
            $iResult = 0
            foreach ($item in $this.RowContent) {
                $iResult += $item.GetTextHeight()
            }
            return $iResult
        } else {
            $iMaxHeight = 0
            foreach ($item in $this.RowContent) {
                if (($item.GetTextHeight()) -and ($item.GetTextHeight() -gt $iMaxHeight)) {
                    $iMaxHeight = $item.GetTextHeight()
                }
            }
            return $iMaxHeight
        }
    }

    $hResult | Add-Member -MemberType ScriptMethod -Name "GetTextWidth" -Value {
        Param(
            [bool]$Verbose = $false
        )
        $iResult = 0
        if (($this.Header) -or ($this.InvisibleHeader)) {
            $iResult = $this.HeaderSeparator.Length + $this.SeparatorLocation + $this.Prefix.Length
        }
        if ($this.Vertical) {
            $iMaxLength = 0
            foreach ($item in $this.RowContent) {
                if ($item.GetTextWidth() -gt $iMaxLength) {
                    $iMaxLength = $item.GetTextWidth()
                }
            }
            $iResult += $iMaxLength
        } else {
            foreach ($item in $this.RowContent) {
                $iResult += $item.GetTextWidth()
            }    
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
                if ($oSelectedRadioButton.Object -ne $null) {
                    return $oSelectedRadioButton.Object
                } else {
                    return $oSelectedRadioButton.GetText()
                }
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
