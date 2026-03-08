function Restart-Teams {
    <#
    .SYNOPSIS
        Restarts Microsoft Teams

    .DESCRIPTION
        Stops all running Teams processes and relaunches Teams via the
        Update.exe bootstrapper.

    .EXAMPLE
        Restart-Teams

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

     # Stop Teams
    Get-Process "Teams" -ErrorAction SilentlyContinue | Stop-Process
    # start Teams
    Start-Process -File $env:LOCALAPPDATA\Microsoft\Teams\Update.exe -ArgumentList '--processStart "Teams.exe"'
}