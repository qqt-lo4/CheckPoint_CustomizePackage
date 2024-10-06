function Get-RootScriptName {
    Param(
        [switch]$appendExtension
    )
    $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' } 
    if ($appendExtension.IsPresent) {
        return $scriptCallStack[-1].Command
    } else {
        return $scriptCallStack[-1].Command.Split(".")[0]
    }
}
