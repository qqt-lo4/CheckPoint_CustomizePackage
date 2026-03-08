function New-DialogResultScriptblock {
    <#
    .SYNOPSIS
        Creates a DialogResult object for scriptblock-type button results.

    .DESCRIPTION
        This function creates a structured result object when a user selects a button that executes
        a scriptblock in a CLI dialog. The result includes the scriptblock to execute and the complete
        dialog state. The returned object has a specific PSTypeName (DialogResult.Scriptblock) that
        allows for pattern matching and switch-based result handling. This is one of the core result
        types used throughout the CLI Dialog framework, specifically for buttons that perform
        immediate actions via scriptblock execution.

    .PARAMETER Value
        The scriptblock to execute when this result is processed. This parameter is mandatory and
        can be used at position 0. Contains the actual PowerShell scriptblock that will be invoked
        by the caller (typically Invoke-CLIDialog in Execute mode).

    .PARAMETER DialogResult
        The complete dialog result object containing the Button, Form, Type, and ValidForm
        properties. Provides access to the full dialog state and form values at the time of
        button selection.

    .OUTPUTS
        Returns a hashtable with PSTypeName set to "DialogResult.Scriptblock".
        - Type: "Scriptblock"
        - Value: The scriptblock to execute
        - DialogResult: The complete dialog result object

    .EXAMPLE
        $scriptblock = { Write-Host "Button clicked!" }
        $result = New-DialogResultScriptblock -Value $scriptblock
        # Returns: DialogResult.Scriptblock

        Creates a simple scriptblock result.

    .EXAMPLE
        $scriptblock = { param($form) $form.GetValue()["Name"] }
        $result = New-DialogResultScriptblock -Value $scriptblock -DialogResult $dialogResult
        & $result.Value $result.DialogResult.Form

        Creates a scriptblock result and executes it with the form as parameter.

    .EXAMPLE
        $result = New-DialogResultScriptblock -Value { Get-Process | Out-GridView }
        switch -Wildcard ($result.PSTypeNames[0]) {
            "DialogResult.Scriptblock" {
                & $result.Value
            }
        }

        Creates a scriptblock result and uses pattern matching to handle it.

    .EXAMPLE
        $refreshAction = {
            # Reload data from database
            $global:DataCache = Get-DataFromDatabase
        }
        $result = New-DialogResultScriptblock -Value $refreshAction -DialogResult $dialogResult

        Creates a scriptblock result for a refresh action with side effects.

    .NOTES
        Module: CLIDialog
        Author: Loïc Ade
        Created: 2025-10-20
        Version: 1.0.0
        Dependencies: None

        This function is part of the CLI Dialog framework's result system. It is used internally
        by New-CLIDialog and Invoke-CLIDialog to standardize scriptblock button results.

        PSTYPENAME STRUCTURE:
        - Format: "DialogResult.Scriptblock"
        - Single type (no variations like Action results)
        - Enables switch -Wildcard pattern matching

        SCRIPTBLOCK EXECUTION:
        - The scriptblock is NOT automatically executed by this function
        - Caller must explicitly invoke the scriptblock using & operator or Invoke-Command
        - Scriptblock can accept parameters (commonly the dialog form or result object)
        - Execution typically happens in Invoke-CLIDialog's Execute mode

        COMMON USE CASES:
        - Immediate actions that don't navigate to another dialog
        - Refresh/reload operations
        - Data processing or calculation triggers
        - Side effects like logging or notifications
        - Quick actions that modify application state

        RESULT HANDLING PATTERNS:
        ```powershell
        # Pattern 1: Switch on PSTypeName
        switch -Wildcard ($result.PSTypeNames[0]) {
            "DialogResult.Scriptblock" {
                & $result.Value
            }
        }

        # Pattern 2: Direct type check and execution
        if ($result.Type -eq "Scriptblock") {
            $output = & $result.Value
        }

        # Pattern 3: Pass dialog state to scriptblock
        if ($result.PSTypeNames[0] -eq "DialogResult.Scriptblock") {
            & $result.Value -Form $result.DialogResult.Form
        }
        ```

        RELATION TO OTHER RESULT TYPES:
        - New-DialogResultAction: For action buttons (Yes, No, Cancel, etc.)
        - New-DialogResultScriptblock: For scriptblock-only buttons (this function)
        - New-DialogResultValue: For value/object selection buttons

        DIFFERENCE FROM ACTION_SCRIPTBLOCK:
        - Action_Scriptblock: Combines an action (like Refresh) with an optional scriptblock
        - Scriptblock (this type): Pure scriptblock execution without predefined action
        - Action_Scriptblock results are created via New-DialogResultAction with Value parameter
        - Scriptblock results are created via this function

        SCRIPTBLOCK SAFETY:
        - Scriptblocks execute in the caller's scope
        - Can access and modify variables in the calling scope
        - Use param() blocks for explicit parameter passing
        - Consider using Begin/Process/End blocks for pipeline scenarios

        CHANGELOG:

        Version 1.0.0 - 2025-10-20 - Loïc Ade
            - Initial release
            - Support for scriptblock-type button results
            - PSTypeName-based result identification
            - Integration with dialog result system
            - Access to dialog state via DialogResult parameter
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Value,
        [object]$DialogResult
    )
    $sResultType = "DialogResult.Scriptblock"
    $hResult = @{
        Type = "Scriptblock"
        Value = $Value
        DialogResult = $DialogResult
    }
    $hResult.PSTypeNames.Insert(0, $sResultType)
    return $hResult
}
