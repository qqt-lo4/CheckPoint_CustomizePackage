function Get-RemoteRegistryKey {
    <#
    .SYNOPSIS
        Retrieves registry key children from a remote computer

    .DESCRIPTION
        Uses PowerShell remoting to enumerate child items of a registry path on a remote computer.

    .PARAMETER path
        The registry path to query (e.g., "HKLM:\SOFTWARE\Microsoft").

    .PARAMETER computer
        The remote computer name.

    .PARAMETER cred
        Optional credentials for remote access.

    .OUTPUTS
        [Microsoft.Win32.RegistryKey[]]. Child registry keys.

    .EXAMPLE
        Get-RemoteRegistryKey -path "HKLM:\SOFTWARE\Microsoft" -computer "SERVER01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$path,
        [string]$computer,
        [pscredential]$cred
    )
    [scriptblock]$sb = { 
        Param(
            [string]$path
        )
        Get-ChildItem -Path $path 
    }
    if ($cred) {
        return Invoke-Command -ComputerName $computer -ScriptBlock $sb -ArgumentList $path -ErrorAction Stop -Credential $cred
    } else {
        return Invoke-Command -ComputerName $computer -ScriptBlock $sb -ArgumentList $path -ErrorAction Stop
    }
}