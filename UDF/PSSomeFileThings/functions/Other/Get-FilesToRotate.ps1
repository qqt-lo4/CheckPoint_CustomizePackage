function Get-FilesToRotate {
    <#
    .SYNOPSIS
        Gets files matching a rotation pattern

    .DESCRIPTION
        Retrieves files that match a rotation naming pattern (e.g., file.log, file_1.log, file_2.log).
        Returns files sorted by rotation index number.

    .PARAMETER filepath
        Path to the base file.

    .PARAMETER descending
        Sort results in descending order.

    .OUTPUTS
        [System.IO.FileInfo[]]. Array of files matching the rotation pattern.

    .EXAMPLE
        Get-FilesToRotate -filepath "C:\logs\app.log"

    .EXAMPLE
        Get-FilesToRotate -filepath "C:\logs\app.log" -descending

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$filepath,
        [switch]$descending
    )
    if (($filepath -match "^(.+\\)([^\\\.]+)(\.[^\\]+)+$") -and ($Matches.Count -eq 4)) {
        $folder = $Matches.1
        $filename_without_ext = $Matches.2
        $extension = $Matches.3
        $regex_children = "^$filename_without_ext(_[0-9]+)*" + [regex]::Escape($extension)
        $result = Get-ChildItem -Path $folder | Where-Object { $_.Name -match $regex_children }
        if ($descending.IsPresent) {
            return $result | Sort-Object {[int]($_.basename -replace '\D')} -Descending
        } else {
            return $result | Sort-Object {[int]($_.basename -replace '\D')}
        }
    }
    return $null
}