function Get-CheckPointRegKey {
    [OutputType([Microsoft.Win32.RegistryKey[]])]
    Param()
    return Get-ApplicationUninstallRegKey -valueName "DisplayName" -valueData @("Check Point VPN", "Check Point Endpoint Security")
}