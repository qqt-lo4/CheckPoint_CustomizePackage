function Get-CheckPointProduct {
    <#
    .SYNOPSIS
        Retrieves the Check Point product name

    .DESCRIPTION
        Gets the Check Point Endpoint Security product display name from the Windows registry.

    .PARAMETER regkey
        Registry key object for Check Point installation. If not specified, retrieved automatically.

    .OUTPUTS
        [String]. Check Point product display name.

    .EXAMPLE
        Get-CheckPointProduct

    .EXAMPLE
        $regkey = Get-CheckPointRegKey
        Get-CheckPointProduct -regkey $regkey

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    if ($regkey -and ($regkey -isnot [array])) {
        $regkey.GetValue("DisplayName")
    } else {
        return ""
    }
}