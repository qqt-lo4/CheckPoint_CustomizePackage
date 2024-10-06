function Get-ScriptRegions {
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

