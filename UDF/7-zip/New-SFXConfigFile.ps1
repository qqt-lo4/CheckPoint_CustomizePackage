function New-SFXConfigFile {
    Param(
        [Parameter(Mandatory)]
        [string]$Title,
        [Parameter(Mandatory)]
        [string]$ExecuteFile,
        [Parameter(Mandatory)]
        [string]$ExecuteParameters,
        [Parameter(Mandatory)]
        [string]$OutFilePath
    )
    $aSfxconfig = @(";!@Install@!UTF-8!Title=", 
                    $Title, 
                    "ExecuteFile=", 
                    $ExecuteFile, 
                    "ExecuteParameters=", 
                    $ExecuteParameters, 
                    ";!@InstallEnd@!"
    )
    $sfxConfig = $aSfxconfig -join """" 
    $sfxConfig | Out-File -FilePath $OutFilePath -Encoding utf8
}