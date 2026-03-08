function Resolve-PathWithVariables {
    <#
    .SYNOPSIS
        Resolves a path containing variables

    .DESCRIPTION
        Expands environment variables, datetime patterns (%d:format%), and custom hashtable
        variables in a path string. Supports Machine, User, and Process environment variables.

    .PARAMETER Path
        Path containing variables to resolve.

    .PARAMETER EnvironmentVariableTarget
        Specific environment variable target to prioritize.

    .PARAMETER Hashtable
        Custom variables as hashtable for replacement.

    .OUTPUTS
        [String]. Path with all variables expanded.

    .EXAMPLE
        Resolve-PathWithVariables -Path "%TEMP%\log_%d:yyyyMMdd%.txt"

    .EXAMPLE
        Resolve-PathWithVariables -Path "%CUSTOMVAR%\file.txt" -Hashtable @{CUSTOMVAR="C:\MyPath"}

    .EXAMPLE
        Resolve-PathWithVariables -Path "%PSScriptRoot%\config.json"

    .EXAMPLE
        Resolve-PathWithVariables -Path "%PSScriptRoot%\..\data\file.txt" -ToAbsolute

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [Parameter(Position = 1)]
        [System.EnvironmentVariableTarget]$EnvironmentVariableTarget,
        [hashtable]$Hashtable,
        [switch]$ToAbsolute
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

    # Replace %PSScriptRoot% with $PSScriptRoot
    if ($sResult -like "*%PSScriptRoot%*") {
        $sResult = $sResult -ireplace "%PSScriptRoot%", $PSScriptRoot
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

    # Resolve to absolute path if requested
    if ($ToAbsolute) {
        $sResult = Resolve-RelativePath -From (Get-Location).Path -To $sResult
    }

    # return $result
    return $sResult
}