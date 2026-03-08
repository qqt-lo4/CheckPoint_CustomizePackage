function Get-CheckPointRegKey {
    <#
    .SYNOPSIS
        Retrieves the Check Point registry key

    .DESCRIPTION
        Gets the Windows registry key for Check Point VPN or Check Point Endpoint Security
        from the uninstall registry location.

    .OUTPUTS
        [Microsoft.Win32.RegistryKey[]]. Registry key(s) for Check Point installation.

    .EXAMPLE
        Get-CheckPointRegKey

    .EXAMPLE
        $regkey = Get-CheckPointRegKey
        $regkey.GetValue("InstallLocation")

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [OutputType([Microsoft.Win32.RegistryKey[]])]
    Param()
    return Get-ApplicationUninstallRegKey -valueName "DisplayName" -valueData @("Check Point VPN", "Check Point Endpoint Security")
}