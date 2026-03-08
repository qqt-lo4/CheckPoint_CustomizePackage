function Show-CheckPointConnectGUI {
    <#
    .SYNOPSIS
        Shows the Check Point VPN connection GUI

    .DESCRIPTION
        Launches the Check Point VPN graphical connection interface (TrGUI) for a specific site.
        Optionally waits for the GUI window to open and close.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .PARAMETER sitename
        Name of the VPN site to display in the GUI.

    .PARAMETER waitOpenAndClose
        If specified, waits for the TrGUI window to open and then close before returning.

    .OUTPUTS
        None. Launches the Check Point GUI.

    .EXAMPLE
        Show-CheckPointConnectGUI -sitename "Corporate VPN"

    .EXAMPLE
        Show-CheckPointConnectGUI -sitename "Office VPN" -waitOpenAndClose

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),
        [Parameter(Mandatory)]
        [string]$sitename,
        [switch]$waitOpenAndClose
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $(&$tracexe "connectgui" "-s" $sitename)
        if ($waitOpenAndClose.IsPresent) {
            Wait-MainWindowFromProcessAppear -processName "TrGUI"
            Wait-MainWindowFromProcessClose -processName "TrGUI"
        }
    }
}