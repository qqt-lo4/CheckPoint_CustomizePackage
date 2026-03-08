function Remove-ScriptRegion {
    <#
    .SYNOPSIS
        Removes a named region from a PowerShell script

    .DESCRIPTION
        Removes all content between #region and #endregion markers for a specified region name,
        including the markers themselves. Can process script content or modify a file directly.

    .PARAMETER PowershellScript
        PowerShell script content as array, string, or file path.

    .PARAMETER RegionName
        Name of the region to remove.

    .OUTPUTS
        [String[]]. Modified script content (when input is array or string content).
        Writes directly to file when input is file path.

    .EXAMPLE
        Remove-ScriptRegion -PowershellScript "C:\Scripts\MyScript.ps1" -RegionName "deprecated"

    .EXAMPLE
        $modifiedScript = Remove-ScriptRegion -PowershellScript $scriptContent -RegionName "temp"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$PowershellScript,
        [Parameter(Mandatory, Position = 1)]
        [string]$RegionName
    )
    $newScriptContent = @()
    $aScriptContent, $sMode = if ($PowershellScript -is [array]) {
        $powershellScript, "Script"
    } else {
        if ($powershellScript -is [string]) {
            if ($PowershellScript.Contains("`n")) {
                ($powershellScript -split "`n"), "Script"
            } else {
                (Get-Content $PowershellScript | Foreach-Object {$_ -replace "\xEF\xBB\xBF", ""} ), "File"
            }
        } else {
            throw "Unsupported type"
        }
    }
    $region_start_found = $false
    $region_end_found = $false

    foreach ($line in $aScriptContent) {
        if ($line.Trim().ToLower() -eq $("#region " + $regionName.ToLower())) {
            $region_start_found = $true
            continue
        } 
        if ($line.Trim().ToLower() -eq $("#endregion " + $regionName.ToLower())) {
            $region_end_found = $true
            continue
        }
        if ($region_start_found) {
            if ($region_end_found) {
                $newScriptContent += $line
            }
        } else {
            $newScriptContent += $line
        }
    }
    if ($sMode -eq "File") {
        $UTF8_with_BOM = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllLines($PowershellScript, $newScriptContent, $UTF8_with_BOM)
    } else {
        return $newScriptContent
    }
}
