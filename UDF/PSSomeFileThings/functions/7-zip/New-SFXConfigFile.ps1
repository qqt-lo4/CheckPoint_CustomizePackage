function New-SFXConfigFile {
    <#
    .SYNOPSIS
        Creates a configuration file for 7-Zip SFX archives

    .DESCRIPTION
        Generates a configuration file that defines SFX archive behavior including window title,
        file to execute after extraction, parameters, and progress display settings.

    .PARAMETER Title
        Title displayed in the SFX extraction window.

    .PARAMETER ExecuteFile
        File to execute after extraction.

    .PARAMETER ExecuteParameters
        Parameters to pass to the executed file.

    .PARAMETER Progress
        Show progress during extraction ("yes" or "no", default: "yes").

    .PARAMETER OutFilePath
        Path where the configuration file will be saved.

    .OUTPUTS
        None. Creates a UTF-8 encoded SFX configuration file.

    .EXAMPLE
        New-SFXConfigFile -Title "My Installer" -ExecuteFile "setup.exe" -ExecuteParameters "/silent" -OutFilePath "config.txt"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string]$ExecuteFile,
        [Parameter(Mandatory)]
        [string]$ExecuteParameters,
        [ValidateSet('yes', 'no')]
        [string]$Progress = "yes",
        [Parameter(Mandatory)]
        [string]$OutFilePath
    )
    $aSfxconfig = @(";!@Install@!UTF-8!Title=", 
                    $Title, 
                    "ExecuteFile=", 
                    $ExecuteFile, 
                    "ExecuteParameters=", 
                    $ExecuteParameters, 
                    "Progress=",
                    "$Progress",
                    ";!@InstallEnd@!"
    )
    $sfxConfig = $aSfxconfig -join """" 
    $sfxConfig | Out-File -FilePath $OutFilePath -Encoding utf8
}