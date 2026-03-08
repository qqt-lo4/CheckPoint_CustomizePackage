function Get-ScriptRegions {
    <#
    .SYNOPSIS
        Gets all region names from a PowerShell script

    .DESCRIPTION
        Extracts all #region names from a PowerShell script. Accepts script content as
        an array, string, or file path. Optionally filters results.

    .PARAMETER PowershellScript
        PowerShell script content as array, string, or file path.

    .PARAMETER Filter
        Optional filter to apply to region names.

    .OUTPUTS
        [String[]]. Array of region names found in the script.

    .EXAMPLE
        Get-ScriptRegions -PowershellScript "C:\Scripts\MyScript.ps1"

    .EXAMPLE
        Get-ScriptRegions -PowershellScript $scriptContent -Filter {$_ -like "config*"}

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$PowershellScript,
        [Parameter(Position = 1)]
        [object]$Filter
    )
    $scriptContent = if ($PowershellScript -is [array]) {
        $powershellScript
    } else {
        if ($powershellScript -is [string]) {
            if ($PowershellScript.Contains("`n")) {
                $powershellScript -split "`n"
            } else {
                Get-Content $PowershellScript    
            }
        } else {
            throw "Unsupported type"
        }
    }
    
    $result = @()
    foreach ($line in $scriptContent) {
        if ($line -match "^(\t\s)*#region\s+(?<regionname>.*)(`r?`n)?$") {
            $result += $Matches.regionname
        }
    }
    if ($Filter) {
        return $result | Where-Object $Filter
    } else {
        return $result
    }
}

