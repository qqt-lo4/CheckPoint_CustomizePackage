function Get-ScriptConfig {
    Param(
        [string]$ConfigFileName = "config.json",
        [switch]$ToHashtable,
        [string]$DevConfigFolderName = "input",
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
        foreach ($sFolderToTest in $aFoldersToTest) {
            $sFolderPath = switch ($sFolderToTest) {
                "ScriptRoot" { Get-RootScriptPath }
                "AppData" { $env:APPDATA + "\"}
                "ProgramData" { $env:ProgramData + "\"}
            }
            $sConfigFilePath = Test-GetScriptConfig -ConfigFileName $ConfigFileName -DevConfigFolderName $DevConfigFolderName -FolderPath $sFolderPath
            if ($sConfigFilePath -ne "") {
                break
            }
        }
    }
    End {
        if ($sConfigFilePath -ne "") {
            $oResult = Get-Content -Path $sConfigFilePath | ConvertFrom-Json
            if ($ToHashtable) {
                $oResult = $oResult | ConvertTo-Hashtable
            }
            return $oResult
        } else {
            return $null
        }
    }
}
