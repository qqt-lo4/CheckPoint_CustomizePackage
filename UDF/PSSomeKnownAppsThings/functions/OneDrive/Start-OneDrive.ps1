function Start-OneDrive {
    <#
    .SYNOPSIS
        Starts the OneDrive client in the background

    .DESCRIPTION
        Launches the OneDrive client with the /background flag.

    .PARAMETER OneDriveClientPath
        Path to the OneDrive executable. Defaults to Get-OneDriveClient result.

    .EXAMPLE
        Start-OneDrive

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$OneDriveClientPath = ((Get-OneDriveClient).FullName)
    )
    if (Test-Path $OneDriveClientPath) {
        &$OneDriveClientPath /background
    }
}