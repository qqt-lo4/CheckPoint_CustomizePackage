function Get-ScriptLogFileName {
    <#
    .SYNOPSIS
        Generates a timestamped log filename

    .DESCRIPTION
        Creates a log filename from the script name and current date/time
        in the format: ScriptName_yyyy-MM-dd_HHmm.log

    .PARAMETER scriptName
        Base script name (default: from Get-RootScriptName).

    .OUTPUTS
        [String]. Timestamped log filename.

    .EXAMPLE
        $logFile = Get-ScriptLogFileName

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$scriptName = $(Get-RootScriptInfo).Name
    )
    return $scriptName + "_" + $(Get-Date -Format "yyyy-MM-dd_HHmm") + ".log"
}
