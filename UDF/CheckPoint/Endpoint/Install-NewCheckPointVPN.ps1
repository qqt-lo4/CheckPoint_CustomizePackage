function Install-NewCheckPointVPN {
    Param(
        [Parameter(Mandatory)]
        [Alias("SetupFile")]
        [object]$msipath,
        [ValidateSet("EN", "FR", "JP", "ES", "IT", "DE", "PT", "RU", "CS", "EL", "PL", "")]
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$language,
        [AllowEmptyString()]
        [string]$uninstPasswd,
        [AllowEmptyString()]
        [string]$SDL_ENABLED,
        [AllowEmptyString()]
        [string]$FIXED_MAC
    )
    $oSetupFile =  if ($msipath -is [System.IO.FileInfo]) {
        $msipath
    } else {
        Get-Item $msipath
    }
    $oSetupType = $oSetupFile.Extension.ToUpper() -replace "\.", ""
    $arguments = @()
    if ($oSetupType -eq "EXE") {
        $command = $oSetupFile
    } else {
        $sFilePath = $oSetupFile.FullName
        $command = [System.Environment]::SystemDirectory + "\msiexec.exe"
        $arguments += "/i"
        $arguments += "`"$sFilePath`""
        $arguments += "/quiet"
        
    }
    $arguments += "/norestart"
    if ($uninstPasswd) {
        $arguments += $("UNINST_PASSWORD=" + $uninstPasswd)
    }
    if ($SDL_ENABLED -and ($SDL_ENABLED -ne "")) {
        $arguments += "SDL_ENABLED=$SDL_ENABLED"
    }
    if ($FIXED_MAC -and ($FIXED_MAC -ne "")) {
        $arguments += "FIXED_MAC=$FIXED_MAC"
    }
    if ($language -ne "") {
        $languageHashtable = @{
            EN = 1033
            FR = 1036
            ES = 1034
            JP = 1041
            DE = 1031
            IT = 1040
            EL = 1032
            PL = 1045
            RU = 1049
            PT = 2070
            CS = 1029
        }
        $languageParameter = if ($language -eq "") { "" } else { $languageHashtable[$language] }
        $arguments += $("LCID=" + $languageParameter)
    }
    Start-Process -FilePath $command -ArgumentList $arguments -PassThru -Wait -NoNewWindow    
}