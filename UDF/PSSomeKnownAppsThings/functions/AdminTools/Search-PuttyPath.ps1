function Search-PuttyPath {
    <#
    .SYNOPSIS
        Searches for the PuTTY executable path

    .DESCRIPTION
        Locates the PuTTY executable by checking the system PATH and common
        install directories (Program Files). Supports remote execution via
        Invoke-ThisFunctionRemotely.

    .PARAMETER ComputerName
        Remote computer to search on.

    .PARAMETER Credential
        Credential for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [String]. Path to putty.exe, or empty string if not found.

    .EXAMPLE
        $path = Search-PuttyPath

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
        $oCommand = Get-Command putty
        if ($oCommand) {
            return $oCommand.Source
        } elseif (Test-Path "$env:ProgramFiles\PuTTY\putty.exe") {
            return "$env:ProgramFiles\PuTTY\putty.exe"
        } elseif (Test-Path "${env:ProgramFiles(x86)}\PuTTY\putty.exe") {
            return "${env:ProgramFiles(x86)}\PuTTY\putty.exe"
        } else {
            return ""
        }
    }
}
