function Invoke-CLIDialog {
    <#
    .SYNOPSIS
        Invokes a CLI dialog and handles the interaction loop, validation, and result processing.

    .DESCRIPTION
        This function is the primary entry point for displaying and interacting with CLI dialogs.
        It handles the rendering loop, keyboard input processing, validation with error display,
        and result processing. Supports both single invocation and execution modes with automatic
        looping for Value-type results. Can accept either a dialog object or an array of rows,
        automatically creating the dialog if needed. Provides comprehensive control over validation
        behavior, error messaging, and post-selection actions.

    .PARAMETER InputObject
        The dialog object to invoke, or an array of row objects to create a dialog from. This
        parameter is mandatory and accepts pipeline input. If an array is provided, New-CLIDialog
        is called automatically to create the dialog.

    .PARAMETER KeepValues
        Switch parameter. When specified, preserves current form values between invocations.
        If not specified (default), calls Reset() to restore all controls to original values
        before displaying the dialog.

    .PARAMETER Validate
        Switch parameter. When specified, enables validation mode where the dialog loops until
        all textbox validations pass or the user cancels/exits. Displays validation errors
        between iterations.

    .PARAMETER ErrorDetails
        Switch parameter. When specified with -Validate, displays detailed validation errors
        showing each invalid field name and its validation requirement. If not specified, only
        displays a summary error message.

    .PARAMETER PauseAfterErrorMessage
        Switch parameter. When specified with -Validate, pauses after displaying validation
        errors (using Invoke-Pause) to allow user to read the messages before redisplaying the
        dialog.

    .PARAMETER CustomErrorMessage
        Custom error message to display when validation fails. If specified, overrides the
        default error messages (ErrorMessageOneField and ErrorMessageFields).

    .PARAMETER ErrorMessageOneField
        The error message to display when a single field fails validation. Default is
        "Error: The following field has an invalid value.". Only used if CustomErrorMessage
        is not specified.

    .PARAMETER ErrorMessageFields
        The error message to display when multiple fields fail validation. Default is
        "Error: Somes fields have invalid values.". Only used if CustomErrorMessage is not
        specified.

    .PARAMETER ErrorsPropertiesAlign
        The alignment of field names in detailed error messages. Valid values: "Right" (default)
        or "Left". Only used when ErrorDetails is specified.

    .PARAMETER Execute
        Switch parameter. When specified, enables execution mode where the function automatically
        loops for Value-type results, allowing FunctionToRunOnValue to process selections and
        return new dialogs. Handles Back, Refresh, and Exit actions automatically. Essential for
        multi-level menu systems and wizards.

    .PARAMETER FunctionToRunOnValue
        A function to call when a Value-type result is returned in Execute mode. The function
        receives the selected value and should return a DialogResult object. Used for nested
        menus, drill-down interfaces, and multi-step wizards. Only applicable with -Execute.

    .PARAMETER DontSpaceAfterDialog
        Switch parameter. When specified, suppresses the blank line normally printed after the
        dialog closes. Useful for compact layouts or when chaining multiple dialogs.

    .OUTPUTS
        Returns a DialogResult object with the following structure:
        - PSTypeName: "DialogResult.Action.*", "DialogResult.Scriptblock", or "DialogResult.Value"
        - Properties: Button, Form, Type, ValidForm, Action (for actions), Value (for values/scriptblocks)
        - The specific PSTypeName indicates the result type and action (e.g., "DialogResult.Action.Cancel")

    .EXAMPLE
        $rows = @(
            New-CLIDialogTextBox -Header "Name"
            New-CLIDialogObjectsRow -Row @(
                New-CLIDialogButton -Text "OK" -Validate
            )
        )
        $result = Invoke-CLIDialog -InputObject $rows
        $name = $result.Form.GetValue()["Name"]

        Creates and invokes a simple dialog from rows, retrieves the entered name.

    .EXAMPLE
        $dialog = New-CLIDialog -Rows @(
            New-CLIDialogTextBox -Header "Email" -Regex "^\w+@\w+\.\w+$"
            New-CLIDialogObjectsRow -Row @(
                New-CLIDialogButton -Text "Submit" -Validate
            )
        )
        $result = $dialog | Invoke-CLIDialog -Validate -ErrorDetails
        # Loops until email is valid or user cancels

        Invokes dialog with validation loop and detailed error messages.

    .EXAMPLE
        $dialog = New-CLIDialog -Rows @(
            New-CLIDialogTextBox -Header "Username"
            New-CLIDialogTextBox -Header "Password" -PasswordChar '*'
        )
        $result = Invoke-CLIDialog -InputObject $dialog -KeepValues
        # Preserves previous values if dialog was already displayed

        Invokes dialog while keeping existing form values.

    .EXAMPLE
        $mainMenu = New-CLIDialog -Rows @(
            New-CLIDialogText -Text "Main Menu"
            New-CLIDialogButton -Text "Settings" -Object { Show-SettingsDialog } -AddNewLine
            New-CLIDialogButton -Text "Exit" -Exit -AddNewLine
        )

        function Show-SettingsDialog {
            param($value)
            # Show settings dialog, return DialogResult
        }

        $result = Invoke-CLIDialog -InputObject $mainMenu -Execute -FunctionToRunOnValue ${function:Show-SettingsDialog}
        # Automatically loops and handles nested dialogs

        Uses Execute mode with FunctionToRunOnValue for multi-level menu system.

    .EXAMPLE
        $result = @(
            New-CLIDialogTextBox -Header "Field1" -ValidationScript { param($t) $t.Length -ge 3 }
            New-CLIDialogObjectsRow -Row @(New-CLIDialogButton -Text "OK" -Validate)
        ) | Invoke-CLIDialog -Validate -PauseAfterErrorMessage -CustomErrorMessage "Please fix validation errors"

        Pipeline invocation with validation, pause after errors, and custom error message.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: New-CLIDialog, New-DialogResultAction, New-DialogResultScriptblock, New-DialogResultValue, Invoke-Pause

        This function is a high-level wrapper that simplifies dialog invocation and handles common
        patterns like validation loops, error display, and nested dialog execution.

        INVOCATION MODES:
        - Simple: Displays dialog once, returns result (default)
        - Validate: Loops until form is valid or user cancels (-Validate switch)
        - Execute: Loops for Value results, calls FunctionToRunOnValue (-Execute switch)

        INPUT OBJECT TYPES:
        - Dialog Object: Direct invocation of pre-created dialog
        - Row Array: Automatically creates dialog via New-CLIDialog
        - Pipeline Support: Accepts input via pipeline

        VALIDATION BEHAVIOR:
        - With -Validate: Loops until IsValidForm() returns true or user cancels/exits
        - Error messages displayed between iterations
        - -ErrorDetails shows field-by-field validation errors
        - -PauseAfterErrorMessage allows user to read errors before retry

        EXECUTION MODE:
        - Enabled with -Execute switch
        - Automatically loops for DialogResult.Value results
        - Calls FunctionToRunOnValue for each Value result
        - FunctionToRunOnValue can return new dialogs for drill-down interfaces
        - Automatically handles Back, Refresh, Exit actions
        - Essential for menu systems and wizards

        RESULT TYPES:
        - DialogResult.Action.*: User selected action button (Yes, No, Cancel, Validate, etc.)
        - DialogResult.Scriptblock: User selected button with scriptblock
        - DialogResult.Value: User selected button with associated value/object

        INTERNAL FUNCTIONS:
        - Show(): Handles rendering loop and keyboard input
        - Write-ErrorMessage(): Displays validation errors
        - Invoke(): Simple or validated invocation
        - Execute(): Execution mode with automatic looping

        FORM VALUE PRESERVATION:
        - Default: Calls Reset() before display (restores original values)
        - With -KeepValues: Preserves current form state
        - Useful for "edit and retry" scenarios

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Simple, Validate, and Execute invocation modes
            - Automatic dialog creation from row arrays
            - Pipeline support
            - Validation loop with error display
            - Detailed error messages with alignment
            - Pause after error option
            - Custom error messages
            - Keep values between invocations
            - FunctionToRunOnValue for nested dialogs
            - Automatic handling of Back/Refresh/Exit actions
            - Scriptblock execution support
            - Cursor visibility management
            - Optional spacing after dialog
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,
        [switch]$KeepValues,
        [switch]$Validate,
        [switch]$ErrorDetails,
        [switch]$PauseAfterErrorMessage,
        [string]$CustomErrorMessage = "",
        [string]$ErrorMessageOneField = "Error: The following field has an invalid value.",
        [string]$ErrorMessageFields = "Error: Somes fields have invalid values.",
        [ValidateSet("Right", "Left")]
        [string]$ErrorsPropertiesAlign = "Right",
        [switch]$Execute,
        [System.Management.Automation.FunctionInfo]$FunctionToRunOnValue,
        [switch]$DontSpaceAfterDialog
    )
    Begin {
        function Show {
            Param(
                [Parameter(Mandatory)]
                [object]$Dialog,
                [switch]$DontSpaceAfterDialog
            )
            $iFormHeight = $Dialog.GetTextHeight($true)
            $Dialog.SetSeparatorLocation()
            $oResult = $null
            $Dialog.DrawStatic()
            try {
                [console]::CursorVisible=$false #prevents cursor flickering
                $Dialog.DrawDynamic()
                While ($oResult -eq $null) {
                    $Key = [Console]::ReadKey($true)
                    $oResult = $Dialog.PressKey($Key)
                    
                    $startPos = [System.Console]::CursorTop - $iFormHeight
                    [System.Console]::SetCursorPosition(0, $startPos)
                    $Dialog.DrawDynamic()
                }
            } finally {
                [System.Console]::SetCursorPosition(0, $startPos + $iFormHeight) | Out-Null
                [System.Console]::CursorVisible = $true
            }
            if (-not $DontSpaceAfterDialog) {
                Write-Host ""
            }
            if ($oResult -ne $null) {
                $hResult = @{
                    Button = $oResult
                    Form = $Dialog
                    Type = $oResult.ButtonType
                    ValidForm = $Dialog.IsValidForm()
                }
                switch ($hResult.Type) {
                    { $_ -in @("Action", "Action_Scriptblock") } {
                        return New-DialogResultAction -Action $oResult.Action -DialogResult $hResult -Value $oResult.Object 
                    }
                    "Scriptblock" {
                        return New-DialogResultScriptblock -DialogResult $hResult -Value $oResult.Object
                    }
                    "Value" {
                        if ($oResult.Object) {
                            return New-DialogResultValue -DialogResult $hResult -Value $oResult.Object -SelectedProperties $oResult.ObjectSelectedProperties
                        } else {
                            return New-DialogResultValue -DialogResult $hResult -Value $hResult.Button -SelectedProperties $oResult.ObjectSelectedProperties
                        }
                    }
                }
            }
        }

        function Write-ErrorMessage {
            Param(
                [Parameter(Mandatory, ValueFromPipeline)]
                [object]$Dialog,
                [string]$PropertyAlign = "Right",
                [AllowEmptyString()]
                [string]$CustomErrorMessage,
                [string]$ErrorMessageOneField = "Error: The following field has an invalid value.",
                [string]$ErrorMessageFields = "Error: Somes fields have invalid values.",
                [switch]$Details
            )
            if ($Dialog.IsValidForm()) {
                $Dialog.RemoveKey("Errors")
            } else {
                $hErrors = [ordered]@{}
                $iMaxLength = 0
                foreach ($item in $Dialog.Rows) {
                    if (($item.Type -eq "textbox") -and (-not $item.IsValidText())) {
                        if ($item.Header.Length -gt $iMaxLength) { $iMaxLength = $item.Header.Length }
                        $sFieldName = if ($item.FieldNameInErrorReason) {
                            $item.FieldNameInErrorReason
                        } else {
                            $item.Header
                        }
                        $sReason = if ($item.ValidationErrorReason) {
                            $item.ValidationErrorReason
                        } else {
                            "must match the following regex $($item.Regex)"
                        }
                        $hErrors.Add($sFieldName, $sReason)
                    }
                }
                if ($CustomErrorMessage) {
                    Write-Host $CustomErrorMessage -ForegroundColor Red
                } else {
                    if ($hErrors.Keys.Count -gt 1) {
                        Write-Host $ErrorMessageFields -ForegroundColor Red
                    } else {
                        Write-Host $ErrorMessageOneField -ForegroundColor Red
                    }    
                }
                if ($Details) {
                    foreach ($item in $hErrors.Keys) {
                        $iAlign = if ($PropertyAlign -eq "Left") { -1 } else { 1 }
                        Write-Host ("{0,$($iMaxLength * $iAlign)} " -f $item) -ForegroundColor Red -NoNewline
                        Write-Host $hErrors[$item]
                    }    
                }
                $Dialog.Errors = $hErrors
            }
        }
        function Invoke {
            Param(
                [Parameter(Mandatory)]
                [object]$Dialog,
                [switch]$Validate,
                [switch]$DontSpaceAfterDialog
            )
            if ($Validate) {
                $oResult = Show -Dialog $Dialog -DontSpaceAfterDialog:$DontSpaceAfterDialog
                while ((-not $Dialog.IsValidForm()) -and ($oResult.Action -ne "Cancel") -and ($oResult.Action -ne "Exit")) {
                    Write-ErrorMessage -Dialog $Dialog -Details:$ErrorDetails -CustomErrorMessage $CustomErrorMessage
                    if ($PauseAfterErrorMessage) {
                        Invoke-Pause -ReplaceByLine -LineColor Red -MessageColor White
                    }
                    $oResult = Show -Dialog $Dialog
                }
                return $oResult
            } else {
                return Show -Dialog $Dialog
            }
        }

        function Execute {
            Param(
                [Parameter(Mandatory, Position = 0)]
                [object]$Dialog,
                [switch]$Validate,
                [switch]$DontSpaceAfterDialog
            )
            
            while ($true) {
                $oDialogResult = Invoke -Dialog $Dialog -Validate:$Validate -DontSpaceAfterDialog:$DontSpaceAfterDialog
                switch -Wildcard ($oDialogResult.PSTypeNames[0]) {
                    "DialogResult.Action.Cancel" {
                        return $oDialogResult
                    }
                    "DialogResult.Action.Back" {
                        return $oDialogResult
                    }
                    "DialogResult.Action.Refresh" {
                        return $oDialogResult
                    }
                    "DialogResult.Scriptblock" {
                        $icr = Invoke-Command $oDialogResult.Value -ArgumentList $oObject
                        return $icr
                    }
                    "DialogResult.Action.*" {
                        return $oDialogResult
                    }
                    "DialogResult.Value" {
                        if ($FunctionToRunOnValue) {
                            $oValueDialogResult = . $FunctionToRunOnValue $oDialogResult.Value
                            switch -Wildcard ($oValueDialogResult.PSTypeNames[0]) {
                                "DialogResult.Action.Exit" {
                                    return $oValueDialogResult
                                }
                                "DialogResult.Action.Back" {
                                    return $oValueDialogResult
                                }
                                "DialogResult.Action.Refresh" {
                                    return $oValueDialogResult
                                }
                                "DialogResult.Action.*" {
                                    throw "Unmanaged action type"
                                }
                            }    
                        } else {
                            return $oDialogResult
                        }
                    }
                }
            }
        }
        $oDialog = if ($InputObject -is [array]) {
            New-CLIDialog -Rows $InputObject
        } else {
            $InputObject
        }
    }
    Process {
        if (-not $KeepValues) {
            $oDialog.Reset()
        }
        if ($Execute) {
            Execute -Dialog $oDialog -Validate:$Validate -DontSpaceAfterDialog:$DontSpaceAfterDialog 
        } else {
            Invoke -Dialog $oDialog -Validate:$Validate -DontSpaceAfterDialog:$DontSpaceAfterDialog
        }
    }
}
