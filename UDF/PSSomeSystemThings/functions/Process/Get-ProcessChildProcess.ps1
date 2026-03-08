function Get-ProcessChildProcess {
    <#
    .SYNOPSIS
        Gets child and grandchild processes of a given process

    .DESCRIPTION
        Uses WMI to enumerate all child and grandchild processes of a specified
        process (or the current PowerShell process by default). Optionally filters
        by process name using wildcards.

    .PARAMETER ProcessId
        The parent process ID to search from. Defaults to the current PowerShell process.

    .PARAMETER NameFilter
        A wildcard filter on the process name (e.g. "chrome*"). If omitted, returns all children.

    .PARAMETER Depth
        How many levels of child processes to traverse. Default is 2 (children and grandchildren).

    .OUTPUTS
        [System.Diagnostics.Process[]]. Array of matching child process objects.

    .EXAMPLE
        Get-ProcessChildProcess
        Gets all child/grandchild processes of the current PowerShell session.

    .EXAMPLE
        Get-ProcessChildProcess -NameFilter "chrome*"
        Gets Chrome child/grandchild processes launched from this PowerShell session.

    .EXAMPLE
        Get-ProcessChildProcess -ProcessId 1234 -Depth 3
        Gets up to 3 levels of child processes for PID 1234.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [uint32]$ProcessId = [System.Diagnostics.Process]::GetCurrentProcess().Id,

        [Parameter()]
        [string]$NameFilter,

        [Parameter()]
        [int]$Depth = 2
    )

    # Single WMI call to retrieve all processes with their parents
    $allWmiProcesses = Get-WmiObject -Class Win32_Process -Property ProcessId, ParentProcessId, Name -ErrorAction SilentlyContinue

    # Build a hashtable for fast parent lookup
    $processMap = @{}
    foreach ($proc in $allWmiProcesses) {
        $processMap[$proc.ProcessId] = @{
            ParentProcessId = $proc.ParentProcessId
            Name            = $proc.Name
        }
    }

    # Collect matching PIDs by traversing the process tree
    $parentIds = @{ $ProcessId = $true }
    $matchedPids = @()

    for ($level = 1; $level -le $Depth; $level++) {
        $nextParentIds = @{}
        foreach ($proc in $allWmiProcesses) {
            if ($parentIds.ContainsKey($proc.ParentProcessId)) {
                $nextParentIds[$proc.ProcessId] = $true

                # Apply name filter if specified
                if ($NameFilter -and $proc.Name -notlike $NameFilter) {
                    continue
                }

                $matchedPids += $proc.ProcessId
                Write-Verbose "Level $level child: PID=$($proc.ProcessId), Name=$($proc.Name), Parent=$($proc.ParentProcessId)"
            }
        }
        $parentIds = $nextParentIds
        if ($parentIds.Count -eq 0) { break }
    }

    # Return actual Process objects
    $result = @()
    foreach ($iPid in $matchedPids) {
        try {
            $processObj = Get-Process -Id $iPid -ErrorAction SilentlyContinue
            if ($processObj) {
                $result += $processObj
            }
        } catch {
            Write-Verbose "Could not get process object for PID $iPid"
        }
    }

    return $result
}
