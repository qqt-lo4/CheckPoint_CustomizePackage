function Read-CLIDialogHashtable {
    <#
    .SYNOPSIS
        Displays an interactive dialog to collect values for hashtable properties with optional validation.

    .DESCRIPTION
        This function creates a dynamic form dialog based on a hashtable schema where each key becomes
        a labeled textbox field. It's designed for collecting structured data where property names and
        optional validation rules are defined in advance. The function returns a hashtable with user-entered
        values, making it ideal for configuration input, form data collection, or parameter gathering scenarios.

        Each property in the input hashtable can define:
        - The property name (hashtable key)
        - Optional regex validation pattern (Properties[$key].Regex)

        The dialog automatically generates textboxes for all properties, validates input, and returns
        the completed hashtable or $null if cancelled.

    .PARAMETER Properties
        A hashtable or dictionary defining the properties to collect. This parameter is mandatory.

        Structure:
        @{
            "PropertyName1" = @{ Regex = "pattern" }  # With validation
            "PropertyName2" = @{}                      # Without validation
        }

        The hashtable keys become the field labels/names in the dialog.
        Each value should be a hashtable that may contain:
        - Regex: Optional regular expression pattern for validation

    .PARAMETER SeparatorColor
        Color of the separator lines at the top and bottom of the dialog. Default: Blue

    .PARAMETER PropertiesHeaderColor
        Color of the property labels (field headers). Default: Green

    .PARAMETER Header
        Header text displayed in the top separator of the dialog.
        Default: "Please enter all required values"

    .PARAMETER PropertyAlign
        Alignment of property labels (field headers). Valid values: "Left", "Right"
        Default: "Left"

    .PARAMETER Prefix
        Prefix string displayed before unfocused fields. Default: "  " (two spaces)

    .PARAMETER FocusedPrefix
        Prefix string displayed before focused field. Default: "> "

    .PARAMETER AllowCancel
        Switch parameter. When set, adds a Cancel button to the dialog. If user cancels,
        the function returns $null. Without this switch, only the OK button is displayed.

    .OUTPUTS
        Returns a hashtable containing the entered values with property names as keys.
        Returns $null if user cancels (when AllowCancel is set) or if validation fails.

        The returned hashtable uses the same keys as the input Properties hashtable.

    .EXAMPLE
        $properties = @{
            "ServerName" = @{ Regex = "^[a-zA-Z0-9.-]+$" }
            "Port" = @{ Regex = "^[0-9]{1,5}$" }
            "Username" = @{}
        }
        $result = Read-CLIDialogHashtable -Properties $properties
        if ($result) {
            Connect-Server -Server $result.ServerName -Port $result.Port -User $result.Username
        }

        Collects server connection parameters with validation for server name and port.

    .EXAMPLE
        $config = @{
            "ApplicationName" = @{}
            "LogLevel" = @{ Regex = "^(Debug|Info|Warning|Error)$" }
            "MaxRetries" = @{ Regex = "^[0-9]+$" }
        }
        $settings = Read-CLIDialogHashtable -Properties $config -Header "Application Configuration"

        Collects application configuration with validated log level and retry count.

    .EXAMPLE
        $userInfo = @{
            "FirstName" = @{}
            "LastName" = @{}
            "Email" = @{ Regex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" }
        }
        $result = Read-CLIDialogHashtable -Properties $userInfo `
                                         -AllowCancel `
                                         -Header "User Registration" `
                                         -PropertyAlign Right

        Collects user information with email validation, right-aligned labels, and cancel option.

    .EXAMPLE
        $dbConfig = @{
            "Database" = @{}
            "Schema" = @{}
            "TablePrefix" = @{ Regex = "^[a-zA-Z_][a-zA-Z0-9_]*$" }
        }
        $result = Read-CLIDialogHashtable -Properties $dbConfig `
                                         -SeparatorColor Cyan `
                                         -PropertiesHeaderColor Yellow

        Collects database configuration with custom colors.

    .EXAMPLE
        $simpleForm = @{
            "Name" = @{}
            "Description" = @{}
        }
        $data = Read-CLIDialogHashtable -Properties $simpleForm -AllowCancel
        if ($null -eq $data) {
            Write-Host "User cancelled input"
        }

        Simple two-field form with cancellation handling.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-04-19
        Version: 1.0.0
        Dependencies: New-CLIDialogSeparator, New-CLIDialogTextBox, New-CLIDialogButton,
                     New-CLIDialogObjectsRow, Invoke-CLIDialog

        This function is ideal for scenarios where you need to collect structured data with
        property names known in advance, such as configuration files, user registration forms,
        or API parameter collection.

        PROPERTIES HASHTABLE STRUCTURE:
        The Properties parameter accepts any IDictionary implementation (Hashtable, OrderedDictionary, etc.)

        For each property, you can define:
        ```powershell
        @{
            "PropertyName" = @{
                Regex = "validation pattern"  # Optional
            }
        }
        ```

        If you need ordered fields (displayed in specific order), use [ordered]@{...}:
        ```powershell
        [ordered]@{
            "FirstName" = @{}
            "LastName" = @{}
            "Email" = @{ Regex = "..." }
        }
        ```

        VALIDATION:
        - Regex validation is optional per property
        - If Regex is specified, user input must match the pattern
        - Validation errors are displayed inline with error details
        - User cannot submit until all validations pass

        RETURN VALUE:
        The function returns a hashtable with the same keys as the input Properties:
        ```powershell
        @{
            "PropertyName1" = "user entered value 1"
            "PropertyName2" = "user entered value 2"
        }
        ```

        The GetValue($true) call ensures that values are returned in a clean hashtable format.

        CANCELLATION:
        - Without AllowCancel: Only OK button, user must fill the form or close the terminal
        - With AllowCancel: Both OK and Cancel buttons, returns $null on cancel

        FIELD ORDERING:
        - Regular @{} hashtables: Order may vary (hash-based)
        - [ordered]@{} hashtables: Preserves definition order
        - For predictable field order, always use [ordered]@{}

        KEYBOARD NAVIGATION:
        - Tab/Shift+Tab: Move between fields
        - Enter: Submit form (when all validations pass)
        - O: Press OK button
        - C: Press Cancel button (when AllowCancel is set)
        - Esc: Cancel dialog (when AllowCancel is set)

        COLOR CUSTOMIZATION:
        All colors can be customized via parameters:
        - SeparatorColor: Top/bottom separator lines
        - PropertiesHeaderColor: Field labels
        Default colors are chosen for good visibility on standard terminal themes.

        ALIGNMENT:
        PropertyAlign affects field label alignment:
        - "Left": Labels aligned to the left (default, compact)
        - "Right": Labels aligned to the right (cleaner for varying label lengths)

        PREFIX CUSTOMIZATION:
        - Prefix: Shown before unfocused fields (default: two spaces)
        - FocusedPrefix: Shown before focused field (default: "> ")
        - Helps user identify which field is currently active

        COMMON REGEX PATTERNS:
        ```powershell
        # Email
        "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"

        # Port number (1-65535)
        "^([1-9][0-9]{0,3}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$"

        # IPv4 address
        "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

        # Alphanumeric with underscores
        "^[a-zA-Z0-9_]+$"

        # Non-empty
        "^.+$"

        # Numeric only
        "^[0-9]+$"
        ```

        USE CASES:
        - Configuration file generation
        - User registration forms
        - API parameter collection
        - Database connection setup
        - Application settings input
        - Structured data collection
        - Parameter validation before script execution

        COMPARISON WITH OTHER FUNCTIONS:
        - Read-CLIDialogConnectionInfo: Specific for server/port/credentials
        - Read-CLIDialogCredential: Specific for username/password
        - Read-CLIDialogHashtable: Generic for any hashtable-based form (this function)
        - Edit-Hashtable: For editing existing hashtables with advanced features

        CHANGELOG:

        Version 1.0.0 - 2025-04-19 - Loïc Ade
            - Initial release
            - Dynamic form generation from hashtable schema
            - Optional regex validation per property
            - Optional Cancel button support
            - Customizable colors and alignment
            - Prefix customization for focus indication
            - IDictionary support for flexible input
            - Clean hashtable output with GetValue($true)
            - Integration with CLI Dialog framework
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [System.Collections.IDictionary]$Properties,
        [System.ConsoleColor]$SeparatorColor = [System.ConsoleColor]::Blue,
        [System.ConsoleColor]$PropertiesHeaderColor = [System.ConsoleColor]::Green,
        [string]$Header = "Please enter all required values",
        [ValidateSet("Left", "Right")]
        [string]$PropertyAlign = "Left",
        [string]$Prefix = "  ",
        [string]$FocusedPrefix = "> ",
        [switch]$AllowCancel
    )
    Begin {
        $aDialogLines = @()
        $aDialogLines += New-CLIDialogSeparator -AutoLength -Text $Header -ForegroundColor $SeparatorColor
        $hTextboxCommonProperties = @{
            HeaderAlign = $PropertyAlign
            FocusedPrefix = $FocusedPrefix 
            Prefix = $Prefix 
            HeaderForegroundColor = $PropertiesHeaderColor
        }
        foreach ($p in $Properties.Keys) {
            $hTextboxProperties = $hTextboxCommonProperties.Clone()
            $hTextboxProperties.Header = $p
            $hTextboxProperties.Name = $p
            if ($Properties[$p].Regex) {
                $hTextboxProperties.Regex = $Properties[$p].Regex
            }
            if ($Properties[$p].Text) {
                $hTextboxProperties.Text = $Properties[$p].Text
            }
            $aDialogLines += New-CLIDialogTextBox @hTextboxProperties
        }
        $aDialogLines += New-CLIDialogSeparator -AutoLength -ForegroundColor $SeparatorColor
        $aButtonsLineItems = @(
            New-CLIDialogButton -Text "&Ok" -Validate 
        )
        if ($AllowCancel) {
            $aButtonsLineItems += New-CLIDialogButton -Text "&Cancel" -Cancel
        }
        $aDialogLines += New-CLIDialogObjectsRow -Header " " -Prefix $Prefix -FocusedPrefix $FocusedPrefix -HeaderSeparator "  " -Row $aButtonsLineItems
    }
    Process {
        $oDialogResult = Invoke-CLIDialog -InputObject $aDialogLines -Validate -ErrorDetails
        if ($oDialogResult.Action -eq "Validate") {
            return $oDialogResult.DialogResult.Form.GetValue($true)
        } else {
            return $null
        }
    }
    End {}
}