function Read-CLIDialogIP {
    <#
    .SYNOPSIS
        Displays an interactive dialog to collect and validate an IP address from the user.

    .DESCRIPTION
        This function creates a dialog that collects an IP address with format validation.
        Supports IPv4 addresses with optional CIDR mask notation (e.g., "192.168.1.1/24").
        Built on top of Read-CLIDialogValidatedValue for consistent dialog experience.

        Validation options:
        - Standard: IPv4 with or without mask (e.g., "192.168.1.1" or "192.168.1.1/24")
        - MandatoryMask: Requires CIDR notation (e.g., "192.168.1.1/24")
        - MaskForbidden: Forbids CIDR notation (e.g., only "192.168.1.1")

    .PARAMETER Header
        Header text displayed above the input field.
        Default: "Please enter an IP address"

    .PARAMETER ErrorMessage
        Custom error message displayed when validation fails.
        Default: "Invalid IP address format"

    .PARAMETER AllowEmpty
        When specified, allows empty input. Returns ValueIfEmpty when user enters nothing.

    .PARAMETER ValueIfEmpty
        Value to return when input is empty and AllowEmpty is set.
        Default: "" (empty string)

    .PARAMETER MandatoryMask
        When specified, requires CIDR mask notation (e.g., "192.168.1.1/24").
        Cannot be combined with MaskForbidden.

    .PARAMETER MaskForbidden
        When specified, forbids CIDR mask notation (e.g., only "192.168.1.1" allowed).
        Cannot be combined with MandatoryMask.

    .PARAMETER AllowCancel
        When specified, adds a Cancel button. Returns null if user cancels.

    .OUTPUTS
        String - Validated IP address (with or without mask)
        $null - If user cancels (when AllowCancel is set)

    .EXAMPLE
        $ip = Read-CLIDialogIP
        Write-Host "IP entered: $ip"

        Prompts for IP address with default settings.

    .EXAMPLE
        $ip = Read-CLIDialogIP -MandatoryMask
        Write-Host "Network: $ip"

        Requires CIDR notation (e.g., "192.168.1.0/24").

    .EXAMPLE
        $ip = Read-CLIDialogIP -MaskForbidden -Header "Enter server IP"
        Write-Host "Server IP: $ip"

        Collects IP without mask, with custom header.

    .EXAMPLE
        $ip = Read-CLIDialogIP -AllowEmpty -ValueIfEmpty "127.0.0.1"
        Write-Host "IP: $ip"

        Uses "127.0.0.1" as default if user enters nothing.

    .EXAMPLE
        $ip = Read-CLIDialogIP -AllowCancel
        if ($null -eq $ip) {
            Write-Host "User cancelled"
        } else {
            Write-Host "IP: $ip"
        }

        Allows cancellation and handles null return.

    .NOTES
        Author: Loïc Ade
        Created: 2025-11-22
        Version: 2.0.0
        Module: CLIDialog
        Dependencies: Read-CLIDialogValidatedValue, Test-StringIsIP

        VERSION HISTORY:

        Version 2.0.0 - 2025-11-22 - Loïc Ade
            - Replaced Read-Host with Read-CLIDialogValidatedValue for interactive CLI Dialog interface
            - Added real-time validation with visual feedback (improved UX)
            - Added AllowCancel parameter for user cancellation support (returns null on cancel)
            - Parameter sets ensure MandatoryMask and MaskForbidden are mutually exclusive
            - Comprehensive documentation with multiple examples
            - Maintains backward compatibility: function signature unchanged, existing calls still work
            - New dependency: Requires Read-CLIDialogValidatedValue and CLI Dialog framework

        Version 1.0.0 - Original version
            - Simple Read-Host based input with while loop validation
            - Basic IP validation using Test-StringIsIP
    #>
    [CmdletBinding(DefaultParameterSetName = "Standard")]
    Param(
        [string]$Header = "Please enter an IP address",
        [string]$ErrorMessage = "Invalid IP address format",
        [switch]$AllowEmpty,
        [AllowEmptyString()]
        [string]$ValueIfEmpty = "",
        [Parameter(ParameterSetName = "MandatoryMask")]
        [switch]$MandatoryMask,
        [Parameter(ParameterSetName = "MaskForbidden")]
        [switch]$MaskForbidden,
        [switch]$AllowCancel
    )

    # Create custom validation scriptblock using Test-StringIsIP
    $bAllowEmpty = [bool]$AllowEmpty
    $bMandatoryMask = [bool]$MandatoryMask
    $bMaskForbidden = [bool]$MaskForbidden
    $validationScript = {
        param($value)

        # If value is empty
        if ($value -eq "") {
            return $bAllowEmpty
        }

        # Use Test-StringIsIP for validation
        $result = Test-StringIsIP -string $value -MandatoryMask:$bMandatoryMask -MaskForbidden:$bMaskForbidden
        return $null -ne $result
    }.GetNewClosure()

    # Build parameters for Read-CLIDialogValidatedValue
    $params = @{
        Header           = $Header
        PropertyName     = "IPAddress"
        ValidationMethod = $validationScript
        ErrorMessage     = $ErrorMessage
    }

    # Add optional parameters
    if ($AllowCancel) {
        $params.AllowCancel = $true
    }

    if ($AllowEmpty -and $ValueIfEmpty) {
        $params.DefaultValue = $ValueIfEmpty
    }

    # Call Read-CLIDialogValidatedValue with bound scriptblock parameters
    $result = Read-CLIDialogValidatedValue @params

    # Handle result
    if ($result.Type -eq "Action" -and $result.Action -eq "Cancel") {
        return $null
    } elseif ($result.Type -eq "Value") {
        # If empty and AllowEmpty, return ValueIfEmpty
        if (($result.Value -eq "") -and $AllowEmpty) {
            return $ValueIfEmpty
        }

        # Return the validated IP (already validated by Read-CLIDialogValidatedValue)
        return $result.Value
    }
}
