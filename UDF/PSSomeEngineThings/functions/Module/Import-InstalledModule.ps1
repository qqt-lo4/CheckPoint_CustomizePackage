function Import-InstalledModule {
    <#
    .SYNOPSIS
        Imports an already installed PowerShell module

    .DESCRIPTION
        Verifies that a PowerShell module is installed and imports it into the current session.
        Throws an error if the module is not installed.

    .PARAMETER Name
        Name of the module to import.

    .OUTPUTS
        None. Imports the module into the current session.

    .EXAMPLE
        Import-InstalledModule -Name "powershell-yaml"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
    if (-not (Test-InstalledPSModule -Name $Name)) {
        throw "$Name module not installed"
    }
    
    if (-not (Get-Module -Name "$Name")) {
        Import-Module $Name -ErrorAction Stop
    }
}