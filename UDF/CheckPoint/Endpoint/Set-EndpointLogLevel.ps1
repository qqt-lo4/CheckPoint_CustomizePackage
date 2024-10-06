function Set-EndpointLogLevel {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),
        [ValidateSet("disabled", "basic", "extended")]
        [string]$loglevel = "extended"
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        if ($loglevel -eq "disabled") {
            $(& $tracexe "disable_log")
        } else {
            $(& $tracexe "enable_log" "-m" $loglevel)
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}
