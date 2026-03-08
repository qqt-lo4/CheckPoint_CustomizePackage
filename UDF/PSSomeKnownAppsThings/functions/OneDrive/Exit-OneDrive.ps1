function Exit-OneDrive {
    <#
    .SYNOPSIS
        Shuts down the OneDrive client

    .DESCRIPTION
        Stops the OneDrive client by launching it with the /shutdown flag.

    .PARAMETER OneDriveClientPath
        Path to the OneDrive executable. Defaults to Get-OneDriveClient result.

    .EXAMPLE
        Exit-OneDrive

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$OneDriveClientPath = ((Get-OneDriveClient).FullName)
    )
    if (Test-Path $OneDriveClientPath) {
        &$OneDriveClientPath /shutdown
    }
}