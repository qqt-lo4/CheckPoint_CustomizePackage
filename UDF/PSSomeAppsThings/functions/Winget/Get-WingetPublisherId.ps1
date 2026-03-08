function Get-WingetPublisherId {
    <#
    .SYNOPSIS
        Retrieves the PublisherId from the installed WinGet package

    .DESCRIPTION
        Queries the Microsoft.DesktopAppInstaller AppX package to get its PublisherId,
        which is used in the folder naming for portable packages.

    .OUTPUTS
        Returns the PublisherId string (e.g., "8wekyb3d8bbwe")

    .EXAMPLE
        Get-WingetPublisherId
        # Returns: 8wekyb3d8bbwe

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param()

    try {
        # Get the WinGet package (Microsoft.DesktopAppInstaller)
        $wingetPackage = Get-AppxPackage | Where-Object { $_.Name -eq "Microsoft.DesktopAppInstaller" }

        if ($wingetPackage) {
            $publisherId = $wingetPackage.PublisherId
            Write-Verbose "WinGet PublisherId: $publisherId"
            return $publisherId
        } else {
            # Fallback to default value if package not found
            Write-Warning "Microsoft.DesktopAppInstaller package not found, using default PublisherId"
            return "8wekyb3d8bbwe"
        }
    } catch {
        Write-Warning "Failed to retrieve WinGet PublisherId: $_. Using default value."
        return "8wekyb3d8bbwe"
    }
}
