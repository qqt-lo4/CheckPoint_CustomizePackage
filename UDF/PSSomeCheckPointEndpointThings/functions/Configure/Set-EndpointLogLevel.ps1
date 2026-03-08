function Set-EndpointLogLevel {
    <#
    .SYNOPSIS
        Sets the log level for Check Point Endpoint Security client

    .DESCRIPTION
        Configures the logging level for Check Point Endpoint Security using trac.exe.
        Supports three levels: disabled, basic, and extended. Extended provides the most detailed logging.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .PARAMETER loglevel
        Log level to set: "disabled", "basic", or "extended". Default: "extended".

    .OUTPUTS
        None. Executes trac.exe to set the log level.

    .EXAMPLE
        Set-EndpointLogLevel -loglevel "extended"

    .EXAMPLE
        Set-EndpointLogLevel -loglevel "disabled"

    .EXAMPLE
        Set-EndpointLogLevel -tracexe "C:\Program Files\CheckPoint\Endpoint\trac.exe" -loglevel "basic"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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
