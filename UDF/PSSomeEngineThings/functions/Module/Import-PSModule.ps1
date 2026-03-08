function Import-PSModule {
    <#
    .SYNOPSIS
        Imports a PowerShell module, installing it if necessary

    .DESCRIPTION
        Checks if a PowerShell module is installed, installs it if missing, and then imports
        it into the current session. Installs to CurrentUser scope by default.

    .PARAMETER Name
        Name of the module to import.

    .OUTPUTS
        None. Imports the module into the current session.

    .EXAMPLE
        Import-PSModule -Name "Microsoft.WinGet.Client"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
    if (-not (Test-InstalledPSModule -Name $Name)) {
        Write-Host "$Name module..." -ForegroundColor Yellow
        Install-PSModule -Name $Name -Scope CurrentUser | Out-Null
    }

    if (-not (Test-InstalledPSModule -Name $Name)) {
        throw "$Name module not installed"
    }
    
    if (-not (Get-Module -Name "$Name")) {
        Import-Module $Name -ErrorAction Stop
    }
}