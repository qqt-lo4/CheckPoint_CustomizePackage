function Get-RootScriptInfo {
    <#
    .SYNOPSIS
        Gets comprehensive information about the root calling script.

    .DESCRIPTION
        Walks the call stack to retrieve details about the top-level calling script,
        including its name, path, directory, and bound parameters.
        Replaces Get-RootScriptName, Get-RootScriptPath and Get-RootScriptArguments.

    .OUTPUTS
        [PSCustomObject] with properties:
            - Name          : Script name without extension
            - FileName      : Script name with extension
            - FullPath      : Full path to the script file
            - Directory     : Directory containing the script
            - Arguments     : Bound parameters passed to the script (hashtable)
            - InvocationInfo: Full InvocationInfo object for advanced use

    .EXAMPLE
        $info = Get-RootScriptInfo
        $info.Name          # "MyScript"
        $info.Directory     # "C:\Scripts"
        $info.Arguments     # @{InputDir="C:\input"; ...}

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        1.0.0 (2026-03-10)
            - Initial version, replaces Get-RootScriptName, Get-RootScriptPath and Get-RootScriptArguments
    #>
    $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' }
    $rootFrame = $scriptCallStack[-1]

    $sFullPath = $rootFrame.ScriptName
    $sCommand = $rootFrame.Command.ToString()

    [PSCustomObject]@{
        Name           = $sCommand.Split(".")[0]
        FileName       = $sCommand
        FullPath       = $sFullPath
        Directory      = $sFullPath.Substring(0, $sFullPath.Length - $sCommand.Length - 1)
        Arguments      = $rootFrame.InvocationInfo.BoundParameters
        InvocationInfo = $rootFrame.InvocationInfo
    }
}
