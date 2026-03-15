function New-CLIDialogWizardStep {
    <#
    .SYNOPSIS
        Creates a step definition for Invoke-CLIDialogWizard.

    .DESCRIPTION
        Defines a single step in a CLI dialog wizard. Each step contains a scriptblock
        that displays a dialog and returns a DialogResult. The result value is stored
        in the output object under the specified PropertyName.

    .PARAMETER PropertyName
        Name of the property in the output object where the step result will be stored.

    .PARAMETER ScriptBlock
        ScriptBlock that displays the dialog for this step. Receives the current output
        object as parameter. Must return a DialogResult (Value, Action.Back, or Action.Exit).

    .PARAMETER Header
        Optional header text displayed before the step.

    .OUTPUTS
        [Hashtable] with PSTypeName "CLIDialogWizardStep".

    .EXAMPLE
        New-CLIDialogWizardStep -PropertyName "Server" -ScriptBlock {
            param($result)
            Read-CLIDialogValidatedValue -Header "Enter server name" -PropertyName "Server"
        }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-14)
            - Initial release
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$PropertyName,
        [Parameter(Mandatory, Position = 1)]
        [scriptblock]$ScriptBlock,
        [string]$Header
    )
    $hStep = @{
        PropertyName = $PropertyName
        ScriptBlock  = $ScriptBlock
        Header       = $Header
    }
    $hStep.PSTypeNames.Insert(0, "CLIDialogWizardStep")
    return $hStep
}
