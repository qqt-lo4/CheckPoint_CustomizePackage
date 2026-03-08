function Test-IsAdmin {
    <#
    .SYNOPSIS
        Tests if the current PowerShell session is running as Administrator

    .DESCRIPTION
        Checks whether the current Windows identity has the Administrator built-in role.

    .OUTPUTS
        [bool]. $true if running as Administrator, $false otherwise.

    .EXAMPLE
        Test-IsAdmin

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}