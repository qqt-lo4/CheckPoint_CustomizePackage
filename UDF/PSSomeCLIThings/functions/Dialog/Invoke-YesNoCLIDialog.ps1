function Invoke-YesNoCLIDialog {
    <#
    .SYNOPSIS
        Displays a Yes/No confirmation dialog with optional Cancel button.

    .DESCRIPTION
        This is a convenience function that creates and displays a simple Yes/No/Cancel confirmation
        dialog using the CLI Dialog framework. It provides a quick way to ask the user for confirmation
        with customizable button layouts (horizontal or vertical), button text, keyboard shortcuts,
        colors, and a recommended default option. The function handles all the dialog creation and
        returns the user's choice as a string action ("Yes", "No", or "Cancel").

    .PARAMETER Message
        The question or message to display to the user. This parameter is mandatory.
        Example: "Do you want to continue?", "Delete this file?", "Save changes?"

    .PARAMETER YNC
        Switch parameter (ParameterSet "YNC", default). Creates a dialog with Yes, No, and Cancel buttons.
        This is the most common configuration for operations that can be confirmed, declined, or aborted.

    .PARAMETER NC
        Switch parameter (ParameterSet "NC"). Creates a dialog with only No and Cancel buttons.
        Useful for "decline or abort" scenarios where there's no affirmative action.

    .PARAMETER YN
        Switch parameter (ParameterSet "YN"). Creates a dialog with only Yes and No buttons.
        Useful for simple binary choices where cancellation is not an option.

    .PARAMETER YesButtonText
        The text to display on the Yes button. Default is "&Yes" (with Y as keyboard shortcut).
        Use "&" to specify the underlined character for keyboard shortcut.

    .PARAMETER YesKeyboard
        The keyboard shortcut for the Yes button. Default is Y key.
        Example: [System.ConsoleKey]::Y, [System.ConsoleKey]::O for OK

    .PARAMETER NoButtonText
        The text to display on the No button. Default is "&No" (with N as keyboard shortcut).

    .PARAMETER NoKeyboard
        The keyboard shortcut for the No button. Default is N key.

    .PARAMETER CancelButtonText
        The text to display on the Cancel button. Default is "&Cancel" (with C as keyboard shortcut).
        Only displayed when using YNC or NC parameter sets.

    .PARAMETER CancelKeyboard
        The keyboard shortcut for the Cancel button. Default is C key.
        Cancel button also responds to Escape key automatically.

    .PARAMETER Vertical
        Switch parameter. When specified, arranges buttons vertically (stacked) instead of
        horizontally (side-by-side). Useful for narrow console windows or many buttons.

    .PARAMETER SpaceBefore
        The number of space characters to display before the buttons. Default is 5.
        Used for indentation and visual alignment.

    .PARAMETER Recommended
        Specifies which button should be focused by default. Valid values: "Yes", "No", "Cancel".
        If not specified, the first button receives focus. Useful for guiding user toward safe choice.

    .PARAMETER HeaderForegroundColor
        The foreground color of the message text. Default is Green.

    .PARAMETER HeaderBackgroundColor
        The background color of the message text. Default is the current console background color.

    .PARAMETER ButtonForegroundColor
        The foreground color of buttons when not focused. Default is the current console foreground color.

    .PARAMETER ButtonBackgroundColor
        The background color of buttons when not focused. Default is the current console background color.

    .PARAMETER FocusedButtonForegroundColor
        The foreground color of the focused button. Default is the current console background color (inverted).

    .PARAMETER FocusedButtonBackgroundColor
        The background color of the focused button. Default is the current console foreground color (inverted).

    .OUTPUTS
        Returns a string indicating the user's choice: "Yes", "No", or "Cancel".

    .EXAMPLE
        $choice = Invoke-YesNoCLIDialog -Message "Do you want to continue?"
        if ($choice -eq "Yes") {
            Write-Host "Continuing..."
        }

        Displays a Yes/No/Cancel dialog and acts based on user choice.

    .EXAMPLE
        $choice = Invoke-YesNoCLIDialog -Message "Delete this file?" -YN -Recommended "No"
        if ($choice -eq "Yes") {
            Remove-Item $file
        }

        Displays a Yes/No dialog with No as the recommended (default focused) option.

    .EXAMPLE
        $result = Invoke-YesNoCLIDialog -Message "Save changes before closing?" `
            -YesButtonText "&Save" -NoButtonText "&Discard" -CancelButtonText "&Cancel" `
            -Vertical

        Displays a custom-labeled vertical dialog for save confirmation.

    .EXAMPLE
        $choice = Invoke-YesNoCLIDialog -Message "Proceed with installation?" `
            -YNC -SpaceBefore 10 -HeaderForegroundColor Yellow

        Displays a Yes/No/Cancel dialog with 10-space indentation and yellow message.

    .EXAMPLE
        $choice = Invoke-YesNoCLIDialog -Message "Decline terms of service?" -NC

        Displays a No/Cancel dialog (no Yes option) for declining agreements.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: New-CLIDialogText, New-CLIDialogSpace, New-CLIDialogButton, New-CLIDialogObjectsRow, New-CLIDialog, Invoke-CLIDialog

        This function is a high-level convenience wrapper around New-CLIDialog. It simplifies
        the common pattern of Yes/No/Cancel confirmation dialogs.

        PARAMETER SETS:
        - YNC (default): Displays Yes, No, and Cancel buttons
        - NC: Displays only No and Cancel buttons (no affirmative action)
        - YN: Displays only Yes and No buttons (no cancellation option)

        KEYBOARD SHORTCUTS:
        - Y: Yes button (default, customizable via YesKeyboard)
        - N: No button (default, customizable via NoKeyboard)
        - C: Cancel button (default, customizable via CancelKeyboard)
        - Escape: Always mapped to Cancel button (when present)
        - Enter: Activates the focused button
        - Arrow keys/Tab: Navigate between buttons

        LAYOUT MODES:
        - Horizontal (default): Buttons arranged side-by-side
        - Vertical: Buttons arranged top-to-bottom (use -Vertical switch)

        RECOMMENDED OPTION:
        - Use -Recommended to pre-focus the safest or most common choice
        - Example: -Recommended "No" for potentially destructive operations
        - Example: -Recommended "Yes" for routine confirmations

        CUSTOMIZATION:
        - All button text can be customized for internationalization
        - All colors can be customized to match application theme
        - Keyboard shortcuts can be changed to avoid conflicts

        RETURN VALUE:
        - Always returns a string: "Yes", "No", or "Cancel"
        - String matches the Action property of the selected button
        - Can be used directly in if/switch statements

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Three parameter sets: YNC, NC, YN
            - Horizontal and vertical layouts
            - Customizable button text and keyboard shortcuts
            - Recommended option for default focus
            - Color customization for message and buttons
            - Automatic Escape key mapping to Cancel
            - Returns action string for easy conditional logic
    #>
    [CmdletBinding(DefaultParameterSetName = "YNC")]
    Param(
        [Parameter(Mandatory)]
        [string]$Message,
        [Parameter(ParameterSetName = "YNC")]
        [switch]$YNC,
        [Parameter(ParameterSetName = "NC")]
        [switch]$NC,
        [Parameter(ParameterSetName = "YN")]
        [switch]$YN,
        [string]$YesButtonText = "&Yes",
        [System.ConsoleKey]$YesKeyboard = ([System.ConsoleKey]::Y),
        [string]$NoButtonText = "&No",
        [System.ConsoleKey]$NoKeyboard = ([System.ConsoleKey]::N),
        [string]$CancelButtonText = "&Cancel",
        [System.ConsoleKey]$CancelKeyboard = ([System.ConsoleKey]::C),
        [switch]$Vertical,
        [uint16]$SpaceBefore = 5,
        [AllowEmptyString()]
        [ValidateSet("Yes", "No", "Cancel")]
        [string]$Recommended,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green,
        [System.ConsoleColor]$HeaderBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$ButtonForegroundColor = (Get-Host).UI.RawUI.ForegroundColor,
        [System.ConsoleColor]$ButtonBackgroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedButtonForegroundColor = (Get-Host).UI.RawUI.BackgroundColor,
        [System.ConsoleColor]$FocusedButtonBackgroundColor = (Get-Host).UI.RawUI.ForegroundColor
    )
    $aCliDialogRows = @(New-CLIDialogText -Text $Message -ForegroundColor $HeaderForegroundColor -BackgroundColor $HeaderBackgroundColor -AddNewLine)
    if ($Vertical) {
        if ($PSCmdlet.ParameterSetName.Contains("Y")) {
            $aCliDialogRows += if ($SpaceBefore -gt 0) {
                New-CLIDialogObjectsRow -Row @(
                    New-CLIDialogSpace -Length $SpaceBefore
                    New-CLIDialogButton -Text $YesButtonText -Keyboard $YesKeyboard -Yes
                )
            } else {
                New-CLIDialogObjectsRow -Row @(New-CLIDialogButton -Text $YesButtonText -Keyboard $YesKeyboard -Yes)
            }    
        }
        $aCliDialogRows += if ($SpaceBefore -gt 0) {
            New-CLIDialogObjectsRow -Row @(
                New-CLIDialogSpace -Length $SpaceBefore
                New-CLIDialogButton -Text $NoButtonText -Keyboard $NoKeyboard -No
            )
        } else {
            New-CLIDialogObjectsRow -Row @(New-CLIDialogButton -Text $NoButtonText -Keyboard $NoKeyboard -No)
        }
        if ($PSCmdlet.ParameterSetName.Contains("C")) {
            $aCliDialogRows += if ($SpaceBefore -gt 0) {
                New-CLIDialogObjectsRow -Row @(
                    New-CLIDialogSpace -Length $SpaceBefore
                    New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel
                )
            } else {
                New-CLIDialogObjectsRow -Row @(New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel)
            }
        }
    } else {
        $oRow = @()
        if ($SpaceBefore -gt 0) {
            $oRow += New-CLIDialogSpace -Length $SpaceBefore
        }
        if ($PSCmdlet.ParameterSetName.Contains("Y")) {
            $oRow += New-CLIDialogButton -Text $YesButtonText -Keyboard $YesKeyboard -Yes
        }
        $oRow += New-CLIDialogButton -Text $NoButtonText -Keyboard $NoKeyboard -No
        if ($PSCmdlet.ParameterSetName.Contains("C")) {
            $oRow += New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel
        }
        $aCliDialogRows += New-CLIDialogObjectsRow -Row $oRow
    }
    $hDialogArgs = @{
        Rows = $aCliDialogRows
    }
    if ($PSCmdlet.ParameterSetName.Contains("C")) {
        $hDialogArgs.EscapeObject = New-CLIDialogButton -Text $CancelButtonText -Keyboard $CancelKeyboard -Cancel
    }
    $oDialog = New-CLIDialog -Rows $aCliDialogRows
    if ($Recommended) {
        $iRowToFocus = ($oDialog.DynamicRows | Where-Object { $_.RowContent[1].Action -eq $Recommended }).DynamicRowId
        $oDialog.FocusedRow = $iRowToFocus
    }
    $oDialogResult = Invoke-CLIDialog $oDialog
    return $oDialogResult.Action
}
