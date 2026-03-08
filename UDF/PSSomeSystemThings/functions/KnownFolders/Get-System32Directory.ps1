function Get-System32Directory {
    <#
    .SYNOPSIS
        Returns the System32 directory path

    .DESCRIPTION
        Returns the path to the Windows System32 directory using .NET Environment class.

    .OUTPUTS
        [string]. The System32 directory path (e.g., "C:\Windows\system32").

    .EXAMPLE
        Get-System32Directory

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    return [System.Environment]::SystemDirectory
}