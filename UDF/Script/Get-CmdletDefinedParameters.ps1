function Get-CmdletDefinedParameters {
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