function Get-CheckPointTracInfo {
    <#
    .SYNOPSIS
        Retrieves Check Point trac information

    .DESCRIPTION
        Executes "trac.exe info" to get raw connection and gateway information from
        Check Point Endpoint Security. Optionally filters by site name.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .PARAMETER sitename
        Optional site name to filter information.

    .OUTPUTS
        [String[]]. Raw output lines from trac.exe info command.

    .EXAMPLE
        Get-CheckPointTracInfo

    .EXAMPLE
        Get-CheckPointTracInfo -sitename "Corporate VPN"

    .EXAMPLE
        $info = Get-CheckPointTracInfo
        $info | Select-String "Connected"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),
        [string]$sitename
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        if ($sitename) {
            $(& $tracexe "info" "-s" $sitename)
        } else {
            $(& $tracexe "info")
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}
