function Set-LogInfo {
    [cmdletbinding()]
    <#
    .Description
    Set log informations used by Write-Log* functions
    .Version 1.0
    First version
    .Version 1.1
    Added another parameter set named "Config"
    Added management for fallback folder
    Added path resolution to remove environement variables
    #>
    Param(
        [Parameter(ParameterSetName = "config")]
        [object]$Config,
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$LogFolder,
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$FallbackLogFolder,
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$LogFileName = (Get-ScriptLogFileName),
        [Parameter(ParameterSetName = "DirectValues")]
        [int]$LogRotateCount = -1,
        [Parameter(ParameterSetName = "DirectValues")]
        [int64]$LogSize = 10MB,
        [Parameter(ParameterSetName = "DirectValues")]
        [LogLevel]$LogLevel = ([LogLevel]::Info),
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$DateFormat = "yyyy-MM-dd HH:mm:ss",
        [Parameter(ParameterSetName = "DirectValues")]
        [System.EnvironmentVariableTarget]$EnvironmentVariableTarget = "Machine"
    )
    # build environment variables target
    $sEnvironmentVariableTarget = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.EnvVarTarget) {
            $Config.EnvVarTarget
        } else {
            "Machine"
        }
    } else {
        [System.EnvironmentVariableTarget]::$EnvironmentVariableTarget
    }
    # build log folder output
    $sLogFolder = if ($PSCmdlet.ParameterSetName -eq "config") {$Config.Folder} else {$LogFolder}
    if ((-not $sLogFolder) -or ($sLogFolder -eq "")) {
        throw "Folder to store log is empty!"
    }
    $sLogFolder = Resolve-PathWithVariables -Path $sLogFolder -EnvironmentVariableTarget $sEnvironmentVariableTarget
    $sFallbackLogFolder = if ($PSCmdlet.ParameterSetName -eq "config") {$Config.FallbackFolder} else {$FallbackLogFolder}
    if (($sFallbackLogFolder) -and ($sFallbackLogFolder -ne "")) {
        $sFallbackLogFolder = Resolve-PathWithVariables -Path $sFallbackLogFolder -EnvironmentVariableTarget $sEnvironmentVariableTarget
    }
    $sLogFolder = if (Test-Path -Path $sLogFolder -PathType Container) {
        $sLogFolder
    } else {
        if (($sFallbackLogFolder) -and (Test-Path -Path $sFallbackLogFolder -PathType Container)) {
            $sFallbackLogFolder
        } else {
            throw [System.IO.DirectoryNotFoundException] "Both log folders does not exist"
        }
    }
    # build log file name output
    $sLogFileName = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.FileName) {
            $Config.FileName
        } else {
            (Get-ScriptLogFileName)
        }
    } else {
        $LogFileName
    }
    $sLogFileName = Resolve-PathWithVariables -Path $sLogFileName -EnvironmentVariableTarget $sEnvironmentVariableTarget
    # build logrotate variable
    $iLogRotate = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.RotateCount) {$Config.RotateCount} else { -1 }
    } else {
        $LogRotateCount
    }
    # build log size
    $iLogSize = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.Size) {
            if ($Config.Size -is [int]) {
                $Config.Size
            } elseif ($Config.Size -is [string]) {
                Convert-SizeToInt -Size $Config.Size
            } else {
                throw "Bad size format"
            }    
        } else {
            -1
        }
    } else {
        $LogSize
    }
    # build log level variable
    $eLogLevel = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.LogLevel) {
            if ($Config.LogLevel -in [Enum]::GetNames("LogLevel")) {
                [LogLevel]::($Config.LogLevel)
            } else {
                throw [System.ArgumentOutOfRangeException] "Provided log level is not correct"
            }
        } else {
            ([LogLevel]::Info)
        }
    } else {
        $LogLevel
    }
    # build dateformat variable
    $sDateFormat = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.DateFormat) {
            $Config.DateFormat
        } else {
            "yyyy-MM-dd HH:mm:ss"
        }
    } else {
        $DateFormat
    }
    # build result variable
    $result = @{
        GlobalLogLevel = $eLogLevel
        LogDateFormat = $sDateFormat
        LogFolder = $sLogFolder
        LogFileName = $sLogFileName
        LogFile = ($sLogFolder + "\" + $sLogFileName)
        DoFileRotate = ($iLogRotate -ne -1)
        LogRotateCount = ($iLogRotate)
        LogSize = $iLogSize
        DoWriteToFile = (($null -ne $LogFileName) -and ($LogFileName -ne ""))
    }
    $result = New-Object -TypeName psobject -Property $result
    Add-Member -InputObject $result -MemberType ScriptMethod -Name "DoWriteLogLevel" -Value {
        $InvocationName = $args[0]
        $eCurrentLogLevel = if ($InvocationName -match "^Write-Log([a-zA-Z]+)$") {
            [LogLevel]::($Matches.1)
        } else {
            throw "Not possible exception"
        }
        return ($eCurrentLogLevel.Value__ -le $this.GlobalLogLevel.Value__)
    }
    $Global:LogInfo = $result
}