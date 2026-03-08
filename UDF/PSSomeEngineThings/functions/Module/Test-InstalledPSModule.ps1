function Test-InstalledPSModule {
    <#
    .SYNOPSIS
        Tests if a PowerShell module is installed
    
    .DESCRIPTION
        Checks if a PowerShell module is installed using multiple detection methods
    
    .PARAMETER Name
        Name of the module to check
    
    .PARAMETER MinimumVersion
        Minimum version required (optional)
    
    .EXAMPLE
        Test-InstalledPSModule -Name "Microsoft.WinGet.Client"
        Returns $true if module is installed, $false otherwise
    
    .EXAMPLE
        Test-InstalledPSModule -Name "PSReadLine" -MinimumVersion "2.0.0"
        Tests if module is installed with at least version 2.0.0
    
    .OUTPUTS
        System.Boolean

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    
    Param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [version]$MinimumVersion
    )
    
    try {
        $module = $null
        
        # Try with Get-PSResource first (PowerShellGet v3)
        try {
            $module = Get-PSResource -Name $Name -ErrorAction SilentlyContinue | Select-Object -First 1
        } catch {
            # Get-PSResource might not be available
        }
        
        # Fallback to Get-Module -ListAvailable (classic method)
        if (-not $module) {
            $module = Get-Module -Name $Name -ListAvailable -ErrorAction SilentlyContinue | Select-Object -First 1
        }
        
        if (-not $module) {
            Write-Verbose "Module '$Name' is not installed"
            return $false
        }
        
        # Check version if specified
        if ($MinimumVersion) {
            $installedVersion = [version]$module.Version
            if ($installedVersion -lt $MinimumVersion) {
                Write-Verbose "Module '$Name' version $installedVersion is installed but version $MinimumVersion or higher is required"
                return $false
            }
        }
        
        Write-Verbose "Module '$Name' version $($module.Version) is installed"
        return $true
        
    } catch {
        Write-Error "Error checking module '$Name': $($_.Exception.Message)"
        return $false
    }
}