function New-7ZipSFX {
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