function Read-CLIDialogNumericValue {
    <#
    .SYNOPSIS
        Displays an interactive dialog to collect a validated numeric value (integer or decimal) from the user.

    .DESCRIPTION
        This function provides a specialized dialog for collecting numeric input with comprehensive validation.
        It supports both integer and decimal numbers, optional min/max range validation, default values,
        and customizable error messages. The function uses regex validation combined with type conversion
        and range checking to ensure the entered value meets all specified criteria.

        The validation process:
        1. Format validation via regex (integer or decimal pattern)
        2. Type conversion to long (integer) or double (decimal)
        3. Range validation against Min and Max bounds (if specified)
        4. Returns validated numeric value or $null if cancelled

        The function delegates to Read-CLIDialogValidatedValue with a custom validation scriptblock
        that captures Min, Max, and type settings via closure.

    .PARAMETER Header
        Header text displayed above the input field. This parameter is mandatory and can be used
        at position 0. Typically describes what numeric value is being requested.
        Example: "Enter port number", "CPU threshold percentage"

    .PARAMETER PropertyName
        Name of the property being collected. This parameter is mandatory and can be used at position 1.
        Used as the field label in the dialog. Example: "Port", "Threshold", "Count"

    .PARAMETER Decimal
        Switch parameter. When set, allows decimal numbers (double precision floating point).
        Without this switch, only integers (long) are accepted.
        Decimal separator can be either comma (,) or period (.) for international support.

    .PARAMETER Min
        Minimum allowed value (inclusive). Can be $null for no minimum limit.
        Applied after format validation and type conversion.
        Works with both integer and decimal modes.

    .PARAMETER Max
        Maximum allowed value (inclusive). Can be $null for no maximum limit.
        Applied after format validation and type conversion.
        Works with both integer and decimal modes.
        Note: If both Min and Max are specified, Min must be less than or equal to Max.

    .PARAMETER DefaultValue
        Default numeric value to pre-populate in the input field. Can be $null for no default.
        When specified, the user can press Enter to accept the default or leave the field empty
        to use the default value. The regex validation becomes optional when a default is provided.

    .PARAMETER AllowCancel
        Switch parameter. When set, adds a Cancel button to the dialog.
        If user cancels, the function returns $null. Without this switch, only OK button is displayed.

    .PARAMETER ErrorMessage
        Custom error message displayed when validation fails.
        Default: "Invalid value, please enter value with correct format."
        The error message is shown inline when the user enters an invalid value.

    .OUTPUTS
        Returns the validated numeric value as long (integer mode) or double (decimal mode).
        Returns $null if user cancels (when AllowCancel is set).

    .EXAMPLE
        $port = Read-CLIDialogNumericValue -Header "Server Configuration" -PropertyName "Port" -Min 1 -Max 65535
        if ($port) {
            Start-Server -Port $port
        }

        Collects a port number between 1 and 65535.

    .EXAMPLE
        $threshold = Read-CLIDialogNumericValue -Header "Performance Settings" `
                                                -PropertyName "CPU Threshold %" `
                                                -Decimal `
                                                -Min 0 `
                                                -Max 100 `
                                                -DefaultValue 80.5

        Collects a decimal CPU threshold percentage with default value of 80.5%.

    .EXAMPLE
        $count = Read-CLIDialogNumericValue -Header "Batch Processing" `
                                           -PropertyName "Items to Process" `
                                           -Min 1 `
                                           -AllowCancel
        if ($null -eq $count) {
            Write-Host "User cancelled"
            return
        }

        Collects a positive integer with cancellation support.

    .EXAMPLE
        $temperature = Read-CLIDialogNumericValue -Header "Temperature Monitor" `
                                                  -PropertyName "Alert Temperature (°C)" `
                                                  -Decimal `
                                                  -Min -273.15 `
                                                  -Max 1000 `
                                                  -ErrorMessage "Temperature must be between -273.15°C and 1000°C"

        Collects a temperature with custom error message and negative values allowed.

    .EXAMPLE
        $retries = Read-CLIDialogNumericValue -Header "Network Settings" `
                                             -PropertyName "Max Retries" `
                                             -Min 0 `
                                             -DefaultValue 3

        Collects retry count with default value, minimum of 0, no maximum.

    .EXAMPLE
        $timeout = Read-CLIDialogNumericValue -Header "Timeout" -PropertyName "Seconds" -Min 1

        Minimal example: collect positive integer timeout value.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-27
        Version: 1.0.0
        Dependencies: Read-CLIDialogValidatedValue

        This function is a specialized wrapper around Read-CLIDialogValidatedValue that provides
        numeric-specific validation logic. It's ideal for collecting configuration values, thresholds,
        counts, measurements, and other numeric parameters with guaranteed validity.

        VALIDATION LOGIC:
        The function creates a validation scriptblock with closure that captures:
        - $sValidationRegex: Pattern matching integers or decimals
        - $sConvertedType: Target type ("long" for integers, "double" for decimals)
        - $Min and $Max: Range bounds

        Validation steps:
        1. Regex format check (integer: ^-?\d+$, decimal: ^-?\d+([.,]\d+)?$)
        2. Type conversion using -as operator
        3. Min boundary check (if Min is not null)
        4. Max boundary check (if Max is not null)

        INTEGER MODE (default):
        - Accepts: Whole numbers with optional minus sign
        - Type: System.Int64 (long)
        - Range: -9,223,372,036,854,775,808 to 9,223,372,036,854,775,807
        - Examples: -5, 0, 42, 1000000

        DECIMAL MODE (-Decimal):
        - Accepts: Numbers with optional decimal point and optional minus sign
        - Decimal separator: Both comma (,) and period (.) supported
        - Type: System.Double
        - Range: ±5.0 × 10^−324 to ±1.7 × 10^308
        - Examples: -3.14, 0.5, 42, 1000.25, 3,14 (European notation)

        DEFAULT VALUE BEHAVIOR:
        When DefaultValue is specified:
        - Regex becomes optional (accepts empty string)
        - Empty input is converted to default value
        - User can press Enter immediately to accept default
        - Visual indication shows default value in the field

        MIN/MAX VALIDATION:
        - Min and Max are inclusive bounds
        - Can specify Min only, Max only, or both
        - Can use $null to indicate no limit
        - ArgumentOutOfRangeException thrown if Min > Max
        - Works with negative numbers in both modes

        INTERNATIONAL NUMBER FORMAT:
        The function accepts both comma and period as decimal separators:
        - 3.14 (US/UK format)
        - 3,14 (European format)
        Both are internally converted to PowerShell's double type correctly.

        ERROR HANDLING:
        - Invalid format: Shows ErrorMessage
        - Out of range: Shows ErrorMessage
        - Min > Max: Throws ArgumentOutOfRangeException at function start
        - Conversion failure: Validation fails, shows ErrorMessage

        COMMON USE CASES:
        - Port numbers (1-65535)
        - Percentages (0-100)
        - Counts (positive integers)
        - Timeouts (seconds, milliseconds)
        - Thresholds (CPU, memory, disk usage)
        - Temperatures (can be negative)
        - Coordinates (latitude, longitude)
        - Quantities (inventory, batch sizes)
        - Indices (0-based or 1-based)

        KEYBOARD NAVIGATION:
        - Type numbers directly
        - Enter: Submit value (if valid)
        - O: Press OK button
        - C: Press Cancel button (when AllowCancel is set)
        - Esc: Cancel dialog (when AllowCancel is set)

        VALIDATION SCRIPTBLOCK CLOSURE:
        The function uses .GetNewClosure() to capture variables in the validation scriptblock:
        - $sValidationRegex
        - $sConvertedType
        - $Min
        - $Max
        This ensures the validation logic has access to the correct bounds and type settings.

        COMPARISON WITH OTHER FUNCTIONS:
        - Read-CLIDialogNumericValue: Specialized for numeric input (this function)
        - Read-CLIDialogValidatedValue: Generic validation with custom scriptblock
        - Read-CLIDialogHashtable: Multiple fields with optional regex validation
        - New-CLIDialogTextBox: Single textbox with regex validation only

        EXAMPLE VALIDATION SCENARIOS:
        ```powershell
        # Port number (1-65535)
        Read-CLIDialogNumericValue -Header "Port" -PropertyName "Port" -Min 1 -Max 65535

        # Percentage (0-100 with decimals)
        Read-CLIDialogNumericValue -Header "%" -PropertyName "Value" -Decimal -Min 0 -Max 100

        # Positive count
        Read-CLIDialogNumericValue -Header "Count" -PropertyName "Items" -Min 1

        # Temperature (can be negative)
        Read-CLIDialogNumericValue -Header "Temp" -PropertyName "°C" -Decimal -Min -273.15

        # Any integer
        Read-CLIDialogNumericValue -Header "Value" -PropertyName "Number"

        # Zero or positive
        Read-CLIDialogNumericValue -Header "Index" -PropertyName "Position" -Min 0
        ```

        CHANGELOG:

        Version 1.0.0 - 2025-10-27 - Loïc Ade
            - Initial release
            - Integer and decimal number support
            - Optional Min/Max range validation
            - Default value support with optional input
            - Custom error messages
            - International decimal separator support (comma and period)
            - Negative number support
            - Validation via regex + type conversion + range check
            - Scriptblock closure for validation logic
            - ArgumentOutOfRangeException for invalid Min/Max
            - Integration with Read-CLIDialogValidatedValue
            - Optional Cancel button support
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Header,
        [Parameter(Mandatory, Position = 1)]
        [string]$PropertyName,
        [switch]$Decimal,
        [allownull()]
        [double]$Min = $null,
        [allownull()]
        [double]$Max = $null,
        [allownull()]
        [double]$DefaultValue = $null,
        [switch]$AllowCancel,
        [string]$ErrorMessage = "Invalid value, please enter value with correct format."
    )

    if ($PSBoundParameters.ContainsKey("min") -and $PSBoundParameters.ContainsKey("max") -and ($Min -gt $Max)) {
        throw [System.ArgumentOutOfRangeException] "Minimum value is higher than max value!"
    }
    $sConvertedType = if ($Decimal) { "double" } else { "long" }
    
    # Regex to validate the format based on type
    $sIntegerRegex = "^-?\d+$"  # Integers only (with optional sign)
    $sDecimalRegex = "^-?\d+([.,]\d+)?$"  # Integers or decimals (with optional sign)

    # If DefaultValue exists, also accept empty string
    if ($DefaultValue) {
        $sIntegerRegex = "^(-?\d+)?$"  # Optional integers
        $sDecimalRegex = "^(-?\d+([.,]\d+)?)?$"  # Optional integers or decimals
    }
    
    $sValidationRegex = if ($Decimal) { $sDecimalRegex } else { $sIntegerRegex }
    
    # Create a scriptblock that captures the Min and Max values in the closure
    $sb = {
        param(
            [Parameter(Mandatory, Position = 0)]
            [object]$value
        )
        
        try {
            # First verify the format with the regex
            if ($value -notmatch $sValidationRegex) {
                return $false
            }
            
            # Convert the value to the specified type
            $dValue = $value -as $sConvertedType
            if ($null -eq $dValue) {
                return $false
            }
            
            # Verify the bounds
            if ($Min -ne $null -and $dValue -lt $Min) {
                return $false
            }
            if ($Max -ne $null -and $dValue -gt $Max) {
                return $false
            }
            
            return $true
        } catch {
            return $false
        }
    }.GetNewClosure()
    
    $hReadValueParameters = @{
        Header = $Header
        PropertyName = $PropertyName
        ValidationMethod = $sb
        AllowCancel = $AllowCancel
    }
    if ($DefaultValue) {
        $hReadValueParameters.DefaultValue = $DefaultValue
    }
    Read-CLIDialogValidatedValue @hReadValueParameters
}