function Get-RootScriptConfigFile {
    Param(
        [string]$configFileName = "config.json",
        [string]$devConfigFolderName = "input"
    )
    $rootScriptPath = Get-RootScriptPath
    $rootScriptName = Get-RootScriptName 
    if (Test-Path -Path ($rootScriptPath + $configFileName) -PathType Leaf) {
        return $rootScriptPath + $configFileName
    } elseif (Test-Path -Path ($rootScriptPath + $devConfigFolderName + "\" + $rootScriptName + "\" + $configFileName) -PathType Leaf) {
        return $rootScriptPath + $devConfigFolderName + "\" + $rootScriptName + "\" + $configFileName
    } elseif (Test-Path -Path ($rootScriptPath + $devConfigFolderName + "\" + $configFileName) -PathType Leaf) {
        return $rootScriptPath + $devConfigFolderName + "\" + $configFileName
    } else {
        return ""
    }
}
