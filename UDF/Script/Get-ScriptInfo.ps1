function Get-ScriptInfo {
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile
    )
    $strRegion = Get-ScriptRegion @PSBoundParameters -regionName "script info"
    $result = @{}
    foreach ($line in $strRegion) {
        if ($line -match "^#([^=]+)=(.+)$") {
            $result.Add($Matches.1, $Matches.2)
        }
    }
    return $result
}
