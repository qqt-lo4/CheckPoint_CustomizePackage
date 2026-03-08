function Get-SystemTemp {
    <#
    .SYNOPSIS
        Returns the system-level TEMP directory path

    .DESCRIPTION
        Returns the machine-scope TEMP environment variable value with a trailing backslash.

    .OUTPUTS
        [string]. The system TEMP directory path (e.g., "C:\Windows\TEMP\").

    .EXAMPLE
        Get-SystemTemp

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    return [System.Environment]::GetEnvironmentVariable('TEMP','Machine') + "\"
}