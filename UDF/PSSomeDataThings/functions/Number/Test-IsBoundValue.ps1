function Test-IsBoundValue {
    <#
    .SYNOPSIS
        Tests if a numeric value equals the type's min or max boundary

    .DESCRIPTION
        Checks whether a value equals its type's MinValue or MaxValue
        (e.g., [int]::MinValue, [int64]::MaxValue).

    .PARAMETER Var
        The numeric value to test

    .PARAMETER MinValue
        Check against the type's MinValue

    .PARAMETER MaxValue
        Check against the type's MaxValue

    .OUTPUTS
        System.Boolean. True if the value equals the type boundary.

    .EXAMPLE
        Test-IsBoundValue -Var ([int]::MaxValue) -MaxValue
        # Returns: True

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Var,
        [Parameter(Mandatory, ParameterSetName = "Min")]
        [switch]$MinValue,
        [Parameter(Mandatory, ParameterSetName = "Max")]
        [switch]$MaxValue
    )
    $oType = $Var.GetType()
    try {
        $TypeBound = Invoke-Expression ("[" + $oType.Name + "]::" + $PSCmdlet.ParameterSetName + "Value")
        return $Var -eq $TypeBound
    } catch {
        return $false
    }
}