function Start-Nmap {
    <#
    .SYNOPSIS
        Launches an Nmap scan via Zenmap

    .DESCRIPTION
        Starts an Nmap scan through the Zenmap GUI with predefined scan profiles
        (Intense, Quick, Ping, Traceroute, etc.). Automatically locates the Nmap
        installation if not provided.

    .PARAMETER Nmap
        Nmap object (from Find-NMap). Defaults to $Global:ExternalApps.Nmap or Find-NMap -Zenmap.

    .PARAMETER Target
        The target host, IP address, or subnet to scan.

    .PARAMETER IntenseScan
        Run an intense scan (-T4 -A -v).

    .PARAMETER IntenseScanPlusUDP
        Run an intense scan with UDP (-sS -sU -T4 -A -v).

    .PARAMETER IntenseScanAllTCP
        Run an intense scan on all TCP ports (-p 1-65535 -T4 -A -v).

    .PARAMETER IntenseScanNoPing
        Run an intense scan without ping (-T4 -A -v -Pn).

    .PARAMETER PingScan
        Run a ping scan (-sn).

    .PARAMETER QuickScan
        Run a quick scan (-T4 -F).

    .PARAMETER QuickScanPlus
        Run a quick scan with version detection (-sV -T4 -O -F --version-light).

    .PARAMETER QuickTraceroute
        Run a quick traceroute (-sn --traceroute).

    .PARAMETER RegularScan
        Run a regular scan (default).

    .PARAMETER SlowComprehensiveScan
        Run a slow comprehensive scan with scripts.

    .EXAMPLE
        Start-Nmap -Target "192.168.1.0/24" -QuickScan

    .EXAMPLE
        Start-Nmap -Target "10.0.0.1" -IntenseScan

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "RegularScan")]
    Param(
        [object]$Nmap,
        [Parameter(Mandatory, Position = 0, ParameterSetName = "InstenseScan")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "InstenseScanPlusUDP")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "InstenseScanAllTCP")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "InstenseScanNoPing")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "PingScan")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "QuickScan")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "QuickScanPlus")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "QuickTraceroute")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "RegularScan")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "SlowComprehensiveScan")]
        [string]$Target,
        [Parameter(ParameterSetName = "InstenseScan")]
        [switch]$IntenseScan,
        [Parameter(ParameterSetName = "InstenseScanPlusUDP")]
        [switch]$IntenseScanPlusUDP,
        [Parameter(ParameterSetName = "InstenseScanAllTCP")]
        [switch]$IntenseScanAllTCP,
        [Parameter(ParameterSetName = "InstenseScanNoPing")]
        [switch]$IntenseScanNoPing,
        [Parameter(ParameterSetName = "PingScan")]
        [switch]$PingScan,
        [Parameter(ParameterSetName = "QuickScan")]
        [switch]$QuickScan,
        [Parameter(ParameterSetName = "QuickScanPlus")]
        [switch]$QuickScanPlus,
        [Parameter(ParameterSetName = "QuickTraceroute")]
        [switch]$QuickTraceroute,
        [Parameter(ParameterSetName = "RegularScan")]
        [switch]$RegularScan,
        [Parameter(ParameterSetName = "SlowComprehensiveScan")]
        [switch]$SlowComprehensiveScan
    )
    Begin {
        $oNmap = if ($Nmap) {
            $Nmap
        } else {
            if (($Global:ExternalApps) -and ($Global:ExternalApps.Nmap)) {
                $Global:ExternalApps.Nmap
            } else {
                Find-Nmap -Zenmap
            }
        }
        $sOption = switch ($PSCmdlet.ParameterSetName) {
            "InstenseScan" { "-T4 -A -v" }
            "InstenseScanPlusUDP" { "-sS -sU -T4 -A -v" }
            "InstenseScanAllTCP" { "-p 1-65535 -T4 -A -v" }
            "InstenseScanNoPing" { "-T4 -A -v -Pn" }
            "PingScan" { "-sn" }
            "QuickScan" { "-T4 -F" }
            "QuickScanPlus" { "-sV -T4 -O -F --version-light" }
            "QuickTraceroute" { "-sn --traceroute" }
            "RegularScan" { "" }
            "SlowComprehensiveScan" { "-sS -sU -T4 -A -v -PE -PP -PS80,443 -PA3389 -PU40125 -PY -g 53 --script ""default or (discovery and safe)""" }
        }
    }
    Process {
        $sArguments = if ($oNmap.Arguments) { $oNmap.Arguments + " -n nmap $sOption $Target" } else { "$sOption $Target" }
        Start-Process -FilePath $oNmap.ExePath -ArgumentList $sArguments -WorkingDirectory $oNmap.ProgramPath | Out-Null
    }
}




