function Invoke-MSTSC {
    <#
    .SYNOPSIS
        Launches a Remote Desktop (MSTSC) session

    .DESCRIPTION
        Opens a Remote Desktop connection to a remote computer with options
        for full screen, multi-monitor, and admin session.

    .PARAMETER Computer
        The remote computer name or IP address.

    .PARAMETER FullScreen
        Launch in full screen mode.

    .PARAMETER MultiMon
        Enable multi-monitor mode.

    .PARAMETER Admin
        Connect to the admin session.

    .EXAMPLE
        Invoke-MSTSC -Computer "SERVER01" -FullScreen

    .EXAMPLE
        Invoke-MSTSC -Computer "SERVER01" -Admin -MultiMon

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Computer,
        [Alias("f")]
        [switch]$FullScreen,
        [Alias("MultiScreen")]
        [switch]$MultiMon,
        [switch]$Admin
    )
    $aArgs = @()
    $aArgs += "/v:$Computer"
    if ($FullScreen) {
        $aArgs += "/f"
    }
    if ($MultiMon) {
        $aArgs += "/multimon"
    }
    if ($Admin) {
        $aArgs += "/admin"
    }
    &mstsc $aArgs
}
