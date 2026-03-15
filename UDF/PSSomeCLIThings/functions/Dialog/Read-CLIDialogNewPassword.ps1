function Read-CLIDialogNewPassword {
    <#
    .SYNOPSIS
        Displays an interactive dialog to collect and confirm a new password.

    .DESCRIPTION
        Creates a dialog with two password fields (password + confirmation) and validates
        that both entries match. Supports optional empty password confirmation, Back navigation,
        and pre-filled values for wizard scenarios.
        Built on top of New-CLIDialogTextBox and Invoke-CLIDialog.

    .PARAMETER Header
        Header text displayed above the password fields.
        Default: "Please enter a new password"

    .PARAMETER PasswordPropertyName
        Label for the password field.
        Default: "Password"

    .PARAMETER ConfirmPropertyName
        Label for the confirmation field.
        Default: "Confirm"

    .PARAMETER ErrorNotMatching
        Error message displayed when passwords don't match.
        Default: "Passwords do not match, please try again"

    .PARAMETER AllowEmpty
        When specified, allows empty passwords. If the user submits an empty password,
        a confirmation dialog is shown to confirm the intent.

    .PARAMETER EmptyConfirmMessage
        Confirmation message when the password is empty and AllowEmpty is set.
        Default: "The password is empty. Do you confirm?"

    .PARAMETER EmptyConfirmYes
        Text for the Yes button in the empty password confirmation dialog.
        Default: "&Yes, keep without password"

    .PARAMETER EmptyConfirmNo
        Text for the No button in the empty password confirmation dialog.
        Default: "&No, enter a password"

    .PARAMETER DefaultValue
        Default password value (SecureString) to pre-fill the fields.
        Useful when navigating back in a wizard.

    .PARAMETER AllowBack
        When specified, adds a Back button. Returns a DialogResult.Action.Back object when pressed.

    .PARAMETER AllowCancel
        When specified, adds a Cancel button. Returns $null when pressed.

    .PARAMETER SeparatorColor
        Color of the separator lines. Default: Blue.

    .OUTPUTS
        [SecureString] - The confirmed password
        [DialogResult.Action.Back] - If user presses Back
        $null - If user cancels or if empty password is confirmed with AllowEmpty

    .EXAMPLE
        $password = Read-CLIDialogNewPassword
        if ($password) {
            Write-Host "Password set"
        }

    .EXAMPLE
        $password = Read-CLIDialogNewPassword -AllowEmpty -AllowBack -Header "Private key password"

    .NOTES
        Author: Loïc Ade
        Created: 2026-03-15
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: New-CLIDialogSeparator, New-CLIDialogTextBox, New-CLIDialogButton,
                     New-CLIDialogObjectsRow, Invoke-CLIDialog, Invoke-YesNoCLIDialog

        CHANGELOG:

        Version 1.0.0 - 2026-03-15 - Loïc Ade
            - Initial release
            - Dual password field with matching validation
            - AllowEmpty with confirmation dialog
            - Back and Cancel button support
            - DefaultValue for wizard back navigation
    #>
    Param(
        [string]$Header = "Please enter a new password",
        [string]$PasswordPropertyName = "Password",
        [string]$ConfirmPropertyName = "Confirm",
        [string]$ErrorNotMatching = "Passwords do not match, please try again",
        [switch]$AllowEmpty,
        [string]$EmptyConfirmMessage = "The password is empty. Do you confirm?",
        [string]$EmptyConfirmYes = "&Yes, keep without password",
        [string]$EmptyConfirmNo = "&No, enter a password",
        [securestring]$DefaultValue,
        [switch]$AllowBack,
        [switch]$AllowCancel,
        [System.ConsoleColor]$SeparatorColor = [System.ConsoleColor]::Blue
    )

    $bAllowEmpty = [bool]$AllowEmpty
    $sValidationRegex = if ($bAllowEmpty) { "^.*$" } else { "^.+$" }

    while ($true) {
        $hTextBoxOptions = @{
            PasswordChar = "*"
            Prefix = "  "
            FocusedPrefix = "> "
        }

        $aDialogLines = @(
            New-CLIDialogSeparator -AutoLength -Text $Header -ForegroundColor $SeparatorColor
        )

        $hPwdParams = $hTextBoxOptions.Clone()
        $hPwdParams.Header = $PasswordPropertyName
        $hPwdParams.Name = "Password"
        $hPwdParams.Regex = $sValidationRegex
        if ($DefaultValue) {
            $hPwdParams.Text = $DefaultValue
        }
        $aDialogLines += New-CLIDialogTextBox @hPwdParams

        $hConfirmParams = $hTextBoxOptions.Clone()
        $hConfirmParams.Header = $ConfirmPropertyName
        $hConfirmParams.Name = "Confirm"
        $hConfirmParams.Regex = $sValidationRegex
        if ($DefaultValue) {
            $hConfirmParams.Text = $DefaultValue
        }
        $aDialogLines += New-CLIDialogTextBox @hConfirmParams

        $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor

        $aButtons = @(
            New-CLIDialogButton -Text "&Ok" -Validate
        )
        if ($AllowCancel) {
            $aButtons += New-CLIDialogButton -Text "&Cancel" -Cancel
        }
        if ($AllowBack) {
            $aButtons += New-CLIDialogButton -Back -Text "&Back"
        }
        $aDialogLines += New-CLIDialogObjectsRow -Header " " -Prefix "  " -FocusedPrefix "> " -HeaderSeparator "  " -Row $aButtons

        $oDialogResult = Invoke-CLIDialog -InputObject $aDialogLines -Validate

        # Handle Back
        if ($oDialogResult.Action -eq "Back") {
            return New-DialogResultAction -Action "Back"
        }

        # Handle Cancel
        if ($oDialogResult.Action -eq "Cancel") {
            return $null
        }

        # Handle Validate
        if ($oDialogResult.Action -eq "Validate") {
            $hFormValues = $oDialogResult.DialogResult.Form.GetValue($true)
            $sPwd1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($hFormValues.Password))
            $sPwd2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($hFormValues.Confirm))

            if ($sPwd1 -ne $sPwd2) {
                Write-Host $ErrorNotMatching -ForegroundColor Red
                continue
            }

            if ($sPwd1.Length -eq 0 -and $bAllowEmpty) {
                $oAnswer = Invoke-YesNoCLIDialog -Message $EmptyConfirmMessage `
                    -Recommended No -YN -Vertical `
                    -YesButtonText $EmptyConfirmYes `
                    -NoButtonText $EmptyConfirmNo
                if ($oAnswer -eq "No") {
                    continue
                }
            }

            return $hFormValues.Password
        }
    }
}
