function Get-ScriptCommentRegion {
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$regionName,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile
    )
    $scriptContent = (Get-ScriptRegion @PSBoundParameters) -join "`r`n"
    $scriptContentMatches = $scriptContent | Select-String -Pattern "<#((((?!#>).)*|`r`n)*)#>" -AllMatches
    if ($scriptContentMatches.Matches.Count -ge 1) {
        $result = @()
        foreach ($m in $scriptContentMatches.Matches) {
            $result += $m.Groups[1].Value
        }
        return $result 
    }
    $result = @()
    foreach ($item in $scriptContent.Split("`r`n")) {
        if ($item -match "^(\t\s)*#(.*)$") {
            $result += $Matches.2
        }
    }
    return $result
}

#. G:\Scripts\PowerShell\UDF\Script\Get-ScriptRegion.ps1
#$o = Get-ScriptCommentRegion -powershellFile "G:\Scripts\PowerShell\Set-McAfeePolicyForWinUpgrade.ps1" -regionName "usage"
#$o