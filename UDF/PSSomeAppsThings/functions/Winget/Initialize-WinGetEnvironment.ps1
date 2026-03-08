function Initialize-WinGetEnvironment {
    <#
    .SYNOPSIS
        Initializes WinGet environment with admin credentials
    
    .PARAMETER AdminCredential
        Administrator credentials
    
    .EXAMPLE
        $adminCred = Get-Credential -UserName "Administrator"
        Initialize-WinGetEnvironment -AdminCredential $adminCred

    .DESCRIPTION
        Sets up the WinGet environment by verifying winget.exe exists,
        initializing the catalog with admin credentials, and downloading
        the package database for offline queries.

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$AdminCredential
    )
    
    Write-Host "=====================================================" -ForegroundColor Magenta
    Write-Host "  Initializing WinGet Environment" -ForegroundColor Magenta
    Write-Host "=====================================================" -ForegroundColor Magenta
    Write-Host ""
    
    # 1. Check if winget.exe exists
    if (-not (Test-WinGetAvailability)) {
        Write-Error "WinGet not found. Please install WinGet first."
        return $false
    }
    
    Write-Host ""
    
    # 2. Initialize catalog with admin rights
    $catalogInit = Initialize-WinGetCatalog -Credential $AdminCredential
    
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Magenta
    
    if ($catalogInit) {
        Write-Host "  ✓ WinGet is ready" -ForegroundColor Green
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host ""
        return $true
    } else {
        Write-Host "  ⚠ WinGet initialization incomplete" -ForegroundColor Yellow
        Write-Host "=====================================================" -ForegroundColor Magenta
        Write-Host ""
        return $false
    }
}
