function New-7ZipSFX {
    <#
    .SYNOPSIS
        Creates a 7-Zip self-extracting archive

    .DESCRIPTION
        Combines 7-Zip SFX header, configuration file, and archive into a self-extracting
        executable. The resulting file can extract and optionally execute files automatically.

    .PARAMETER SevenZipHeaderFile
        Path to 7-Zip SFX module (e.g., 7zSD.sfx).

    .PARAMETER SFXConfigFile
        Path to SFX configuration file.

    .PARAMETER ArchiveFile
        Path to the .7z archive file.

    .PARAMETER OutFile
        Path for the output self-extracting executable.

    .OUTPUTS
        None. Creates a self-extracting .exe file.

    .EXAMPLE
        New-7ZipSFX -SevenZipHeaderFile "7zSD.sfx" -SFXConfigFile "config.txt" -ArchiveFile "data.7z" -OutFile "installer.exe"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$SevenZipHeaderFile,
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$SFXConfigFile,
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ArchiveFile,
        [Parameter(Mandatory)]
        [string]$OutFile
    )
    &cmd /c copy /b """$SevenZipHeaderFile""" + """$SFXConfigFile""" + """$ArchiveFile""" """$OutFile"""
}