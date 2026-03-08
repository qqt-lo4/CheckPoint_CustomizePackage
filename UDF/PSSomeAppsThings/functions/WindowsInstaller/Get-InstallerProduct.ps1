function Get-InstallerProduct {
    <#
    .SYNOPSIS
        Gets Windows Installer product entries from the registry

    .DESCRIPTION
        Retrieves all product entries from the HKCR:\Installer\Products registry hive,
        which contains metadata about MSI-installed products.

    .PARAMETER Guid
        Optional product GUID to filter results

    .OUTPUTS
        Microsoft.Win32.RegistryKey[]. Windows Installer product registry keys.

    .EXAMPLE
        Get-InstallerProduct

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [guid]$Guid
    )
    
    if (-not (Test-PSDrive "HKCR")) {
        New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
    }

    Get-ChildItem "hkcr:\Installer\Products"
}
