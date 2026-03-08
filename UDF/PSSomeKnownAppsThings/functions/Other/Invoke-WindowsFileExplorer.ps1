function Invoke-WindowsFileExplorer {
    <#
    .SYNOPSIS
        Opens Windows File Explorer at a specific path

    .DESCRIPTION
        Opens Windows Explorer at the specified folder path. Throws an error
        if the path contains commas due to a known explorer.exe bug.

    .PARAMETER Path
        The folder path to open. Must exist.

    .EXAMPLE
        Invoke-WindowsFileExplorer -Path "C:\Users"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$Path
    )
    if ($Path.Contains(",")) {
        throw "Unsupported Path: a bug in explorer.exe prevent opening path that contains commas"
    }
    &explorer $Path
}