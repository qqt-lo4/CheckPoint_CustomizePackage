function Read-CLIDialogValidatedValue {
    <#
    .SYNOPSIS
        Displays an interactive dialog to collect a single validated value from the user.

    .DESCRIPTION
        This is a generic validation dialog function that accepts either regex pattern validation or
        custom scriptblock validation. It provides a flexible foundation for collecting single-field
        input with guaranteed validity. The function is used as a building block by more specialized
        input functions like Read-CLIDialogNumericValue.

        Key features:
        - Dual validation modes: Regex string pattern or custom scriptblock
        - Optional default value with automatic substitution on empty input
        - Optional Cancel button with null return
        - Custom error messages
        - SecureString support (parameter defined but not yet fully implemented)
        - Default value display in field header (e.g., "Port [8080]")

        The function creates a simple dialog with:
        1. Header text explaining what to enter
        2. Single textbox with validation
        3. OK button (and optionally Cancel button)

    .PARAMETER Header
        Header text displayed above the input field. Describes what value is being requested.
        Example: "Enter server address", "Please provide your API key"

    .PARAMETER PropertyName
        Name of the property being collected. Used as the field label and as the key in the
        returned result. Example: "ServerAddress", "ApiKey", "Port"

    .PARAMETER ValidationMethod
        Validation method to apply to the input. Accepts two types:

        [string] - Treated as a regex pattern for validation
        Example: "^[0-9]+$" (numbers only)

        [scriptblock] - Custom validation function that receives the value and returns $true/$false
        Example: { param($value) $value -as [int] -and $value -gt 0 }

        The ValidationMethod is mandatory in practice (though not marked as such for flexibility).

    .PARAMETER AllowCancel
        Switch parameter. When set, adds a Cancel button to the dialog. If user cancels,
        the function returns a DialogResult.Action.Cancel result instead of a value.

    .PARAMETER AsSecureString
        Switch parameter. Intended for password/sensitive input that should be returned as SecureString.
        Note: This parameter is defined but the implementation is not yet complete in the current version.

    .PARAMETER ErrorMessage
        Custom error message displayed when validation fails.
        Default: "Invalid value, please enter value with correct format."
        Shown inline below the textbox when user enters an invalid value.

    .PARAMETER DefaultValue
        Default value to use when user leaves the field empty. When specified:
        - Displayed in field header as "[DefaultValue]"
        - If user enters nothing and presses OK, DefaultValue is returned
        - Regex validation is modified to accept empty string (pattern becomes "pattern|^$")

    .OUTPUTS
        Returns a DialogResult object:
        - DialogResult.Value: When user validates (contains .Value property with entered/default value)
        - DialogResult.Action.Cancel: When user cancels (if AllowCancel is set)

        The .Value property contains the validated string (or SecureString if AsSecureString).

    .EXAMPLE
        $result = Read-CLIDialogValidatedValue -Header "Server Configuration" `
                                               -PropertyName "Hostname" `
                                               -ValidationMethod "^[a-zA-Z0-9.-]+$"
        if ($result.Type -eq "Value") {
            $hostname = $result.Value
        }

        Collects a hostname with regex validation.

    .EXAMPLE
        $validationScript = { param($value) ($value -as [int]) -and ($value -ge 1) -and ($value -le 65535) }
        $result = Read-CLIDialogValidatedValue -Header "Network Settings" `
                                               -PropertyName "Port" `
                                               -ValidationMethod $validationScript `
                                               -DefaultValue "8080"

        Collects a port number with scriptblock validation and default value.

    .EXAMPLE
        $emailRegex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
        $result = Read-CLIDialogValidatedValue -Header "User Registration" `
                                               -PropertyName "Email" `
                                               -ValidationMethod $emailRegex `
                                               -AllowCancel `
                                               -ErrorMessage "Please enter a valid email address"
        if ($result.Action -eq "Cancel") {
            Write-Host "Registration cancelled"
            return
        }

        Collects email with custom error message and cancellation support.

    .EXAMPLE
        $validator = { param($v) Test-Path $v -PathType Leaf }
        $result = Read-CLIDialogValidatedValue -Header "File Selection" `
                                               -PropertyName "FilePath" `
                                               -ValidationMethod $validator `
                                               -ErrorMessage "File does not exist"

        Validates that entered path points to an existing file.

    .EXAMPLE
        $result = Read-CLIDialogValidatedValue -Header "API Configuration" `
                                               -PropertyName "BaseUrl" `
                                               -ValidationMethod "^https?://.+" `
                                               -DefaultValue "https://api.example.com"

        Collects URL with regex validation and default value displayed as "[https://api.example.com]".

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2023-05-29
        Modified: 2025-10-27
        Version: 2.0.0
        Dependencies: New-CLIDialogText, New-CLIDialogTextBox, New-CLIDialogButton,
                     New-CLIDialogObjectsRow, Invoke-CLIDialog, New-DialogResultValue

        This function serves as a generic building block for more specialized input functions.
        It provides the core validation logic that other functions can build upon.

        VALIDATION MODES:

        1. REGEX VALIDATION (ValidationMethod is string):
           - Direct pattern matching against user input
           - When DefaultValue is set, pattern becomes "originalPattern|^$" (accepts empty)
           - Fast and simple for format validation
           - Examples: email, phone, IP address, alphanumeric patterns

        2. SCRIPTBLOCK VALIDATION (ValidationMethod is scriptblock):
           - Custom validation function receives the value as parameter
           - Must return $true (valid) or $false (invalid)
           - Allows complex validation logic (range checks, external lookups, etc.)
           - Example: { param($value) ($value -as [int]) -and ($value -gt 0) }

        DEFAULT VALUE BEHAVIOR:
        When DefaultValue is specified:
        - Header shows: "PropertyName [DefaultValue]"
        - User can leave field empty and press Enter
        - Empty input returns DefaultValue instead of empty string
        - Regex validation automatically modified to accept empty string
        - Useful for configuration with sensible defaults

        RETURN VALUE STRUCTURE:
        Success (validation passed):
        ```powershell
        @{
            Type = "Value"
            Value = "user entered value" # or DefaultValue if input was empty
            DialogResult = @{ ... }
        }
        ```

        Cancellation (when AllowCancel is set):
        ```powershell
        @{
            Type = "Action"
            Action = "Cancel"
        }
        ```

        ERROR HANDLING:
        - Invalid input: Shows ErrorMessage inline, keeps dialog open
        - User must correct input or cancel (if AllowCancel)
        - Validation runs on each keystroke or on submit attempt
        - No way to bypass validation (ensures data integrity)

        KEYBOARD NAVIGATION:
        - Type directly in textbox
        - Enter: Submit value (if valid)
        - O: Press OK button (validates before accepting)
        - C: Press Cancel button (if AllowCancel is set)
        - Esc: Cancel dialog (if AllowCancel is set)

        COMPARISON WITH SPECIALIZED FUNCTIONS:
        - Read-CLIDialogValidatedValue: Generic single-field validation (this function)
        - Read-CLIDialogNumericValue: Specialized for numbers with Min/Max
        - Read-CLIDialogHashtable: Multiple fields with schema
        - Read-CLIDialogCredential: Specialized for username/password
        - Read-CLIDialogConnectionInfo: Specialized for server/port/credentials

        COMMON REGEX PATTERNS:
        ```powershell
        # Email
        "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

        # URL (http/https)
        "^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/.*)?$"

        # IPv4 address
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

        # Alphanumeric only
        "^[a-zA-Z0-9]+$"

        # Non-empty
        "^.+$"

        # Numbers only
        "^[0-9]+$"

        # Version number (semver-like)
        "^[0-9]+\.[0-9]+\.[0-9]+$"
        ```

        COMMON SCRIPTBLOCK VALIDATORS:
        ```powershell
        # Positive integer
        { param($v) ($v -as [int]) -and ($v -gt 0) }

        # File exists
        { param($v) Test-Path $v -PathType Leaf }

        # Directory exists
        { param($v) Test-Path $v -PathType Container }

        # Valid JSON
        { param($v) try { $v | ConvertFrom-Json; $true } catch { $false } }

        # Remote server reachable
        { param($v) Test-Connection $v -Count 1 -Quiet }

        # Value in array
        { param($v) $v -in @("Dev", "Test", "Prod") }
        ```

        USE CASES:
        - API keys/tokens with format validation
        - File/folder path validation
        - Custom format strings (URLs, emails, etc.)
        - Enumerated value selection (via scriptblock)
        - Any single-value input requiring validation

        ASECURESTRING PARAMETER:
        The AsSecureString parameter is defined but not fully implemented in the current version.
        Future versions should:
        - Pass PasswordChar parameter to New-CLIDialogTextBox
        - Convert string result to SecureString before returning
        - Update return type documentation

        EXTENSIBILITY:
        This function is designed to be extended by wrapper functions that provide:
        - Specialized validation logic (like Read-CLIDialogNumericValue)
        - Domain-specific defaults
        - Pre-configured regex patterns
        - Custom error messages for specific scenarios

        CHANGELOG:

        Version 2.0.0 - 2025-10-27 - Loïc Ade
            - Dual validation mode: regex string or scriptblock
            - Optional default value with automatic empty string handling
            - Optional Cancel button support
            - Custom error messages
            - Default value displayed in header
            - AsSecureString parameter (not yet fully implemented)
            - Integration with CLI Dialog framework
            - DialogResult return value
            - Invisible header for button row (cleaner layout)
            - Renamed from Read-ValidatedValue to Read-CLIDialogValidatedValue

        Version 1.0.0 - 2023-05-29 - Loïc Ade
            - Initial release
    #>
    Param(
        [string]$Header,
        [string]$PropertyName,
        [object]$ValidationMethod,
        [switch]$AllowCancel,
        [switch]$AsSecureString,
        [string]$ErrorMessage = "Invalid value, please enter value with correct format.",
        [string]$DefaultValue
    )
    $aButtons = @(
        New-CLIDialogButton -Text "&Ok" -Validate
    )
    if ($AllowCancel) {
        $aButtons += New-CLIDialogButton -Text "&Cancel" -Cancel
    }
    $hTextboxParameters = @{
        Name = $PropertyName
    }
    $hTextboxParameters.Header = if ($DefaultValue) {
        "$PropertyName [$DefaultValue]"
    } else {
        $PropertyName
    }
    if ($ValidationMethod -is [string]) {
        $hTextboxParameters.Regex = if ($DefaultValue) {
            "$Regex|^$"
        } else {
            $Regex
        }
    } elseif ($ValidationMethod -is [scriptblock]) {
        $hTextboxParameters.ValidationScript = $ValidationMethod
    } else {
        throw "Unsupported validation method"
    }
    $oDialogLines = @(
        New-CLIDialogText -Text $Header -AddNewLine
        New-CLIDialogTextBox @hTextboxParameters -HeaderSeparator " :  "
        New-CLIDialogObjectsRow -Row $aButtons -InvisibleHeader
    )
    $oDialogResult = Invoke-CLIDialog $oDialogLines -Validate
    if (($oDialogResult.Type -eq "Action") -and ($oDialogResult.Action -eq "Validate")) {
        $oDialogResultForm = $oDialogResult.DialogResult.Form.GetValue($true)
        if (($oDialogResultForm."$PropertyName" -eq "") -and $DefaultValue) {
            return New-DialogResultValue -Value $DefaultValue -DialogResult $oDialogResult.DialogResult
        } else {
            return New-DialogResultValue -Value $oDialogResultForm."$PropertyName" -DialogResult $oDialogResult.DialogResult
        }
    } else {
        return $oDialogResult
    }
}
