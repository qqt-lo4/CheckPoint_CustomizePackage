function Get-ScriptConfig {
    <#
    .SYNOPSIS
        Loads configuration from a JSON file with fallback search locations

    .DESCRIPTION
        Locates a JSON config file using Get-RootScriptConfigFile and returns its contents
        as a PSObject or hashtable.

    .PARAMETER ConfigFileName
        Name of the config file (default: "config.json").

    .PARAMETER ToHashtable
        Return as hashtable instead of PSObject.

    .PARAMETER ConfigFilePath
        Direct path to a config file. Supports variables resolved by Resolve-PathWithVariables.
        If provided and non-empty, skips the folder search entirely.

    .PARAMETER ScriptRoot
        Search in the script root directory.

    .PARAMETER InputDir
        Search in the input directory resolved by Get-ScriptDir -InputDir.

    .PARAMETER AppData
        Search in the user's AppData directory.

    .PARAMETER ProgramData
        Search in the ProgramData directory.

    .OUTPUTS
        [PSObject] or [Hashtable]. Configuration data, or $null if not found.

    .EXAMPLE
        $config = Get-ScriptConfig

    .EXAMPLE
        $config = Get-ScriptConfig -ConfigFileName "settings.json" -AppData -ToHashtable

    .EXAMPLE
        $config = Get-ScriptConfig -ConfigFilePath "%PSScriptRoot%\myconfig.json"

    .NOTES
        Author  : Loïc Ade
        Version : 2.0.0

        1.0.0 - Initial version. Config file search in ScriptRoot, AppData, ProgramData.
        1.1.0 (2026-03-03) - Added -ConfigFilePath parameter with Resolve-PathWithVariables support.
                           - Added -PathOnly parameter to return the resolved file path only.
        1.2.0 (2026-03-09) - Added -InputDir parameter to search in Get-ScriptDir -InputDir location.
                           - Removed -DevConfigFolderName parameter (replaced by -InputDir).
        1.3.0 (2026-03-10) - Uses Get-RootScriptInfo instead of Get-RootScriptName and Get-RootScriptPath.
        2.0.0 (2026-03-14) - Delegates file search to Get-RootScriptConfigFile.
                           - Removed -PathOnly parameter (use Get-RootScriptConfigFile directly).
    #>

    Param(
        [string]$ConfigFileName = "config.json",
        [switch]$ToHashtable,
        [AllowNull()]
        [string]$ConfigFilePath,
        [switch]$ScriptRoot,
        [switch]$InputDir,
        [switch]$AppData,
        [switch]$ProgramData
    )
    Process {
        $params = @{ ConfigFileName = $ConfigFileName }
        if ($ConfigFilePath) { $params.ConfigFilePath = $ConfigFilePath }
        if ($ScriptRoot) { $params.ScriptRoot = $true }
        if ($InputDir) { $params.InputDir = $true }
        if ($AppData) { $params.AppData = $true }
        if ($ProgramData) { $params.ProgramData = $true }

        $sConfigFilePath = Get-RootScriptConfigFile @params

        if ($sConfigFilePath -ne "" -and (Test-Path -Path $sConfigFilePath -PathType Leaf)) {
            $oResult = Get-Content -Path $sConfigFilePath | ConvertFrom-Json
            if ($ToHashtable) {
                $oResult = $oResult | ConvertTo-Hashtable
            }
            return $oResult
        }
        return $null
    }
}
