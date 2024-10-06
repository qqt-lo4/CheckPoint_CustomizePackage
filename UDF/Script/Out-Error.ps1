function Out-Error {
    Param(
        [Parameter(Position=0)]
        $message,
        [Parameter(Position=1)]
        [System.Management.Automation.ErrorRecord]$e, 
        [Parameter(Position=2)]
        [string]$logfile,
        [switch]$appendDate,
        [string]$dateFormat = "yyyy-MM-dd HH:mm:ss"
    )
    Write-Host $message
    Write-Host "Reason: "$e.Exception.Message
    if ($logfile) {
        if ($appendDate.IsPresent) {
            $logheader = $(Get-Date -Format $dateFormat)
            if ($message.Contains("`n")) {
                $logitem = $logheader + " :`n" + $message
            } else {
                $logitem = $logheader + " - " + $message
            }
            $logitem | Out-File -Append $logfile
            $erroritem = $logheader + " - Reason: " + $($e | Out-String)
            $erroritem | Out-File -Append $logfile
        } else {
            $message | Out-File -Append $logfile
            $errorItem = "Reason: " + $($e | Out-String)
            $errorItem | Out-File -Append $logfile
        }
    }
}