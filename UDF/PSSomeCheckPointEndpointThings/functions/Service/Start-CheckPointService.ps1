function Start-CheckPointService {
    <#
    .SYNOPSIS
        Starts the Check Point Endpoint Security service

    .DESCRIPTION
        Starts the Check Point VPN/Endpoint Security service using trac.exe start command.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .OUTPUTS
        None. Executes trac.exe to start the service.

    .EXAMPLE
        Start-CheckPointService

    .EXAMPLE
        Start-CheckPointService -tracexe "C:\Program Files\CheckPoint\Endpoint\trac.exe"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $(& $tracexe "start")
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}
