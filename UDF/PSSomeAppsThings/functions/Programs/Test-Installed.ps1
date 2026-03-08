function Test-Installed {
    <#
    .SYNOPSIS
        Tests if a program is installed

    .DESCRIPTION
        Checks the Windows uninstall registry keys to determine if a program
        is installed, either by display name or MSI product code.

    .PARAMETER ProgramName
        The display name of the program to check (supports wildcards)

    .PARAMETER ProductCode
        The MSI product code GUID to check

    .OUTPUTS
        System.Boolean. True if the program is found in the registry.

    .EXAMPLE
        Test-Installed -ProgramName "Google Chrome*"

    .EXAMPLE
        Test-Installed -ProductCode "{GUID-HERE}"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ParameterSetName = "Name")]
        [string]$ProgramName,
        [Parameter(Mandatory, ParameterSetName = "productcode")]
        [string]$ProductCode
    )
    switch ($PSCmdlet.ParameterSetName) {
        "Name" {
            $regKey = Get-ApplicationUninstallRegKey -valueData $ProgramName
            return $($null -ne $regKey)        
        }
        "productcode" {
            $regKey = Get-ApplicationUninstallRegKey -productCode $ProductCode
            return $($null -ne $regKey)
        }
    }
}
