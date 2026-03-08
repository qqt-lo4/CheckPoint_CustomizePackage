$MSI_ERROR_SUCCESS = 0
$MSI_ERROR_SUCCESS_REBOOT_INITIATED = 1641
$MSI_ERROR_SUCCESS_REBOOT_REQUIRED = 3010
function Test-MSISuccess {
    <#
    .SYNOPSIS
        Tests if an MSI return code indicates success

    .DESCRIPTION
        Evaluates an MSI installer return code against known success values:
        0 (SUCCESS), 1641 (SUCCESS_REBOOT_INITIATED), 3010 (SUCCESS_REBOOT_REQUIRED).

    .PARAMETER msiReturnCode
        The MSI installer exit code to evaluate

    .OUTPUTS
        System.Boolean. True if the return code indicates success.

    .EXAMPLE
        if (Test-MSISuccess $LASTEXITCODE) { Write-Host "Installation succeeded" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [int]$msiReturnCode
    )
    return (($msiReturnCode -eq $MSI_ERROR_SUCCESS) `
        -or ($msiReturnCode -eq $MSI_ERROR_SUCCESS_REBOOT_INITIATED) `
        -or ($msiReturnCode -eq $MSI_ERROR_SUCCESS_REBOOT_REQUIRED)) 
}