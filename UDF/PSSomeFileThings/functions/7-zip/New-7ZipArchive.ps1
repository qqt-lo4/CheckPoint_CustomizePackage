function New-7ZipArchive {
    <#
    .SYNOPSIS
        Creates a 7-Zip archive

    .DESCRIPTION
        Uses 7-Zip command line tool to create a .7z archive with specified compression level.
        Supports various compression levels from 0 (no compression) to 9 (ultra compression).

    .PARAMETER SevenZipExePath
        Path to 7za.exe executable (default: auto-detected from tools directory).

    .PARAMETER Content
        Array of file or folder paths to include in the archive.

    .PARAMETER OutputArchivePath
        Path where the .7z archive will be created.

    .PARAMETER CompressionLevel
        Compression level from 0 to 9 (default: 5).
        0 = No compression (copy mode)
        1 = Low compression (fastest)
        5 = Normal compression
        9 = Ultra compression

    .OUTPUTS
        None. Creates a .7z archive file.

    .EXAMPLE
        New-7ZipArchive -Content "C:\Folder1","C:\File.txt" -OutputArchivePath "C:\archive.7z"

    .EXAMPLE
        New-7ZipArchive -Content "C:\Data" -OutputArchivePath "C:\backup.7z" -CompressionLevel 9

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$SevenZipExePath = (Get-ScriptDir -ToolsDir -ToolName "7-Zip" -FullPath) + "\7za.exe",
        [Parameter(Mandatory)]
        [string[]]$Content,
        [Parameter(Mandatory)]
        [string]$OutputArchivePath,

        #0 Don't compress at all.
        #This is called "copy mode."

        #1 Low compression.
        #This is called "fastest" mode.

        #9 Ultra compression
        [ValidateRange(0, 9)]
        [int]$CompressionLevel = 5
    )
    $aArgs = @(
        "a"
        "-mx$CompressionLevel"
        "-t7z"
        $OutputArchivePath
    )
    &$SevenZipExePath $aArgs -- $Content
}