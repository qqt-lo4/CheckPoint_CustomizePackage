function Get-RotatedFilesToDelete {
    <#
    .SYNOPSIS
        Gets rotated files that exceed retention count

    .DESCRIPTION
        Identifies rotated files that should be deleted based on retention count.
        Returns files that exceed the specified maximum number of rotations to keep.

    .PARAMETER filepath
        Path to the base file.

    .PARAMETER count
        Maximum number of rotated files to retain (default: 10).

    .OUTPUTS
        [System.IO.FileInfo[]]. Array of files to delete.

    .EXAMPLE
        Get-RotatedFilesToDelete -filepath "C:\logs\app.log" -count 5

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$filepath,
        [Parameter(Mandatory=$true, Position=1)]
        [int]$count = 10
    )
    [System.IO.FileInfo[]]$list = Get-FilesToRotate $filepath
    [System.IO.FileInfo[]]$result = @()
    if ($list.Count -gt $count) {
        for ($i = $count; $i -lt $list.Count; $i++) {
            $result += $list[$i]
        }
    }
    return $result
}
