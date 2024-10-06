function Resolve-PathWithVariables {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [Parameter(Position = 1)]
        [System.EnvironmentVariableTarget]$EnvironmentVariableTarget,
        [hashtable]$Hashtable
    )
    $sResult = $Path
    # Replace environment variables
    $aTargets = @()
    if ($EnvironmentVariableTarget) {
        $aTargets += $EnvironmentVariableTarget
    }
    $aTargets += "Machine", "User", "Process"

    foreach ($target in $aTargets) {
        $hEnvVariables = [System.Environment]::GetEnvironmentVariables($target)
        foreach ($variable in $hEnvVariables.Keys) {
            if ($sResult -like ("*%" + $variable + "%*")) {
                $sResult = $sResult -replace ("%" + $variable + "%"), $hEnvVariables[$variable]
            }
        }
    }

    # Replace datetime variables
    $aDateMatches = $sResult | Select-String "%d:([^%]+)%" -AllMatches
    foreach ($m in $aDateMatches.matches) {
        $sResult = $sResult -replace $m.Value, (Get-Date -Format $m.Groups[1].Value)
    }

    # Replace variables included in $Hashtable
    foreach ($key in $Hashtable.Keys) {
        $sResult = $sResult -ireplace ("%" + $key + "%"), $Hashtable[$key]
    }

    # return $result
    return $sResult
}