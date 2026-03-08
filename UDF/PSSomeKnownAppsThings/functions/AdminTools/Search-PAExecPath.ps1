function Search-PAExecPath {
    <#
    .SYNOPSIS
        Searches for the PAExec executable path

    .DESCRIPTION
        Locates the PAExec executable by checking the system PATH and the
        tools directory. Supports remote execution via Invoke-ThisFunctionRemotely.

    .PARAMETER ComputerName
        Remote computer to search on.

    .PARAMETER Credential
        Credential for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [String]. Path to paexec.exe, or empty string if not found.

    .EXAMPLE
        $path = Search-PAExecPath

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    if ($ComputerName -or $Session) {
        Invoke-ThisFunctionRemotely
    } else {
        $oCommand = Get-Command paexec -ErrorAction SilentlyContinue
        if ($oCommand) {
            return $oCommand.Source
        } elseif (Test-Path "$(Get-ScriptDir -ToolsDir -ToolName "paexec")\paexec.exe") {
            return "$(Get-ScriptDir -ToolsDir -ToolName "paexec")\paexec.exe"
        } else {
            return ""
        }
    }
}
