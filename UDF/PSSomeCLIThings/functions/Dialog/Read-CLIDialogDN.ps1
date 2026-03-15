function Read-CLIDialogDN {
    <#
    .SYNOPSIS
        Displays an interactive dialog to collect and validate a Distinguished Name (DN) from the user.

    .DESCRIPTION
        This function creates a dialog that collects an X.500 Distinguished Name with format validation.
        Supports common RDN attributes: CN, OU, O, L, ST, C, E, DC.
        Built on top of Read-CLIDialogValidatedValue for consistent dialog experience.

    .PARAMETER Header
        Header text displayed above the input field.
        Default: "Please enter a Distinguished Name (DN)"

    .PARAMETER PropertyName
        Name of the property displayed in the dialog input field.
        Default: "DN"

    .PARAMETER ErrorMessage
        Custom error message displayed when validation fails.
        Default: "Invalid DN format. Expected format: CN=value,OU=value,O=value,C=XX"

    .PARAMETER AllowCancel
        When specified, adds a Cancel button. Returns null if user cancels.

    .PARAMETER AllowBack
        When specified, adds a Back button. Returns a DialogResult.Action.Back object when pressed.

    .OUTPUTS
        String - Validated Distinguished Name
        DialogResult.Action.Back - If user presses Back (when AllowBack is set)
        $null - If user cancels (when AllowCancel is set)

    .EXAMPLE
        $dn = Read-CLIDialogDN
        Write-Host "DN entered: $dn"

    .EXAMPLE
        $dn = Read-CLIDialogDN -AllowCancel -AllowBack
        if ($null -eq $dn) {
            Write-Host "User cancelled"
        }

    .EXAMPLE
        $dn = Read-CLIDialogDN -Header "Enter certificate subject"
        Write-Host "Subject: $dn"

    .NOTES
        Author: Loïc Ade
        Created: 2026-03-14
        Version: 1.0.0
        Module: CLIDialog
        Dependencies: Read-CLIDialogValidatedValue, Get-DNRegex

        CHANGELOG:

        Version 1.0.0 - 2026-03-14 - Loïc Ade
            - Initial release
            - DN validation using Get-DNRegex
            - Cancel and Back button support
    #>
    Param(
        [string]$Header = "Please enter a Distinguished Name (DN)",
        [string]$PropertyName = "DN",
        [string]$ErrorMessage = "Invalid DN format. Expected format: CN=value,OU=value,O=value,C=XX",
        [string]$DefaultValue,
        [switch]$AllowCancel,
        [switch]$AllowBack
    )

    $sDNRegex = Get-DNRegex -FullLine
    $validationScript = {
        param($value)
        if ($value -eq "") { return $false }
        return $value -match $sDNRegex
    }.GetNewClosure()

    $params = @{
        Header           = $Header
        PropertyName     = $PropertyName
        ValidationMethod = $validationScript
        ErrorMessage     = $ErrorMessage
    }

    if ($AllowCancel) {
        $params.AllowCancel = $true
    }

    if ($AllowBack) {
        $params.AllowBack = $true
    }
    if ($DefaultValue) {
        $params.DefaultValue = $DefaultValue
    }

    $result = Read-CLIDialogValidatedValue @params

    if ($result.Type -eq "Action" -and $result.Action -eq "Back") {
        return New-DialogResultAction -Action "Back"
    } elseif ($result.Type -eq "Action" -and $result.Action -eq "Cancel") {
        return $null
    } elseif ($result.Type -eq "Value") {
        return $result.Value
    }
}
