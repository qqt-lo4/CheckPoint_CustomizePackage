function Stop-CheckPointService {
    <#
    .SYNOPSIS
        Stops the Check Point Endpoint Security service

    .DESCRIPTION
        Stops the Check Point VPN/Endpoint Security service using trac.exe stop command.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .OUTPUTS
        None. Executes trac.exe to stop the service.

    .EXAMPLE
        Stop-CheckPointService

    .EXAMPLE
        Stop-CheckPointService -tracexe "C:\Program Files\CheckPoint\Endpoint\trac.exe"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $(& $tracexe "stop")
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}