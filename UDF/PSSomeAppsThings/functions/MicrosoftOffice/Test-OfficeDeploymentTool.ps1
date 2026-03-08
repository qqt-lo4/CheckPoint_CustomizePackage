function Test-OfficeDeploymentTool {
    <#
    .SYNOPSIS
        Tests if Office Deployment Tool is installed

    .DESCRIPTION
        Checks if Office Deployment Tool is installed by searching for setup.exe.

    .OUTPUTS
        Returns $true if Office Deployment Tool is found, $false otherwise

    .EXAMPLE
        if (Test-OfficeDeploymentTool) {
            Write-Host "Office Deployment Tool is installed"
        }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param()

    $odtPath = Get-OfficeDeploymentToolPath
    return ($null -ne $odtPath)
}
