function Invoke-FileRotate {
    <#
    .SYNOPSIS
        Performs file rotation with retention management

    .DESCRIPTION
        Rotates a file by renaming it with an incrementing index (e.g., file.log -> file_1.log).
        Automatically manages rotation retention by deleting files exceeding the count limit.
        Can optionally rotate only when file reaches a specific size.

    .PARAMETER filepath
        Path to the file to rotate.

    .PARAMETER count
        Maximum number of rotated files to retain (default: 10).

    .PARAMETER size
        Minimum file size in bytes to trigger rotation (-1 = always rotate, default: -1).

    .OUTPUTS
        None. Rotates the file and manages retention.

    .EXAMPLE
        Invoke-FileRotate -filepath "C:\logs\app.log" -count 5

    .EXAMPLE
        Invoke-FileRotate -filepath "C:\logs\app.log" -count 10 -size 10485760

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [string]$filepath,
        [ValidateNotNullOrEmpty()]
        [int]$count = 10,
        [int]$size = -1
    )
    if ($filepath -match "^(.+\\).+$") {
        if (Test-Path $Matches.1 -PathType Container) {
            if (Test-Path $filepath -PathType Leaf) {
                if (($size -eq -1) -or (($size -gt 0) -and ((Get-ChildItem $filepath).Length -ge $size))) {
                    Get-FilesToRotate $filepath -descending | `
                        ForEach-Object {
                            if (($_.Name -match "^([^._]+)(_([0-9]+))?(\..*)$") `
                                -and (($Matches.Count -eq 5) -or ($Matches.Count -eq 3))) {
                                $extension = $Matches.4
                                $name = $Matches.1
                                $index = $Matches.3
                                $newname = $_.Directory.FullName + "\" + $name
                                if ($null -eq $index) {
                                    $newname += "_1" + $extension
                                } else {
                                    $newname += "_" + ([int]$index + 1) + $extension
                                }
                                Rename-Item -Path $_.FullName -NewName $newname
                            }
                        }
                    Get-RotatedFilesToDelete $filepath $count | ForEach-Object { Remove-Item $_.FullName }
                }
            }
        } else {
            throw [System.IO.FileNotFoundException] $("Folder " + $Matches.1 + " does not exists.")
        }
    } else {
        throw [System.IO.FileNotFoundException] "File path has a bad format : $filepath"
    }
}