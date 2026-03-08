function Get-OS {
    <#
    .SYNOPSIS
        Returns the operating system name

    .DESCRIPTION
        Retrieves the OS caption string (e.g., "Microsoft Windows 11 Pro") using Get-SystemInfo.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [string]. The OS caption.

    .EXAMPLE
        Get-OS

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "None")]
    Param(
        [Parameter(ParameterSetName = "userpasswd")]
        [string]$ComputerName,
        [Parameter(ParameterSetName = "userpasswd")]
        [pscredential]$Credential,
        [Parameter(ParameterSetName = "pssession")]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    $infos = Get-SystemInfo @PSBoundParameters
    return $infos.OperatingSystem.Caption
}