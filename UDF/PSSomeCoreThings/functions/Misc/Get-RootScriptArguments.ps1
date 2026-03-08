function Get-RootScriptArguments {
    <#
    .SYNOPSIS
        Gets the root script's bound parameters from the call stack

    .DESCRIPTION
        Walks the call stack to retrieve the bound parameters passed to the top-level calling script.
        Returns them as a hashtable.

    .OUTPUTS
        [Hashtable]. The root script bound parameters as key-value pairs.

    .EXAMPLE
        $rootArgs = Get-RootScriptArguments
        $rootArgs.InputDir  # returns the value of -InputDir passed to the root script

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-05)
            - First version
    #>
    $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' }
    $rootFrame = $scriptCallStack[-1]
    return $rootFrame.InvocationInfo.BoundParameters
}
