function Get-ScriptCommentRegion {
    <#
    .SYNOPSIS
        Extracts comments from a script region

    .DESCRIPTION
        Gets all comment content (block comments or line comments) from a named
        region in a PowerShell script.

    .PARAMETER regionName
        Name of the region to extract comments from.

    .PARAMETER powershellScript
        PowerShell script content as string or array.

    .PARAMETER powershellFile
        Path to PowerShell script file.

    .OUTPUTS
        [String[]]. Array of comment text lines.

    .EXAMPLE
        Get-ScriptCommentRegion -powershellFile "C:\Scripts\MyScript.ps1" -regionName "usage"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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