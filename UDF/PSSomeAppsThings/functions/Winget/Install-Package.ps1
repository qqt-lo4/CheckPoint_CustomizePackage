function Install-Package {
    <#
    .SYNOPSIS
        Installs a package using the system winget.exe
    
    .PARAMETER Id
        Package ID to install
    
    .PARAMETER Scope
        Installation scope (Machine, User, or System)
    
    .PARAMETER Source
        Package source (winget or msstore, default: winget)
    
    .PARAMETER Credential
        Administrator credentials (required)

    .DESCRIPTION
        Wraps winget.exe install command, running it under the specified
        administrator credentials with silent switches and agreement acceptance.

    .EXAMPLE
        Install-Package -Id "Google.Chrome" -Scope "Machine" -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Id,
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("Machine", "User", "System")]
        [string]$Scope = "Machine",
        
        [Parameter(Mandatory=$false, ValueFromPipelineByPropertyName=$true)]
        [string]$Source = "winget",
        
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(ValueFromRemainingArguments=$true)]
        [object[]]$RemainingArguments
    )
    
    try {
        Write-Host "Installing: $Id" -ForegroundColor Cyan
        
        # Map scope
        $wingetScope = if ($Scope -eq "System" -or $Scope -eq "Machine") { "machine" } else { "user" }
        
        # Install with admin credentials
        $installScript = {
            param($PackageId, $PackageSource, $InstallScope)
            
            try {
                # Get winget path using AppxPackage
                $package = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue
                
                if ($package -and $package.InstallLocation) {
                    $winget = Join-Path $package.InstallLocation "winget.exe"
                } else {
                    return @{ 
                        Success = $false
                        ExitCode = -1
                        Message = "Microsoft.DesktopAppInstaller package not found"
                    }
                }
                
                if (-not (Test-Path $winget)) {
                    return @{
                        Success = $false
                        ExitCode = -1
                        Message = "winget.exe not accessible at: $winget"
                    }
                }
                
                # Build arguments
                $arguments = "install --id `"$PackageId`" --source $PackageSource --scope $InstallScope --silent --accept-package-agreements --accept-source-agreements"
                
                # Execute
                $process = Start-Process -FilePath $winget -ArgumentList $arguments -Wait -PassThru -NoNewWindow
                
                return @{
                    Success = ($process.ExitCode -eq 0 -or $process.ExitCode -eq -1978335189)
                    ExitCode = $process.ExitCode
                    Message = "Exit code: $($process.ExitCode)"
                }
                
            } catch {
                return @{
                    Success = $false
                    ExitCode = -1
                    Message = $_.Exception.Message
                }
            }
        }
        
        Write-Host "  → Installing ($wingetScope scope)..." -ForegroundColor Yellow
        $result = Invoke-ScriptBlockAs -ScriptBlock $installScript -Credential $Credential -ArgumentList $Id, $Source, $wingetScope
        
        # Interpret exit codes
        switch ($result.ExitCode) {
            0 {
                Write-Host "  → Installed successfully ✓" -ForegroundColor Green
            }
            -1978335189 {
                Write-Host "  → Already installed ✓" -ForegroundColor Yellow
            }
            -1978335212 {
                Write-Host "  → Package not found ✗" -ForegroundColor Red
                throw "Package not found: $Id"
            }
            -1978335135 {
                Write-Host "  → No applicable installer ✗" -ForegroundColor Red
                throw "No applicable installer for: $Id"
            }
            default {
                Write-Host "  → Failed (exit code: $($result.ExitCode)) ✗" -ForegroundColor Red
                throw "Installation failed: $($result.Message)"
            }
        }
        
    } catch {
        Write-Host "  → ERROR: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}