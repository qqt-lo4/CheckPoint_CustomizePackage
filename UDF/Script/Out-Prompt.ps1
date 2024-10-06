function Out-Prompt {
    Param(
        [Parameter(Mandatory, Position=0, ValueFromPipeline)]
        $message,
        [Parameter(Position=1)]
        [string]$logfile,
        [switch]$appendDate,
        [string]$dateFormat = "yyyy-MM-dd HH:mm:ss"
    )
    if ($logfile) {
        if ($appendDate.IsPresent) {
            if ($message.Contains("`n")) {
                $logitem = $(Get-Date -Format $dateFormat) + " :`n" + $message
            } else {
                $logitem = $(Get-Date -Format $dateFormat) + " - " + $message
            }
            $logitem | Out-File -Append $logfile
        } else {
            $message | Out-File -FilePath $logfile -Append             
        }        
    }
    Write-Host $message
}
