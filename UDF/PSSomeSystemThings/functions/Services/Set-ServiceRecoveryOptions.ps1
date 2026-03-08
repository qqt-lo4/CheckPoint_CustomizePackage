function Set-ServiceRecovery{
    <#
    .SYNOPSIS
        Configures service recovery options on a remote server

    .DESCRIPTION
        Uses sc.exe to set failure recovery actions (restart, run, reboot, donothing)
        for a Windows service on a remote computer.

    .PARAMETER ServiceDisplayName
        The display name (or pattern) of the service to configure.

    .PARAMETER Server
        The remote server name.

    .PARAMETER action1
        First failure action. Default: "restart".

    .PARAMETER time1
        Delay before first action in milliseconds. Default: 30000.

    .PARAMETER action2
        Second failure action. Default: "restart".

    .PARAMETER time2
        Delay before second action in milliseconds. Default: 30000.

    .PARAMETER actionLast
        Subsequent failure action. Default: "restart".

    .PARAMETER timeLast
        Delay before subsequent action in milliseconds. Default: 30000.

    .PARAMETER resetCounter
        Time in seconds after which to reset the failure counter. Default: 4000.

    .OUTPUTS
        None. Configures recovery options via sc.exe.

    .EXAMPLE
        Set-ServiceRecovery -ServiceDisplayName "Print Spooler" -Server "SERVER01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [Alias('Set-Recovery')]
    Param(
        [string] [Parameter(Mandatory=$true)] $ServiceDisplayName,
        [string] [Parameter(Mandatory=$true)] $Server,
        [ValidateSet("run", "restart", "reboot", "donothing")]
        [string] $action1 = "restart",
        [int] $time1 =  30000, # in miliseconds
        [ValidateSet("run", "restart", "reboot", "donothing")]
        [string] $action2 = "restart",
        [int] $time2 =  30000, # in miliseconds
        [ValidateSet("run", "restart", "reboot", "donothing")]
        [string] $actionLast = "restart",
        [int] $timeLast = 30000, # in miliseconds
        [int] $resetCounter = 4000 # in seconds
    )
    $sServerPath = "\\" + $Server
    $aServices = Get-CimInstance -ClassName 'Win32_Service' -ComputerName $Server| Where-Object {$_.DisplayName -imatch $ServiceDisplayName}
    $sAction1 = if ($action1 -eq "donothing") { "" } else { $action1 }
    $sAction2 = if ($action2 -eq "donothing") { "" } else { $action2 }
    $sAction3 = if ($actionLast -eq "donothing") { "" } else { $actionLast }
    $sAction = $sAction1+"/"+$time1+"/"+$sAction2+"/"+$time2+"/"+$sAction3+"/"+$timeLast
    
    foreach ($service in $aServices){
        # https://technet.microsoft.com/en-us/library/cc742019.aspx
        $output = sc.exe $sServerPath failure $($service.Name) actions= $sAction reset= $resetCounter
    }
}