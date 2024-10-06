function New-7ZipArchive {
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