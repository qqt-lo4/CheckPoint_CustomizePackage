function Wait-ServiceStatus {
    <#
    .SYNOPSIS
        Waits for a service to reach a specified status

    .DESCRIPTION
        Polls a service at 100ms intervals until it reaches the expected status
        or the timeout expires.

    .PARAMETER Name
        The service name to monitor.

    .PARAMETER Status
        The expected status to wait for (e.g., "Running", "Stopped").

    .PARAMETER Timeout
        Maximum wait time in milliseconds. Default: 20000.

    .OUTPUTS
        [PSCustomObject]. Object with Timeout, NewStatus, ExpectedStatus, and Success properties.

    .EXAMPLE
        Wait-ServiceStatus -Name "Spooler" -Status "Running"

    .EXAMPLE
        Wait-ServiceStatus -Name "Spooler" -Status "Stopped" -Timeout 10000

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,
        [Parameter(Mandatory, Position = 1)]
        [string]$Status,
        [Parameter(Position = 2)]
        [int]$Timeout = 20000
    )
    $timoutRemaining = $Timeout
    While (($(Get-Service -Name $Name).Status -ne $Status) -and ($timoutRemaining -gt 0)) {
        $timoutRemaining = $timoutRemaining - 100
        Start-Sleep -Milliseconds 100
    }
    $newStatus = $(Get-Service -Name $Name).Status
    Return [PSCustomObject]@{
        Timeout = $timoutRemaining
        NewStatus = $newStatus
        ExpectedStatus = $Status
        Success = $($newStatus -eq $Status)
    }
}
