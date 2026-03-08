<#
.SYNOPSIS
    Defines log level severity values for the logging framework

.DESCRIPTION
    Enumeration of log levels used by Set-LogInfo and Write-LogInfo.
    Lower values indicate higher severity. Info and Host share the same level.

.NOTES
    Author  : Loïc Ade
    Version : 1.0.0
#>

enum LogLevel {
    Error = 1
    Warning = 2
    Info = 3
    Host = 3
    Verbose = 4
    Debug = 5
}