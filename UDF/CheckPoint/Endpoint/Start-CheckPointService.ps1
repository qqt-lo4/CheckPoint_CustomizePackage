function Start-CheckPointService {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $(& $tracexe "start")
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}
