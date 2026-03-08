function Invoke-PAExecRemoteShell {
    <#
    .SYNOPSIS
        Opens a remote shell on a computer using PAExec

    .DESCRIPTION
        Launches a remote shell session (cmd, powershell, or pwsh) on a remote
        computer via PAExec. Wraps Invoke-PAExec with a shell selector.

    .PARAMETER Computer
        The remote computer name or IP address.

    .PARAMETER cmd
        Open a CMD shell (default).

    .PARAMETER powershell
        Open a Windows PowerShell shell.

    .PARAMETER pwsh
        Open a PowerShell 7+ (pwsh) shell.

    .PARAMETER System
        Run the remote shell as SYSTEM.

    .PARAMETER Username
        Username for authentication.

    .PARAMETER Password
        SecureString password for authentication.

    .PARAMETER Credential
        PSCredential for authentication.

    .EXAMPLE
        Invoke-PAExecRemoteShell -Computer "SERVER01" -powershell -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "cmd")]
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Computer,
        [Parameter(ParameterSetName = "cmd")]
        [switch]$cmd,
        [Parameter(ParameterSetName = "powershell")]
        [switch]$powershell,
        [Parameter(ParameterSetName = "pwsh")]
        [switch]$pwsh,
        [switch]$System,
        [string]$Username,
        [securestring]$Password,
        [pscredential]$Credential
    )
    $sShell = $PSCmdlet.ParameterSetName
    $PSBoundParameters.Remove($sShell)
    Invoke-PAExec @PSBoundParameters -Application $sShell
}
