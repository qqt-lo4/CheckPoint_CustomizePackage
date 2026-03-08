function New-CLIDialogButton {
    <#
    .SYNOPSIS
        Creates a button control for CLI dialog interfaces with predefined action types.

    .DESCRIPTION
        This function creates an interactive button object for use in CLI dialogs. Buttons can be
        simple value selections or action buttons with predefined behaviors (Yes, No, Cancel, Validate,
        Exit, etc.). The control supports keyboard shortcuts with automatic detection from "&" notation,
        underlined characters, focus states with color inversion, custom object association, scriptblock
        execution, and flexible spacing options.

    .PARAMETER Text
        The label text displayed on the button. This parameter is mandatory and can be used at position 0.
        Use "&" before a character to auto-underline it and set it as the keyboard shortcut
        (e.g., "&OK" displays as "OK" with underlined O and sets "O" as the shortcut key).

    .PARAMETER Keyboard
        The keyboard shortcut key for this button. This parameter can be used at position 1.
        If not specified and Text contains "&", the character after "&" is used as the shortcut.
        Space and Enter keys also activate the focused button.

    .PARAMETER Yes
        Switch parameter (ParameterSet "Yes"). Creates a button with "Yes" action type, typically
        used for confirmation dialogs. Sets ButtonType to "Action" or "Action_Scriptblock".

    .PARAMETER No
        Switch parameter (ParameterSet "No"). Creates a button with "No" action type, typically
        used for negative confirmation in dialogs.

    .PARAMETER Cancel
        Switch parameter (ParameterSet "Cancel"). Creates a button with "Cancel" action type,
        used to abort or cancel dialog operations.

    .PARAMETER Back
        Switch parameter (ParameterSet "Back"). Creates a button with "Back" action type,
        used for navigation to previous screen or step.

    .PARAMETER Exit
        Switch parameter (ParameterSet "Exit"). Creates a button with "Exit" action type,
        used to close or exit the dialog.

    .PARAMETER Validate
        Switch parameter (ParameterSet "Validate"). Creates a button with "Validate" action type,
        used to confirm and validate dialog input.

    .PARAMETER Previous
        Switch parameter (ParameterSet "Previous"). Creates a button with "Previous" action type,
        used for previous page or item navigation.

    .PARAMETER Next
        Switch parameter (ParameterSet "Next"). Creates a button with "Next" action type,
        used for next page or item navigation.

    .PARAMETER Refresh
        Switch parameter (ParameterSet "Refresh"). Creates a button with "Refresh" action type,
        used to refresh or reload dialog content.

    .PARAMETER Other
        Switch parameter (ParameterSet "Other"). Creates a button with "Other" action type,
        for custom or miscellaneous actions.

    .PARAMETER DoNotSelect
        Switch parameter (ParameterSet "DoNotSelect"). Creates a button with "DoNotSelect" action type,
        used to explicitly indicate no selection.

    .PARAMETER GoTo
        Switch parameter (ParameterSet "GoTo"). Creates a button with "GoTo" action type,
        used for navigation to specific location or page.

    .PARAMETER BackgroundColor
        The background color when the button is not focused. Default is the current console
        background color.

    .PARAMETER ForegroundColor
        The foreground (text) color when the button is not focused. Default is the current
        console foreground color.

    .PARAMETER FocusedBackgroundColor
        The background color when the button is focused. Default is the current console
        foreground color (inverted).

    .PARAMETER FocusedForegroundColor
        The foreground color when the button is focused. Default is the current console
        background color (inverted).

    .PARAMETER Object
        An optional custom object or scriptblock to associate with this button.
        - If scriptblock: Sets ButtonType to "Scriptblock" (None set) or "Action_Scriptblock" (action set)
        - If object: Sets ButtonType to "Value" (None set) or "Action" (action set)

    .PARAMETER ObjectSelectedProperties
        Specifies which properties of the Object to use when the button is selected.
        Useful for filtering or transforming the object data.

    .PARAMETER AddNewLine
        Switch parameter. If specified, adds a newline after the button is drawn. Useful
        for vertical button layouts.

    .PARAMETER Underline
        The zero-based position of the character to underline in the text. Use -1 for no
        underline (default). Ignored if "&" is present in the text.

    .PARAMETER NoSpace
        Switch parameter. If specified, removes the leading and trailing spaces around the
        button text. Format becomes "Text" instead of " Text ".

    .PARAMETER Name
        A unique identifier for the button. Used for identification and retrieval.

    .OUTPUTS
        Returns a hashtable object with the following members:
        - Properties: Type, Text, Keyboard, Colors, Object, ObjectSelectedProperties, AddNewLine,
                     NoSpace, Name, ButtonType, Action
        - Methods: Draw(), DrawFocused(), GetText(), PressKey(), GetTextHeight(), GetTextWidth(),
                   IsDynamicObject()

    .EXAMPLE
        $okBtn = New-CLIDialogButton -Text "&OK" -Validate
        $okBtn.Draw()

        Creates an OK button with Validate action type and "O" as keyboard shortcut.

    .EXAMPLE
        $btnRow = @(
            New-CLIDialogButton -Text "&Yes" -Yes
            New-CLIDialogButton -Text "&No" -No
            New-CLIDialogButton -Text "&Cancel" -Cancel
        )

        Creates a row of three action buttons: Yes, No, and Cancel.

    .EXAMPLE
        $navButtons = @(
            New-CLIDialogButton -Text "<< Previous" -Previous -Keyboard ([ConsoleKey]::LeftArrow)
            New-CLIDialogButton -Text "Next >>" -Next -Keyboard ([ConsoleKey]::RightArrow)
        )

        Creates navigation buttons with custom keyboard shortcuts using arrow keys.

    .EXAMPLE
        $item = [PSCustomObject]@{ Name = "Server1"; IP = "192.168.1.1" }
        $btn = New-CLIDialogButton -Text "Server1" -Object $item -ObjectSelectedProperties @("Name", "IP")

        Creates a button associated with an object and specific properties to return on selection.

    .EXAMPLE
        $scriptBtn = New-CLIDialogButton -Text "Execute" -Object { Write-Host "Running..." } -Validate
        # When pressed, executes the scriptblock

        Creates a button that executes a scriptblock when selected.

    .EXAMPLE
        $compactBtn = New-CLIDialogButton -Text "Compact" -NoSpace -ForegroundColor Green -AddNewLine
        $width = $compactBtn.GetTextWidth()  # Returns exact text width without padding

        Creates a compact green button with newline and gets its width.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: Set-StringUnderline

        This function is part of the CLI Dialog framework. Buttons are the primary interactive
        element for user actions and selections in dialogs.

        BUTTON TYPES:
        - Value: Simple button with associated object (default when no action specified)
        - Scriptblock: Button that executes a scriptblock (when Object is scriptblock)
        - Action: Action button with predefined behavior (when action switch used)
        - Action_Scriptblock: Action button that also executes scriptblock

        PARAMETER SETS (Action Types):
        - None (default): Generic button for value selection
        - Yes, No, Cancel: Common confirmation buttons
        - Validate, Exit: Dialog control buttons
        - Previous, Next, Back: Navigation buttons
        - Refresh, GoTo, Other, DoNotSelect: Additional action types

        KEYBOARD SHORTCUTS:
        - Use "&" in text for automatic shortcut extraction (e.g., "&Save" -> "S" key)
        - Explicit Keyboard parameter overrides "&" shortcut
        - Space bar activates the focused button
        - Enter key activates focused button if Object is present
        - Shortcuts are case-insensitive

        METHODS:
        - Draw([bool]DrawUnderlinedChar): Renders the button in normal state
        - DrawFocused([bool]DrawUnderlinedChar): Renders with focus colors
        - GetText(): Returns text without ANSI formatting codes
        - PressKey([ConsoleKeyInfo]KeyInfo): Handles keyboard input, returns button or KeyInfo
        - GetTextHeight(): Returns number of lines in text
        - GetTextWidth(): Returns width with or without padding (adds 2 characters unless NoSpace)
        - IsDynamicObject(): Returns $true (button is interactive)

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Multiple action types via parameter sets
            - Keyboard shortcut support with "&" notation
            - Focus state with color inversion
            - Scriptblock execution support
            - Object association with property selection
            - Automatic keyboard shortcut extraction from text
            - NoSpace and AddNewLine formatting options
            - Enter and Space key activation
    #>
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
        $sLetter = $sText[$iAmpersand..$iAmpersand][0].ToString().ToUpper()
        $kKeyboard = [System.Enum]::Parse([System.ConsoleKey], $sLetter)
        $sText = $sText | Set-StringUnderline -Position $iAmpersand
    } elseif ($Underline -ge 0) {
        if ($Underline -ge $Text.Length) {
            throw [System.ArgumentOutOfRangeException] "Can't underline a character greater than string length"
        }
        $sText = $sText | Set-StringUnderline -Position $Underline
        $kKeyboard = $Keyboard
    } else {
        $kKeyboard = $Keyboard
    }
    $hResult = @{
        Type = "button"
        Text = $sText
        Keyboard = $kKeyboard
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
