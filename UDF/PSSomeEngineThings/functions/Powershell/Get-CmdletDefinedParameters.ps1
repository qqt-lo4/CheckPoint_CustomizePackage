function Get-CmdletDefinedParameters {
    <#
    .SYNOPSIS
        Gets all defined parameters for a cmdlet

    .DESCRIPTION
        Extracts all parameter names from a cmdlet's parameter sets, excluding common parameters
        like WhatIf and Confirm. Returns unique parameter names.

    .PARAMETER CmdLet
        The cmdlet object to analyze.

    .OUTPUTS
        [String[]]. Array of unique parameter names.

    .EXAMPLE
        Get-CmdletDefinedParameters -CmdLet (Get-Command Get-Process)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$CmdLet 
    )
    $result = @()
    foreach ($parameterset in $CmdLet.ParameterSets) {
        $aParameters = $parameterset.ToString().Split(" ") -match "-([a-z-A-Z0-9]+)" | ForEach-Object { if ($_ -match "-([a-z-A-Z0-9]+)") { $Matches.1 }}
        $aParameters = $aParameters | Where-Object { ($_ -ne "WhatIf") -and ($_ -ne "Confirm")}
        foreach ($sParameterName in $aParameters) {
            $result += $sParameterName
        }
    }
    return $result | Select-Object -Unique
}