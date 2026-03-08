function Get-RemotePSDrive {
    <#
    .SYNOPSIS
        Gets PSDrive information from a remote computer

    .DESCRIPTION
        Retrieves PSDrive information from a remote computer using PowerShell remoting.
        Returns drive details including name, provider, root, and free space.

    .PARAMETER computerName
        Name of the remote computer.

    .PARAMETER drive
        Drive letter to query (default: "C").

    .PARAMETER Credential
        Credentials for remote connection.

    .OUTPUTS
        [PSCustomObject]. PSDrive information from the remote computer.

    .EXAMPLE
        Get-RemotePSDrive -computerName "Server01" -Credential $cred

    .EXAMPLE
        Get-RemotePSDrive -computerName "Server01" -drive "D" -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)][string]$computerName,
        [string]$drive = "C",
        [Parameter(Mandatory)][pscredential]$Credential
    )
    Invoke-Command -ComputerName $computerName {Get-PSDrive $args[0]} -ArgumentList $drive -Credential $cred
}