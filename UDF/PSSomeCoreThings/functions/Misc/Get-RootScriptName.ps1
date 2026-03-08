function Get-RootScriptName {
    <#
    .SYNOPSIS
        Gets the root/calling script name from the call stack

    .DESCRIPTION
        Walks the PowerShell call stack to find the top-level script name.
        By default returns the name without extension.

    .PARAMETER appendExtension
        Include the file extension in the returned name.

    .OUTPUTS
        [String]. The root script name.

    .EXAMPLE
        $name = Get-RootScriptName

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
