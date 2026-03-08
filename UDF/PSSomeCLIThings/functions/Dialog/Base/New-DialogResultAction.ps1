function New-DialogResultAction {
    <#
    .SYNOPSIS
        Creates a DialogResult object for action-type button results.

    .DESCRIPTION
        This function creates a structured result object when a user selects an action button
        (Yes, No, Cancel, Validate, Exit, Back, etc.) in a CLI dialog. The result includes
        the action name, optional associated value, and the complete dialog state. The returned
        object has a specific PSTypeName (DialogResult.Action.*) that allows for pattern matching
        and switch-based result handling. This is one of the core result types used throughout
        the CLI Dialog framework.

    .PARAMETER Action
        The action name representing the button type selected. This parameter is mandatory and
        can be used at position 0. Common values: "Yes", "No", "Cancel", "Validate", "Exit",
        "Back", "Refresh", "Next", "Previous", "Other", "GoTo".

    .PARAMETER Value
        An optional value or scriptblock associated with the action button. Can be null.
        When an action button has an associated scriptblock (Action_Scriptblock type), this
        contains the scriptblock to execute.

    .PARAMETER DialogResult
        The complete dialog result object containing the Button, Form, Type, and ValidForm
        properties. Provides access to the full dialog state and form values.

    .OUTPUTS
        Returns a hashtable with PSTypeName set to "DialogResult.Action.<ActionName>".
        - Type: "Action"
        - Action: The action name string
        - DialogResult: The complete dialog result object
        - Value: (optional) Associated value or scriptblock
        - Depth: (for "Back" action only) Set to 0 to indicate navigation depth

    .EXAMPLE
        $result = New-DialogResultAction -Action "Yes"
        # Returns: DialogResult.Action.Yes

        Creates a simple Yes action result without value.

    .EXAMPLE
        $result = New-DialogResultAction -Action "Cancel" -DialogResult $dialogResult
        switch -Wildcard ($result.PSTypeNames[0]) {
            "DialogResult.Action.Cancel" { Write-Host "User cancelled" }
        }

        Creates a Cancel action result and uses pattern matching to handle it.

    .EXAMPLE
        $scriptblock = { Write-Host "Refreshing..." }
        $result = New-DialogResultAction -Action "Refresh" -Value $scriptblock
        if ($result.Value) {
            & $result.Value
        }

        Creates a Refresh action with an associated scriptblock.

    .EXAMPLE
        $result = New-DialogResultAction -Action "Back"
        # Result includes Depth = 0 for navigation tracking

        Creates a Back action which automatically includes depth tracking.

    .EXAMPLE
        $result = New-DialogResultAction -Action "Validate" -DialogResult $dialogResult
        $formValues = $result.DialogResult.Form.GetValue()

        Creates a Validate action and retrieves form values from the dialog result.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: None

        This function is part of the CLI Dialog framework's result system. It is used internally
        by New-CLIDialog and Invoke-CLIDialog to standardize action button results.

        PSTYPENAME STRUCTURE:
        - Format: "DialogResult.Action.<ActionName>"
        - Examples: "DialogResult.Action.Yes", "DialogResult.Action.Cancel"
        - Enables switch -Wildcard pattern matching: "DialogResult.Action.*"

        ACTION TYPES:
        - Yes, No: Binary confirmation
        - Cancel: Abort operation
        - Validate: Confirm and validate form
        - Exit: Exit dialog or application
        - Back: Navigate to previous screen (includes Depth property)
        - Refresh: Reload dialog content
        - Next, Previous: Pagination navigation
        - Other, GoTo: Custom actions

        BACK ACTION SPECIAL HANDLING:
        - When Action is "Back", automatically adds Depth = 0
        - Used for tracking navigation depth in multi-level dialogs
        - Allows dialog stack management

        RESULT HANDLING PATTERNS:
        ```powershell
        # Pattern 1: Switch on PSTypeName
        switch -Wildcard ($result.PSTypeNames[0]) {
            "DialogResult.Action.Yes" { }
            "DialogResult.Action.Cancel" { }
        }

        # Pattern 2: Check Action property
        if ($result.Action -eq "Validate") { }

        # Pattern 3: Access dialog state
        $formData = $result.DialogResult.Form.GetValue()
        ```

        RELATION TO OTHER RESULT TYPES:
        - New-DialogResultAction: For action buttons (this function)
        - New-DialogResultScriptblock: For scriptblock-only buttons
        - New-DialogResultValue: For value/object selection buttons

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Support for all standard action types
            - PSTypeName-based result identification
            - Optional value association
            - Special handling for Back action with Depth property
            - Integration with dialog result system
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Action,
        [AllowNull()]
        [object]$Value,
        [object]$DialogResult
    )
    $sResultType = "DialogResult.Action.$Action"
    $hResult = @{
        Type = "Action"
        Action = $Action
        DialogResult = $DialogResult
    }
    if ($Value) {
        $hResult.Value = $Value
    }
    if ($Action -eq "Back") {
        $hResult.Depth = 0
    }
    $hResult.PSTypeNames.Insert(0, $sResultType)
    return $hResult
}
