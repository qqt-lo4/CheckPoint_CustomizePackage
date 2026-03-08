function Install-PSModule {
    <#
    .SYNOPSIS
        Installs a PowerShell module with permission and credential management
    
    .PARAMETER Name
        Name of the module to install
    
    .PARAMETER Scope
        Installation scope: CurrentUser or AllUsers (default: CurrentUser)
    
    .PARAMETER Credential
        Administrator credentials for AllUsers installation (required if non-admin)
    
    .PARAMETER TrustRepository
        Automatically trust the repository (default: $true)
    
    .EXAMPLE
        Install-PSModule -Name "powershell-yaml" -Scope AllUsers -Credential $cred

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]$Scope = "CurrentUser",
        
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter(Mandatory=$false)]
        [bool]$TrustRepository = $true
    )
    
    try {
        # Check if module is already installed
        $installedModule = Get-Module -ListAvailable -Name $Name | Select-Object -First 1
        
        if ($installedModule) {
            Write-Host "Module '$Name' already installed (version $($installedModule.Version))." -ForegroundColor Green
            return $true
        }
        
        Write-Host "Installing module '$Name' (Scope: $Scope)..." -ForegroundColor Yellow
        
        # If Scope = AllUsers, check permissions
        if ($Scope -eq "AllUsers") {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            if (-not $isAdmin -and -not $Credential) {
                throw "Installation in 'AllUsers' scope requires administrator rights. Please provide -Credential parameter or run the script as administrator."
            }
            
            if ($Credential) {
                Write-Host "Installing with provided credentials..." -ForegroundColor Yellow
                
                # ScriptBlock with explicit parameters - USE Install-Module instead of Install-PSResource
                $installScript = {
                    param(
                        [string]$ModuleName,
                        [bool]$Trust
                    )
                    
                    $ErrorActionPreference = 'Stop'
                    
                    try {
                        # Check if already installed in this context
                        $existing = Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1
                        if ($existing) {
                            return @{
                                Success = $true
                                Message = "Module already installed (version $($existing.Version))"
                            }
                        }
                        
                        # Configure repository trust
                        if ($Trust) {
                            $repo = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
                            if ($repo -and $repo.InstallationPolicy -ne 'Trusted') {
                                Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
                            }
                        }
                        
                        # Install module using Install-Module (compatible across all contexts)
                        Install-Module -Name $ModuleName -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck -Confirm:$false
                        
                        return @{
                            Success = $true
                            Message = "Module installed successfully"
                        }
                    } catch {
                        return @{
                            Success = $false
                            Message = $_.Exception.Message
                        }
                    }
                }
                
                # Pass arguments explicitly
                $result = Invoke-ScriptBlockAs -ScriptBlock $installScript -Credential $Credential -ArgumentList $Name, $TrustRepository
                
                if ($result.Success) {
                    Write-Host "Module '$Name' installed successfully." -ForegroundColor Green
                    return $true
                } else {
                    throw "Installation failed: $($result.Message)"
                }
                
            } else {
                # Already admin, install directly
                Write-Host "Direct installation (admin rights detected)..." -ForegroundColor Cyan
                
                if ($TrustRepository) {
                    $oRepository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
                    if ($oRepository -and $oRepository.InstallationPolicy -ne 'Trusted') {
                        Set-PSRepository PSGallery -InstallationPolicy Trusted
                    }
                }
                
                Install-Module -Name $Name -Scope AllUsers -Force -AllowClobber -SkipPublisherCheck
                Write-Host "Module '$Name' installed successfully." -ForegroundColor Green
                return $true
            }
            
        } else {
            # Scope = CurrentUser, no admin rights needed
            Write-Host "Installing for current user..." -ForegroundColor Cyan
            
            if ($TrustRepository) {
                $oRepository = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
                if ($oRepository -and $oRepository.InstallationPolicy -ne 'Trusted') {
                    Set-PSRepository PSGallery -InstallationPolicy Trusted
                }
            }
            
            Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck
            Write-Host "Module '$Name' installed successfully." -ForegroundColor Green
            return $true
        }
        
    } catch {
        Write-Error "Error installing module '$Name': $($_.Exception.Message)"
        throw
    }
}