function Update-ScriptRegion {
    <#
    .SYNOPSIS
        Replaces content in a named script region

    .DESCRIPTION
        Replaces all content between #region and #endregion markers with new content.
        The region markers themselves are preserved.

    .PARAMETER regionName
        Name of the region to replace.

    .PARAMETER newRegionValue
        New content to insert in the region (string or array).

    .PARAMETER powershellScript
        PowerShell script content as string or array.

    .PARAMETER powershellFile
        Path to PowerShell script file.

    .OUTPUTS
        [String[]]. Modified script content with replaced region.

    .EXAMPLE
        Update-ScriptRegion -powershellFile "C:\Scripts\MyScript.ps1" -regionName "config" -newRegionValue $newConfig

    .EXAMPLE
        $updated = Update-ScriptRegion -powershellScript $content -regionName "settings" -newRegionValue "# New settings"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$regionName,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "File")]
        [object]$newRegionValue,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile
    )
    $newScriptContent = @()
    $oldContent = switch ($PSCmdlet.ParameterSetName) {
        "Script" {
            if ($powershellScript -is [string]) {
                $powershellScript -split "`n"
            } elseif ($powershellScript -is [array]) {
                $powershellScript
            }
        }
        "File" {
            Get-Content $powershellFile
        }
    }
    $region_start_found = $false
    $region_end_found = $false
    $replaced_lines_added = $false
    foreach ($line in $oldContent) {
        if ($line.Trim().ToLower() -eq $("#region " + $regionName.ToLower())) {
            $region_start_found = $true
            $newScriptContent += $line
            continue
        } 
        if ($line.Trim().ToLower() -eq $("#endregion " + $regionName.ToLower())) {
            $region_end_found = $true
            $newScriptContent += $line
            continue
        }
        if ($region_start_found) {
            if ($region_end_found) {
                $newScriptContent += $line
            } else {
                if (-not $replaced_lines_added) {
                    $newRegionLines = if ($newRegionValue -is [string]) {
                        $newRegionValue -split "`n"
                    } elseif ($newRegionValue -is [array]) {
                        $newRegionValue
                    }
                    foreach ($newline in $newRegionLines) {
                        $newScriptContent += $newline
                    }
                    $replaced_lines_added = $true        
                }
            }
        } else {
            $newScriptContent += $line
        }
    }
    return $newScriptContent
}
