function Expand-CABFile {
    <#
    .SYNOPSIS
        Extracts files from a CAB archive

    .DESCRIPTION
        Expands (extracts) files from a Windows CAB (Cabinet) archive to a specified destination.
        Can extract all files or a specific file by name.

    .PARAMETER CABFile
        Path to the CAB file to extract.

    .PARAMETER Destination
        Destination folder for extracted files.

    .PARAMETER Filename
        Optional specific file to extract (default: all files).

    .OUTPUTS
        [String]. Command output from expand.exe.

    .EXAMPLE
        Expand-CABFile -CABFile "C:\archive.cab" -Destination "C:\Output"

    .EXAMPLE
        Expand-CABFile -CABFile "C:\archive.cab" -Destination "C:\Output" -Filename "file.txt"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$CABFile,
        [Parameter(Position = 1)]
        [string]$Destination,
        [Parameter(Position = 2)]
        [string]$Filename
    )
    if (Test-Path -Path $CABFile -PathType Leaf) {
        $sFilename = if ($Filename) { $Filename } else { "*" }
        $sCommandResult = (expand -F:$sFilename $CABFile $Destination)
        return $sCommandResult
    } else {
        throw [System.IO.FileNotFoundException] "`$CABFile not found"
    }
}