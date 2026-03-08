function Get-RootScriptConfigFile {
    <#
    .SYNOPSIS
        Locates a configuration file in the script hierarchy

    .DESCRIPTION
        Searches for a config file in multiple locations: script root,
        dev config folder with script name, and dev config folder root.

    .PARAMETER configFileName
        Name of the config file to find (default: "config.json").

    .PARAMETER devConfigFolderName
        Name of the dev config subfolder (default: "input").

    .OUTPUTS
        [String]. Path to the config file, or empty string if not found.

    .EXAMPLE
        $configPath = Get-RootScriptConfigFile

    .EXAMPLE
        $configPath = Get-RootScriptConfigFile -configFileName "settings.json"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$configFileName = "config.json",
        [string]$devConfigFolderName = "input"
    )
    $rootScriptPath = Get-RootScriptPath
    $rootScriptName = Get-RootScriptName 
    if (Test-Path -Path ($rootScriptPath + "\" + $configFileName) -PathType Leaf) {
        return $rootScriptPath + "\" + $configFileName
    } elseif (Test-Path -Path ($rootScriptPath + "\" + $devConfigFolderName + "\" + $rootScriptName + "\" + $configFileName) -PathType Leaf) {
        return $rootScriptPath + "\" + $devConfigFolderName + "\" + $rootScriptName + "\" + $configFileName
    } elseif (Test-Path -Path ($rootScriptPath + "\" + $devConfigFolderName + "\" + $configFileName) -PathType Leaf) {
        return $rootScriptPath + "\" + $devConfigFolderName + "\" + $configFileName
    } else {
        return ""
    }
}
