function Show-CheckPointConnectGUI {
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