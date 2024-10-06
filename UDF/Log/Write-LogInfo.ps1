function Write-LogItem {
    Param(
        [string]$InvocationName,
        [object]$MessageData 
    )
    $oLogInfo = $Global:LogInfo
    $eCurrentLogLevel = if ($InvocationName -match "^Write-Log([a-zA-Z]+)$") {
        [LogLevel]::($Matches.1)
    } else {
        throw "Not possible exception"
    }
    $sLogItem = $(Get-Date -Format $oLogInfo.LogDateFormat) + " " + $eCurrentLogLevel
    $sMsg = [string]$MessageData
    if ($sMsg.Contains("`n")) {
        $sLogItem += " :`n" + $sMsg
    } else {
        $sLogItem += " - " + $sMsg
    }
    if ($oLogInfo.DoFileRotate) {
        Invoke-FileRotate -filepath $oLogInfo.LogFile -count $oLogInfo.LogRotateCount -size $oLogInfo.LogSize
    }
    $sLogItem | Out-File -Append $oLogInfo.LogFile
}

function Write-LogError {
    [CmdletBinding(DefaultParameterSetName="NoException")]
    Param(
        [Parameter(ParameterSetName = "WithException")]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "NoException", Position = 0)]
        [AllowNull()][AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message,

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        [System.Management.Automation.ErrorCategory]$Category,

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        [string]$ErrorId,

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        [Object]$TargetObject,

        [string]$RecommendedAction,

        [Alias("Activity")]
        [string]$CategoryActivity,

        [Alias("Reason")]
        [string]$CategoryReason,

        [Alias("TargetName")]
        [string]$CategoryTargetName,

        [Alias("TargetType")]
        [string]$CategoryTargetType,

        [Parameter(Mandatory, ParameterSetName = "WithException")]
        [System.Exception]$Exception,

        [Parameter(Mandatory, ParameterSetName = "ErrorRecord")]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    Begin {
        $oLogInfo = $Global:LogInfo        
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                switch ($PSCmdlet.ParameterSetName) {
                    "ErrorRecord" {
                        Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $ErrorRecord
                    }
                    "WithException" {
                        Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Exception
                    }
                    "NoException" {
                        Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
                    }
                }
            }
            Microsoft.PowerShell.Utility\Write-Error @PSBoundParameters
        }
    }
}

function Write-LogVerbose {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message
    )
    Begin {
        $oLogInfo = $Global:LogInfo
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
            }
            Microsoft.PowerShell.Utility\Write-Verbose @PSBoundParameters
        }
    }
}

function Write-LogWarning {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message
    )
    Begin {
        $oLogInfo = $Global:LogInfo        
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
            }
            Microsoft.PowerShell.Utility\Write-Warning @PSBoundParameters
        }
    }
}

function Write-LogDebug {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message
    )
    Begin {
        $oLogInfo = $Global:LogInfo        
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
            }
            Microsoft.PowerShell.Utility\Write-Debug @PSBoundParameters
        }
    }
}

function Write-LogInfo {
    [CmdLetBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromRemainingArguments, Position = 0)]
        [Object]$Object,

        [switch]$NoNewline,

        [Object]$Separator,

        [System.ConsoleColor]$ForegroundColor,

        [System.ConsoleColor]$BackgroundColor
    )
    Begin {
        $oLogInfo = $Global:LogInfo
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Object
            }
            Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
        }
    }
}
Set-Alias -Name Write-LogHost -Value Write-LogInfo
Set-Alias -Name Write-LogInformation -Value Write-LogInfo
