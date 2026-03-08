function Get-CheckPointTracDefaults {
    <#
    .SYNOPSIS
        Retrieves the path to the Check Point trac.defaults configuration file

    .DESCRIPTION
        Gets the full path to the trac.defaults configuration file from the Check Point
        Endpoint Security installation directory using registry information.

    .PARAMETER regkey
        Registry key object for Check Point installation. If not specified, retrieved automatically.

    .OUTPUTS
        [String]. Full path to the trac.defaults file.

    .EXAMPLE
        Get-CheckPointTracDefaults

    .EXAMPLE
        $regkey = Get-CheckPointRegKey
        Get-CheckPointTracDefaults -regkey $regkey

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    return $(Get-CheckPointFile -regkey $regkey -filename "trac.defaults")
}