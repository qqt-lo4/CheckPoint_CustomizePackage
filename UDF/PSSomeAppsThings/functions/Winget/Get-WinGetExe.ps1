function Get-WinGetExe {
    <#
    .SYNOPSIS
        Returns the path to the system winget.exe using AppxPackage information

    .DESCRIPTION
        Locates the winget.exe binary by querying the Microsoft.DesktopAppInstaller
        AppX package install location.

    .OUTPUTS
        System.String. The full path to winget.exe.

    .EXAMPLE
        $winget = Get-WinGetExe

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    # Get package information to find install location
    $package = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue
    
    if ($package -and $package.InstallLocation) {
        $wingetPath = Join-Path $package.InstallLocation "winget.exe"
        if (Test-Path $wingetPath) {
            return $wingetPath
        } else {
            throw "winget.exe not found at expected location: $wingetPath"
        }
    }
    
    throw "Microsoft.DesktopAppInstaller package not found. Please ensure App Installer (WinGet) is installed."
}