function Get-CheckPointTracInfo {
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
