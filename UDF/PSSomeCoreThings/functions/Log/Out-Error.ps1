function Out-Error {
    <#
    .SYNOPSIS
        Writes an error message and exception details to host and log file

    .DESCRIPTION
        Outputs an error message and exception reason to the console,
        and appends them to a log file if a path is provided.

    .PARAMETER message
        The error message to display and log.

    .PARAMETER e
        The ErrorRecord object containing exception details.

    .PARAMETER logfile
        Path to the log file. If not specified, only writes to host.

    .PARAMETER appendDate
        Prepends a timestamp to the log file entry.

    .PARAMETER dateFormat
        Date format string (default: "yyyy-MM-dd HH:mm:ss").

    .EXAMPLE
        try { 1/0 } catch { Out-Error "Division failed" -e $_ -logfile "C:\Logs\app.log" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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