function Test-WinGetAvailability {
    <#
    .SYNOPSIS
        Tests if WinGet is available on the system

    .DESCRIPTION
        Checks whether winget.exe can be located via the Microsoft.DesktopAppInstaller
        AppX package. Outputs status messages to the console.

    .OUTPUTS
        System.Boolean. True if winget.exe is found, false otherwise.

    .EXAMPLE
        if (Test-WinGetAvailability) { Write-Host "WinGet is ready" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    Write-Host "Checking WinGet availability..." -ForegroundColor Cyan
    
    try {
        $winget = Get-WinGetExe
        Write-Host "  ✓ Found at: $winget" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "  ✗ $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}