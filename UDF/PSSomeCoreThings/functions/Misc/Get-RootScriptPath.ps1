function Get-RootScriptPath {
    <#
    .SYNOPSIS
        Gets the root script's directory path

    .DESCRIPTION
        Walks the call stack to determine the directory of the top-level calling script.

    .OUTPUTS
        [String]. The root script directory path.

    .EXAMPLE
        $scriptDir = Get-RootScriptPath

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        1.0.0 - First version
        1.1.0 (2026-03-05)
            - Corrected bugs since moved to a module
            - Removes -FullPath parameter (always returns full path)
    #>
    $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' } 
    $rootScriptFullPath = $scriptCallStack[-1].ScriptName
    $rootScriptName = $scriptCallStack[-1].Command.ToString()
    return $rootScriptFullPath.Substring(0, ($rootScriptFullPath.Length - $rootScriptName.Length - 1))
}
