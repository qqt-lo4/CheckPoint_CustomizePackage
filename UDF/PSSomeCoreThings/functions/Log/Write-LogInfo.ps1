function Write-LogItem {
    <#
    .SYNOPSIS
        Writes a formatted log entry to the log file

    .DESCRIPTION
        Internal helper function that formats a log message with timestamp and log level,
        handles file rotation if configured, and appends to the log file.

    .PARAMETER InvocationName
        The name of the calling function (used to determine log level).

    .PARAMETER MessageData
        The message data to log.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
    <#
    .SYNOPSIS
        Writes an error-level message to log file and error stream

    .DESCRIPTION
        Logs an error message to file (if configured) and calls Write-Error.
        Supports exception objects, error records, and plain messages.

    .PARAMETER Message
        The error message string.

    .PARAMETER Exception
        An exception object to log.

    .PARAMETER ErrorRecord
        An ErrorRecord object to log.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
    <#
    .SYNOPSIS
        Writes a verbose-level message to log file and verbose stream

    .DESCRIPTION
        Logs a verbose message to file (if configured) and calls Write-Verbose.

    .PARAMETER Message
        The verbose message string.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
    <#
    .SYNOPSIS
        Writes a warning-level message to log file and warning stream

    .DESCRIPTION
        Logs a warning message to file (if configured) and calls Write-Warning.

    .PARAMETER Message
        The warning message string.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
    <#
    .SYNOPSIS
        Writes a debug-level message to log file and debug stream

    .DESCRIPTION
        Logs a debug message to file (if configured) and calls Write-Debug.

    .PARAMETER Message
        The debug message string.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
    <#
    .SYNOPSIS
        Writes an info-level message to log file and host

    .DESCRIPTION
        Logs an informational message to file (if configured) and calls Write-Host.
        Aliases: Write-LogHost, Write-LogInformation.

    .PARAMETER Object
        The object to write.

    .PARAMETER ForegroundColor
        Console text color.

    .PARAMETER BackgroundColor
        Console background color.

    .EXAMPLE
        Write-LogInfo "Application started"

    .EXAMPLE
        Write-LogInfo "Warning!" -ForegroundColor Yellow

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
