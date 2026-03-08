function Out-Prompt {
    <#
    .SYNOPSIS
        Writes a message to the host and optionally to a log file

    .DESCRIPTION
        Outputs a message to the console via Write-Host and appends it to a log file
        if a path is provided. Supports optional date prefix formatting.

    .PARAMETER message
        The message to display and log.

    .PARAMETER logfile
        Path to the log file. If not specified, only writes to host.

    .PARAMETER appendDate
        Prepends a timestamp to the log file entry.

    .PARAMETER dateFormat
        Date format string (default: "yyyy-MM-dd HH:mm:ss").

    .EXAMPLE
        Out-Prompt "Processing started"

    .EXAMPLE
        Out-Prompt "Step completed" -logfile "C:\Logs\app.log" -appendDate

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

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
