function New-DialogResultValue {
    <#
    .SYNOPSIS
        Creates a DialogResult object for value-type button results with property selection support.

    .DESCRIPTION
        This function creates a structured result object when a user selects a button that returns
        a value or object in a CLI dialog. The result includes the selected value(s), optional
        property selections, and the complete dialog state. The returned object has a specific
        PSTypeName (DialogResult.Value) that allows for pattern matching and switch-based result
        handling. This is one of the core result types used throughout the CLI Dialog framework,
        specifically for buttons that return data selections such as items from tables, lists,
        or object browsers. The function also adds a ValueCount() script method that intelligently
        counts values whether they are single objects, arrays, or null.

    .PARAMETER Value
        The value or object(s) selected by the user. This parameter is mandatory and can be used
        at position 0. Can be a single object, an array of objects, or $null. Typically contains
        items selected from checkboxes, radio buttons, or table rows.

    .PARAMETER SelectedProperties
        Optional array of property names that were selected for the value. Used when the dialog
        allows users to select which properties of an object should be included in the result.
        Can be $null if no property selection is involved. Common in scenarios where users choose
        both objects and their visible/exported properties.

    .PARAMETER DialogResult
        The complete dialog result object containing the Button, Form, Type, and ValidForm
        properties. Provides access to the full dialog state and form values at the time of
        button selection.

    .OUTPUTS
        Returns a hashtable with PSTypeName set to "DialogResult.Value".
        - Type: "Value"
        - Value: The selected value(s)
        - SelectedProperties: Array of selected property names (or $null)
        - DialogResult: The complete dialog result object
        - ValueCount(): Script method that returns count of values (0 for null, array.Count for arrays, 1 for single objects)

    .EXAMPLE
        $selectedItem = Get-Process | Select-Object -First 1
        $result = New-DialogResultValue -Value $selectedItem
        # Returns: DialogResult.Value with ValueCount() = 1

        Creates a value result for a single selected process.

    .EXAMPLE
        $selectedItems = @("Item1", "Item2", "Item3")
        $result = New-DialogResultValue -Value $selectedItems
        Write-Host "Selected $($result.ValueCount()) items"
        # Output: Selected 3 items

        Creates a value result for multiple selected items and uses ValueCount() method.

    .EXAMPLE
        $selectedObjects = Get-Service | Where-Object Status -eq "Running"
        $properties = @("Name", "DisplayName", "Status")
        $result = New-DialogResultValue -Value $selectedObjects -SelectedProperties $properties
        # Result contains both the objects and which properties to display/export

        Creates a value result with both objects and selected properties.

    .EXAMPLE
        $result = New-DialogResultValue -Value $null
        if ($result.ValueCount() -eq 0) {
            Write-Host "No items selected"
        }

        Creates a value result with null value and checks using ValueCount().

    .EXAMPLE
        $result = New-DialogResultValue -Value $items -DialogResult $dialogResult
        switch -Wildcard ($result.PSTypeNames[0]) {
            "DialogResult.Value" {
                foreach ($item in $result.Value) {
                    Process-Item $item
                }
            }
        }

        Creates a value result and uses pattern matching to process selected items.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: None

        This function is part of the CLI Dialog framework's result system. It is used internally
        by New-CLIDialog and Invoke-CLIDialog to standardize value/object selection button results.

        PSTYPENAME STRUCTURE:
        - Format: "DialogResult.Value"
        - Single type (no variations like Action results)
        - Enables switch -Wildcard pattern matching

        VALUECOUNT() METHOD:
        The function adds a custom script method that provides intelligent value counting:
        - Returns 0 if Value is $null
        - Returns array.Count if Value is an array
        - Returns 1 if Value is a single object

        This method is useful for validation, UI feedback, and conditional logic:
        ```powershell
        if ($result.ValueCount() -eq 0) {
            Write-Warning "No items selected"
        } elseif ($result.ValueCount() -eq 1) {
            Write-Host "Processing 1 item..."
        } else {
            Write-Host "Processing $($result.ValueCount()) items..."
        }
        ```

        SELECTEDPROPERTIES USAGE:
        The SelectedProperties parameter supports scenarios where users select both:
        1. Which objects to work with (Value parameter)
        2. Which properties of those objects to include (SelectedProperties parameter)

        Common use cases:
        - Export dialogs: Select objects and which columns to export
        - Display dialogs: Select items and which properties to show
        - Comparison dialogs: Select objects and which fields to compare

        COMMON USE CASES:
        - Table item selection (single or multiple rows)
        - Checkbox selections returning selected items
        - Radio button selection returning chosen option
        - Object browser returning selected objects
        - File/folder picker returning selected paths
        - Property selector dialogs

        RESULT HANDLING PATTERNS:
        ```powershell
        # Pattern 1: Switch on PSTypeName
        switch -Wildcard ($result.PSTypeNames[0]) {
            "DialogResult.Value" {
                $selectedItems = $result.Value
            }
        }

        # Pattern 2: Direct type check with count validation
        if ($result.Type -eq "Value") {
            if ($result.ValueCount() -gt 0) {
                Process-Items $result.Value
            }
        }

        # Pattern 3: Property-aware processing
        if ($result.PSTypeNames[0] -eq "DialogResult.Value") {
            if ($result.SelectedProperties) {
                $result.Value | Select-Object -Property $result.SelectedProperties
            } else {
                $result.Value
            }
        }
        ```

        RELATION TO OTHER RESULT TYPES:
        - New-DialogResultAction: For action buttons (Yes, No, Cancel, etc.)
        - New-DialogResultScriptblock: For scriptblock execution buttons
        - New-DialogResultValue: For value/object selection buttons (this function)

        DIFFERENCE FROM OTHER RESULT TYPES:
        - Action: Represents a user intention or navigation decision
        - Scriptblock: Represents code to execute
        - Value: Represents data/objects selected by the user

        NULL VALUE HANDLING:
        The function accepts $null values explicitly via [AllowNull()] attribute on SelectedProperties.
        This is intentional to support scenarios where:
        - User cancels without selecting items
        - Dialog allows "no selection" as a valid state
        - Property selection is optional

        VALUE TYPE FLEXIBILITY:
        The Value parameter accepts [object] type, allowing maximum flexibility:
        - Primitive types: strings, numbers, booleans
        - Complex objects: PSCustomObject, COM objects, .NET objects
        - Collections: arrays, ArrayLists, generic Lists
        - Special types: FileInfo, DirectoryInfo, Process, Service, etc.

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Support for value-type button results
            - PSTypeName-based result identification
            - ValueCount() script method for intelligent value counting
            - SelectedProperties support for property selection scenarios
            - Integration with dialog result system
            - Access to dialog state via DialogResult parameter
            - Null value handling support
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Value,
        [AllowNull()]
        [object]$SelectedProperties,
        [object]$DialogResult
    )
    $sResultType = "DialogResult.Value"
    $hResult = @{
        Type = "Value"
        Value = $Value
        SelectedProperties = $SelectedProperties
        DialogResult = $DialogResult
    }
    $hResult | Add-Member -MemberType ScriptMethod -Name "ValueCount" -Value {
        if ($null -eq $this.Value) {
            return 0
        } elseif ($this.Value -is [array]) {
            return $this.Value.Count
        } else {
            return 1
        }
    }
    $hResult.PSTypeNames.Insert(0, $sResultType)
    return $hResult
}
