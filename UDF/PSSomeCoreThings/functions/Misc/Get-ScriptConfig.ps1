function Get-ScriptConfig {
    <#
    .SYNOPSIS
        Loads configuration from a JSON file with fallback search locations

    .DESCRIPTION
        Searches for a JSON config file in multiple locations (script root, AppData,
        ProgramData) and returns its contents as a PSObject or hashtable.

    .PARAMETER ConfigFileName
        Name of the config file (default: "config.json").

    .PARAMETER ToHashtable
        Return as hashtable instead of PSObject.

    .PARAMETER DevConfigFolderName
        Dev config subfolder name (default: "input").

    .PARAMETER ScriptRoot
        Search in the script root directory.

    .PARAMETER AppData
        Search in the user's AppData directory.

    .PARAMETER ProgramData
        Search in the ProgramData directory.

    .OUTPUTS
        [PSObject] or [Hashtable]. Configuration data.

    .EXAMPLE
        $config = Get-ScriptConfig

    .PARAMETER ConfigFilePath
        Direct path to a config file. Supports variables resolved by Resolve-PathWithVariables.
        If provided and non-empty, skips the folder search entirely.

    .PARAMETER PathOnly
        Returns only the resolved config file path instead of its content.

    .EXAMPLE
        $config = Get-ScriptConfig -ConfigFileName "settings.json" -AppData -ToHashtable

    .EXAMPLE
        $config = Get-ScriptConfig -ConfigFilePath "%PSScriptRoot%\myconfig.json"

    .EXAMPLE
        $path = Get-ScriptConfig -PathOnly

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        1.0.0 - Initial version. Config file search in ScriptRoot, AppData, ProgramData.
        1.1.0 (2026-03-03) - Added -ConfigFilePath parameter with Resolve-PathWithVariables support.
                           - Added -PathOnly parameter to return the resolved file path only.
    #>

    Param(
        [string]$ConfigFileName = "config.json",
        [switch]$ToHashtable,
        [string]$DevConfigFolderName = "input",
        [string]$ConfigFilePath,
        [switch]$PathOnly,
        [switch]$ScriptRoot,
        [switch]$AppData,
        [switch]$ProgramData
    )
    Begin {
        $sRootScriptName = Get-RootScriptName 
        $aFoldersToTest = @()
        if ((-not $AppData) -and (-not $ProgramData) -and (-not $ScriptRoot)) {
            $aFoldersToTest += "ScriptRoot"
        } else {
            foreach ($item in $PSBoundParameters.Keys) {
                if (($PSBoundParameters[$item] -is [switch]) -and ($PSBoundParameters[$item] -eq $true)) {
                    $aFoldersToTest += $item
                }
            }
        }
        function Test-GetScriptConfig {
            Param(
                [string]$ConfigFileName,
                [string]$DevConfigFolderName,
                [string]$FolderPath
            )
            $sResult = if (Test-Path -Path ($FolderPath + $ConfigFileName) -PathType Leaf) {
                $FolderPath + $ConfigFileName
            } elseif (Test-Path -Path ($FolderPath + $DevConfigFolderName + "\" + $sRootScriptName + "\" + $ConfigFileName) -PathType Leaf) {
                $FolderPath + $DevConfigFolderName + "\" + $sRootScriptName + "\" + $ConfigFileName
            } elseif (Test-Path -Path ($FolderPath + $DevConfigFolderName + "\" + $ConfigFileName) -PathType Leaf) {
                $FolderPath + $DevConfigFolderName + "\" + $ConfigFileName
            } elseif (Test-Path -Path ($FolderPath + $sRootScriptName + "\" + $DevConfigFolderName + "\" + $ConfigFileName) -PathType Leaf) {
                $FolderPath + $sRootScriptName + "\" + $DevConfigFolderName + "\" + $ConfigFileName
            } elseif (Test-Path -Path ($FolderPath + $sRootScriptName + "\" + $ConfigFileName) -PathType Leaf) {
                $FolderPath + $sRootScriptName + "\" + $ConfigFileName
            } else {
                ""
            }
            return $sResult
        }
    }
    Process {
        $sConfigFilePath = ""
        $sDefaultFilePath = ""
        if (-not [string]::IsNullOrEmpty($ConfigFilePath)) {
            $sResolvedPath = Resolve-PathWithVariables -Path $ConfigFilePath
            $sDefaultFilePath = $sResolvedPath
            if (Test-Path -Path $sResolvedPath -PathType Leaf) {
                $sConfigFilePath = $sResolvedPath
            }
        } else {
            foreach ($sFolderToTest in $aFoldersToTest) {
                $sFolderPath = switch ($sFolderToTest) {
                    "ScriptRoot" { Get-RootScriptPath }
                    "AppData" { $env:APPDATA + "\"}
                    "ProgramData" { $env:ProgramData + "\"}
                }
                if ($sDefaultFilePath -eq "") {
                    $sDefaultFilePath = $sFolderPath + $ConfigFileName
                }
                $sConfigFilePath = Test-GetScriptConfig -ConfigFileName $ConfigFileName -DevConfigFolderName $DevConfigFolderName -FolderPath $sFolderPath
                if ($sConfigFilePath -ne "") {
                    break
                }
            }
        }
    }
    End {
        if ($sConfigFilePath -ne "") {
            if ($PathOnly) {
                return $sConfigFilePath
            }
            $oResult = Get-Content -Path $sConfigFilePath | ConvertFrom-Json
            if ($ToHashtable) {
                $oResult = $oResult | ConvertTo-Hashtable
            }
            return $oResult
        } else {
            if ($PathOnly) {
                return $sDefaultFilePath
            }
            return $null
        }
    }
}
