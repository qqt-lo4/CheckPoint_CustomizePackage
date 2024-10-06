function Get-ScriptRegion {
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$regionName,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile,
        [Parameter(ParameterSetName = "Script")]
        [Parameter(ParameterSetName = "File")]
        [object]$inputFileEncoding
    )
    $scriptContent = switch ($PSCmdlet.ParameterSetName) {
        "Script" {
            if ($powershellScript -is [string]) {
                $powershellScript -split "`n"
            } elseif ($powershellScript -is [array]) {
                $powershellScript
            }
        }
        "File" {
            if ($inputFileEncoding) {Get-Content $powershellFile -Encoding $inputFileEncoding} else {Get-Content $powershellFile}
        }
    }
    $region_start_found = $false
    $region_end_found = $false
    $regionContent = @()
    foreach ($line in $scriptContent) {
        if ($line.Trim().ToLower() -eq $("#region " + $regionName.ToLower())) {
            $region_start_found = $true
            continue
        } 
        if ($line.Trim().ToLower() -eq $("#endregion " + $regionName.ToLower())) {
            $region_end_found = $true
            continue
        }
        if ($region_start_found -and (-not $region_end_found)) {
            $regionContent += $line
        }
    }
    return $regionContent
}