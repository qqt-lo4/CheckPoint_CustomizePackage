function Get-CheckPointTracExe {
    <#
    .SYNOPSIS
        Retrieves the path to the Check Point trac.exe executable

    .DESCRIPTION
        Gets the full path to the trac.exe executable from the Check Point Endpoint Security
        installation directory using registry information.

    .PARAMETER regkey
        Registry key object for Check Point installation. If not specified, retrieved automatically.

    .OUTPUTS
        [String]. Full path to trac.exe.

    .EXAMPLE
        Get-CheckPointTracExe

    .EXAMPLE
        $tracExe = Get-CheckPointTracExe
        & $tracExe "show_conn"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    return $(Get-CheckPointFile -regkey $regkey -filename "trac.exe")
}