function Get-RootScriptConfigFile {
    <#
    .SYNOPSIS
        Locates a configuration file in the script hierarchy

    .DESCRIPTION
        Searches for a config file in multiple locations (input directory, script root,
        AppData, ProgramData) and returns the resolved file path.
        For each location, searches directly and in a subfolder named after the root script.

    .PARAMETER ConfigFileName
        Name of the config file to find (default: "config.json").

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
        [String]. Path to the config file, or empty string if not found.

    .EXAMPLE
        $configPath = Get-RootScriptConfigFile

    .EXAMPLE
        $configPath = Get-RootScriptConfigFile -ConfigFileName "settings.json" -AppData

    .EXAMPLE
        $configPath = Get-RootScriptConfigFile -ConfigFilePath "%PSScriptRoot%\myconfig.json"

    .NOTES
        Author  : Loïc Ade
        Version : 2.0.0

        1.0.0 - Initial version
        1.1.0 (2026-03-10)
            - Uses Get-RootScriptInfo instead of Get-RootScriptPath and Get-RootScriptName
            - Uses Get-ScriptDir -InputDir instead of devConfigFolderName parameter
        2.0.0 (2026-03-14)
            - Merged search logic from Get-ScriptConfig
            - Added ConfigFilePath, ScriptRoot, InputDir, AppData, ProgramData parameters
            - Multi-location search with fallback
    #>

    Param(
        [string]$ConfigFileName = "config.json",
        [AllowNull()]
        [string]$ConfigFilePath,
        [switch]$ScriptRoot,
        [switch]$InputDir,
        [switch]$AppData,
        [switch]$ProgramData
    )
    Begin {
        $rootInfo = Get-RootScriptInfo
        $aFoldersToTest = @()
        if ((-not $AppData) -and (-not $ProgramData) -and (-not $ScriptRoot) -and (-not $InputDir)) {
            $aFoldersToTest += "InputDir"
        } else {
            $aLocationSwitches = @("InputDir", "ScriptRoot", "AppData", "ProgramData")
            foreach ($item in $PSBoundParameters.Keys) {
                if (($PSBoundParameters[$item] -is [switch]) -and ($PSBoundParameters[$item] -eq $true) -and ($item -in $aLocationSwitches)) {
                    $aFoldersToTest += $item
                }
            }
        }
        function Test-ConfigFileInFolder {
            Param(
                [string]$ConfigFileName,
                [string]$FolderPath
            )
            if (Test-Path -Path ($FolderPath + "\" + $ConfigFileName) -PathType Leaf) {
                return $FolderPath + "\" + $ConfigFileName
            } elseif (Test-Path -Path ($FolderPath + "\" + $rootInfo.Name + "\" + $ConfigFileName) -PathType Leaf) {
                return $FolderPath + "\" + $rootInfo.Name + "\" + $ConfigFileName
            } else {
                return ""
            }
        }
    }
    Process {
        if (-not [string]::IsNullOrEmpty($ConfigFilePath)) {
            $sResolvedPath = Resolve-PathWithVariables -Path $ConfigFilePath
            if (Test-Path -Path $sResolvedPath -PathType Leaf) {
                return $sResolvedPath
            }
            return $sResolvedPath
        }

        $sDefaultFilePath = ""
        foreach ($sFolderToTest in $aFoldersToTest) {
            $sFolderPath = switch ($sFolderToTest) {
                "ScriptRoot" { $rootInfo.Directory }
                "InputDir" { (Get-ScriptDir -InputDir) }
                "AppData" { $env:APPDATA }
                "ProgramData" { $env:ProgramData }
            }
            if ($sDefaultFilePath -eq "") {
                $sDefaultFilePath = $sFolderPath + "\" + $ConfigFileName
            }
            $sConfigFilePath = Test-ConfigFileInFolder -ConfigFileName $ConfigFileName -FolderPath $sFolderPath
            if ($sConfigFilePath -ne "") {
                return $sConfigFilePath
            }
        }
        return $sDefaultFilePath
    }
}
