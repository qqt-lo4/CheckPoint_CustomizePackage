function Get-ParentProcess {
    <#
    .SYNOPSIS
        Retrieves the parent process of a given process

    .DESCRIPTION
        Uses WMI to find the parent process ID, then returns the parent process object.
        Defaults to the current PowerShell process.

    .PARAMETER ID
        The process ID to look up. Defaults to the current process ($PID).

    .OUTPUTS
        [System.Diagnostics.Process]. The parent process object.

    .EXAMPLE
        Get-ParentProcess

    .EXAMPLE
        Get-ParentProcess -ID 1234

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$ID = $PID
    )
    $PPID = (Get-WmiObject win32_process -Filter "processid='$ID'").ParentProcessId
    $oParentProcess = Get-Process -Id $PPID
    return $oParentProcess
}
