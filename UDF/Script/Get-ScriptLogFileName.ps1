function Get-ScriptLogFileName {
    Param(
        [string]$scriptName = $(Get-RootScriptName)
    )
    return $scriptName + "_" + $(Get-Date -Format "yyyy-MM-dd_HHmm") + ".log"
}
