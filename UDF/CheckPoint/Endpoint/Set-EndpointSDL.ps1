function Set-EndpointSDL {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),
        [ValidateSet("disabled", "enaled")]
        [string]$loglevel
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        if ($loglevel -eq "disabled") {
            $(& $tracexe "sdl" "-st" "disable")
        } else {
            $(& $tracexe "sdl" "-st" "enable")
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}
