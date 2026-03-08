function Get-CheckPointInfo {
    <#
    .SYNOPSIS
        Retrieves Check Point Endpoint Security connection information

    .DESCRIPTION
        Gets detailed connection information from Check Point Endpoint Security client including
        connection status, gateway list, and configuration details. Parses the output from trac.exe
        into structured objects.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .PARAMETER sitename
        Optional site name to filter results.

    .OUTPUTS
        [PSCustomObject[]]. Array of objects with connection details and gateway lists.

    .EXAMPLE
        Get-CheckPointInfo

    .EXAMPLE
        Get-CheckPointInfo -sitename "Corporate VPN"

    .EXAMPLE
        $info = Get-CheckPointInfo
        $info | ForEach-Object { Write-Host "Connection: $($_.Connection)"; $_.gateway_list }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe,
        [string]$sitename
    )
    $checkpointTracExeResult = Get-CheckPointTracInfo @PSBoundParameters
    if ($checkpointTracExeResult) {
        $i = 0
        [array]$arrayConnectionIndex = @()
        $checkpointTracExeResult | ForEach-Object {
            $item = $_.Trim()
            if ($item -match "^Conn ([^:]+):$") {
                $arrayConnectionIndex += ($i)
            }
            if ($item -match "^gateway list:$") {
                $arrayConnectionIndex += ($i)
            }
            $i++
        }
        for ($i = 0; $i -lt $arrayConnectionIndex.Count; $i += 2) {
            $connLine = $checkpointTracExeResult[$arrayConnectionIndex[$i]].Trim()
            $connName = if ($connLine -match "^Conn ([^:]+):$") { $Matches.1 } else { "" }
            $newObject = @{Connection = $connName}
            for ($j = $arrayConnectionIndex[$i] + 1; $j -lt $arrayConnectionIndex[$i + 1]; $j++) {
                if ($checkpointTracExeResult[$j].Trim() -match "^([^:]+):(.+)$") {
                    $propertyName = ($Matches.1).Trim()
                    $propertyValue = ($Matches.2).Trim()
                    $newObject.Add($propertyName.Replace(" ", "_"), $propertyValue)
                }
            }
            $jmax = if ($i -eq ($arrayConnectionIndex.Count - 2)) {$checkpointTracExeResult.Count} else {$arrayConnectionIndex[$i + 2]}
            [hashtable]$gatewaysObject = @{}
            for ($j = $arrayConnectionIndex[$i + 1] + 1; $j -lt $jmax; $j++) {
                if ($checkpointTracExeResult[$j].Trim() -match "^(\*)?\(([a-zA-Z]+)\)( |`t)+(.+)$") {
                    $gatewayName = $Matches.4
                    $gatewayStatus = $Matches.2
                    $mainGateway = $Matches.1 -eq "*"
                    $newPSO = New-Object PSObject -Property @{Status = $gatewayStatus
                                                              MainGateway = $mainGateway}
                    $gatewaysObject.Add($gatewayName, $newPSO)
                }
            }
            $newObject.Add("gateway_list", $(New-Object PSObject -Property $gatewaysObject))
            New-Object PSObject -Property $newObject
        }
    }
}
