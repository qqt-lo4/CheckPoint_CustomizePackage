function Get-CheckPointVersion {
    <#
    .SYNOPSIS
        Retrieves the Check Point version

    .DESCRIPTION
        Gets the Check Point Endpoint Security version number from the Windows registry.

    .PARAMETER regkey
        Registry key object for Check Point installation. If not specified, retrieved automatically.

    .OUTPUTS
        [String]. Check Point version number.

    .EXAMPLE
        Get-CheckPointVersion

    .EXAMPLE
        $version = Get-CheckPointVersion
        Write-Host "Check Point version: $version"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    if ($regkey -and ($regkey -isnot [array])) {
        $regkey.GetValue("DisplayVersion")
    } else {
        return ""
    }
}