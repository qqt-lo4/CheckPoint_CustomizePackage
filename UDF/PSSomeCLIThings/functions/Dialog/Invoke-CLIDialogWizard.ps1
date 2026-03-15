function Invoke-CLIDialogWizard {
    <#
    .SYNOPSIS
        Manages a succession of CLI dialog steps to build an object.

    .DESCRIPTION
        Iterates through an ordered list of dialog steps (created with New-CLIDialogWizardStep),
        executing each step's scriptblock. Supports Back navigation to return to the previous step
        and Exit to quit. The result of each step is stored in an output object under the step's
        PropertyName.

    .PARAMETER Steps
        Array of wizard step definitions created with New-CLIDialogWizardStep.

    .PARAMETER InitialObject
        Optional initial object to pre-populate properties. Properties from completed steps
        will be merged into this object.

    .PARAMETER HeaderForegroundColor
        Foreground color for step headers. Default: Green.

    .OUTPUTS
        [PSCustomObject] containing all collected properties, or $null if the user exits.

    .EXAMPLE
        $steps = @(
            New-CLIDialogWizardStep -PropertyName "Server" -Header "Step 1/3" -ScriptBlock {
                param($result)
                Read-CLIDialogValidatedValue -Header "Enter server name" -PropertyName "Server" -AllowCancel
            }
            New-CLIDialogWizardStep -PropertyName "Port" -Header "Step 2/3" -ScriptBlock {
                param($result)
                Read-CLIDialogNumericValue -Header "Enter port" -PropertyName "Port" -AllowCancel
            }
            New-CLIDialogWizardStep -PropertyName "Credential" -Header "Step 3/3" -ScriptBlock {
                param($result)
                Read-CLIDialogCredential -Header "Enter credentials"
            }
        )
        $config = Invoke-CLIDialogWizard -Steps $steps

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        DIALOG RESULT HANDLING:
        Each step's scriptblock must return one of the following:
        - A DialogResult with a Value (stored in the output object, moves to next step)
        - A DialogResult.Action.Back (returns to previous step, or exits if on first step)
        - A DialogResult.Action.Exit (exits the wizard, returns $null)
        - $null (treated as Cancel/Back)
        - Any other value is stored directly as the property value

        BACK NAVIGATION:
        When the user navigates back, the previous step is re-displayed.
        The output object retains values from previously completed steps,
        allowing the scriptblock to use them as defaults.

        1.0.0 (2026-03-14)
            - Initial release
    #>
    Param(
        [Parameter(Mandatory)]
        [array]$Steps,
        [object]$InitialObject,
        [System.ConsoleColor]$HeaderForegroundColor = [System.ConsoleColor]::Green
    )
    Process {
        $hResult = if ($InitialObject) {
            if ($InitialObject -is [hashtable]) {
                $InitialObject.Clone()
            } else {
                $hConverted = @{}
                $InitialObject.PSObject.Properties | ForEach-Object { $hConverted[$_.Name] = $_.Value }
                $hConverted
            }
        } else {
            @{}
        }

        $iCurrentStep = 0
        while ($iCurrentStep -lt $Steps.Count) {
            $oStep = $Steps[$iCurrentStep]

            if ($oStep.Header) {
                Write-Host $oStep.Header -ForegroundColor $HeaderForegroundColor
            }

            $oStepResult = & $oStep.ScriptBlock $hResult

            # Handle DialogResult.Action.Exit
            if ($oStepResult -and $oStepResult.PSTypeNames -and $oStepResult.PSTypeNames[0] -eq "DialogResult.Action.Exit") {
                return $oStepResult
            }

            # Handle DialogResult.Action.Back
            if ($oStepResult -and $oStepResult.PSTypeNames -and $oStepResult.PSTypeNames[0] -eq "DialogResult.Action.Back") {
                if ($iCurrentStep -eq 0) {
                    return $oStepResult
                }
                $iCurrentStep--
                continue
            }

            # Extract value from DialogResult or use raw value
            $oValue = if ($oStepResult -and $oStepResult.PSTypeNames -and $oStepResult.PSTypeNames[0] -eq "DialogResult.Value") {
                $oStepResult.Value
            } else {
                $oStepResult
            }

            $hResult[$oStep.PropertyName] = $oValue
            $iCurrentStep++
        }

        $oOutput = New-Object -TypeName PSCustomObject -Property $hResult
        return $oOutput
    }
}
