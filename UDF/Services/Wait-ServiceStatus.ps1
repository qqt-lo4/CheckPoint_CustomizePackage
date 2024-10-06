function Wait-ServiceStatus {
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
