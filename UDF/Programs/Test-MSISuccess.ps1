$MSI_ERROR_SUCCESS = 0
$MSI_ERROR_SUCCESS_REBOOT_INITIATED = 1641
$MSI_ERROR_SUCCESS_REBOOT_REQUIRED = 3010
function Test-MSISuccess {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [int]$msiReturnCode
    )
    return (($msiReturnCode -eq $MSI_ERROR_SUCCESS) `
        -or ($msiReturnCode -eq $MSI_ERROR_SUCCESS_REBOOT_INITIATED) `
        -or ($msiReturnCode -eq $MSI_ERROR_SUCCESS_REBOOT_REQUIRED)) 
}