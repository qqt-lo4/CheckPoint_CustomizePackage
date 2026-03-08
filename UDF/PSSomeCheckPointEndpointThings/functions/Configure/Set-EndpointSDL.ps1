function Set-EndpointSDL {
    <#
    .SYNOPSIS
        Sets the SDL (Software Defined Logging) status for Check Point Endpoint Security

    .DESCRIPTION
        Enables or disables SDL (Software Defined Logging) for Check Point Endpoint Security using trac.exe.
        SDL allows dynamic control of logging components without restarting the client.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .PARAMETER loglevel
        SDL status: "disabled" or "enaled" (note: typo in original parameter).

    .OUTPUTS
        None. Executes trac.exe to set SDL status.

    .EXAMPLE
        Set-EndpointSDL -loglevel "enaled"

    .EXAMPLE
        Set-EndpointSDL -loglevel "disabled"

    .EXAMPLE
        Set-EndpointSDL -tracexe "C:\Program Files\CheckPoint\Endpoint\trac.exe" -loglevel "enaled"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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
