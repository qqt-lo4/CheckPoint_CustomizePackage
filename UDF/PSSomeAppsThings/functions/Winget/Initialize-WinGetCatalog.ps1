function Initialize-WinGetCatalog {
    <#
    .SYNOPSIS
        Initializes WinGet catalog by accepting agreements and updating sources
    
    .DESCRIPTION
        Runs winget source update under the specified credentials to initialize
        the WinGet catalog, accepting source agreements in the process.

    .PARAMETER Credential
        Administrator credentials for initialization

    .EXAMPLE
        $cred = Get-Credential
        Initialize-WinGetCatalog -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential
    )
    
    $initScript = {
        try {
            # Get winget path using AppxPackage
            $package = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue
            
            if ($package -and $package.InstallLocation) {
                $winget = Join-Path $package.InstallLocation "winget.exe"
            } else {
                return @{ Success = $false; Message = "Microsoft.DesktopAppInstaller package not found" }
            }
            
            if (-not (Test-Path $winget)) {
                return @{ Success = $false; Message = "winget.exe not accessible at: $winget" }
            }
            
            # Step 1: Accept source agreements
            Write-Output "  Accepting source agreements..."
            $null = & $winget source list --accept-source-agreements 2>&1
            Start-Sleep -Seconds 2
            
            # Step 2: Reset sources (to fix missing data)
            Write-Output "  Resetting sources..."
            $null = & $winget source reset --force 2>&1
            Start-Sleep -Seconds 3
            
            # Step 3: Update sources
            Write-Output "  Updating sources..."
            $null = & $winget source update 2>&1
            Start-Sleep -Seconds 2
            
            # Step 4: Test by searching for a known package
            Write-Output "  Testing catalog access..."
            $testOutput = & $winget search "7zip.7zip" --exact 2>&1
            $testExitCode = $LASTEXITCODE
            
            if ($testExitCode -eq 0 -or $testExitCode -eq -1978335212) {
                # 0 = found, -1978335212 = not found but catalog accessible
                return @{ 
                    Success = $true
                    Message = "Catalog initialized and accessible"
                    WingetPath = $winget
                }
            } else {
                return @{
                    Success = $false
                    Message = "Catalog test failed with exit code: $testExitCode"
                    WingetPath = $winget
                }
            }
            
        } catch {
            return @{ 
                Success = $false
                Message = $_.Exception.Message
            }
        }
    }
    
    Write-Host "Initializing WinGet catalog with admin rights..." -ForegroundColor Cyan
    $result = Invoke-ScriptBlockAs -ScriptBlock $initScript -Credential $Credential
    
    if ($result.Success) {
        Write-Host "  ✓ $($result.Message)" -ForegroundColor Green
        Write-Host "    Using: $($result.WingetPath)" -ForegroundColor Gray
        return $true
    } else {
        Write-Host "  ✗ $($result.Message)" -ForegroundColor Red
        
        # If failed, suggest manual fix
        if ($result.WingetPath) {
            Write-Host ""
            Write-Host "  Try running these commands manually as Administrator:" -ForegroundColor Yellow
            Write-Host "    & '$($result.WingetPath)' source reset --force" -ForegroundColor Gray
            Write-Host "    & '$($result.WingetPath)' source update" -ForegroundColor Gray
        }
        
        return $false
    }
}