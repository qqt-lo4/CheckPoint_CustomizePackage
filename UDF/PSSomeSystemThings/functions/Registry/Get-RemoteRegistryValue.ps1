function Get-RemoteRegistryValue {
    <#
    .SYNOPSIS
        Retrieves a specific registry value from a remote computer

    .DESCRIPTION
        Uses PowerShell remoting to read a named registry value from a remote computer.

    .PARAMETER path
        The registry path (e.g., "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion").

    .PARAMETER valuename
        The name of the registry value to retrieve.

    .PARAMETER computer
        The remote computer name.

    .PARAMETER cred
        Optional credentials for remote access.

    .OUTPUTS
        The registry value data.

    .EXAMPLE
        Get-RemoteRegistryValue -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -valuename "ProgramFilesDir" -computer "SERVER01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$path,
        [string]$valuename,
        [string]$computer,
        [pscredential]$cred
    )
    [scriptblock]$sb = { 
        Param(
            [string]$path,
            [string]$valuename
        )
        Get-ItemProperty -Path $path | ForEach-Object { $_.$valuename }
    }
    if ($cred) {
        return Invoke-Command -ComputerName $computer -ScriptBlock $sb -ArgumentList $path,$valuename -ErrorAction Stop -Credential $cred
    } else {
        return Invoke-Command -ComputerName $computer -ScriptBlock $sb -ArgumentList $path,$valuename -ErrorAction Stop
    }
}
