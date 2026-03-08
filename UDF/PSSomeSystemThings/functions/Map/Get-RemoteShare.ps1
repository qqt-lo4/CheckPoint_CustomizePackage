function Get-RemoteShare {
    <#
    .SYNOPSIS
        Retrieves shared folders from a remote computer

    .DESCRIPTION
        Lists SMB shares on a remote computer using CIM session, falling back to WMI if CIM fails.

    .PARAMETER Credential
        Credentials for remote access.

    .PARAMETER ComputerName
        Remote computer name to query.

    .OUTPUTS
        [CimInstance[]] or [ManagementObject[]]. SMB share objects.

    .EXAMPLE
        Get-RemoteShare -ComputerName "SERVER01" -Credential (Get-Credential)

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory)]
        [pscredential]$Credential,
        [Parameter(Mandatory)]
        [string]$ComputerName
    )
    try {
        $_CimSession = New-CimSession -ComputerName $ComputerName -Credential $Credential
        Get-SmbShare -CimSession $_CimSession -ErrorAction Stop
    } catch {
        Get-WmiObject -Class Win32_Share -ComputerName $ComputerName -Credential $Credential
    }
}