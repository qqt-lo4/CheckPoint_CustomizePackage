class connectedFirewall {
    [string]$name
    [string]$status 
    [boolean]$main 

    connectedFirewall([string]$name, [string]$status, [boolean]$main) {
        $this.name = $name
        $this.status = $status
        $this.main = $main
    }

    [string]ToString() {
        return $this.name + " Status=" + $this.status + ", Main=" + $this.main
    }
}

class checkpointSiteInfo {
    [string]$connectionName
    [hashtable]$properties
    [hashtable]$gatewayList

    checkpointSiteInfo([string]$connectionName) {
        $this.connectionName = $connectionName
        $this.properties = @{}
        $this.gatewayList = @{}
    }
}

function Get-SiteInfo {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),
        [string]$sitename
    )
    [checkpointSiteInfo]$result = New-Object checkpointSiteInfo($sitename)
    $infos = $(Get-CheckPointTracInfo -tracexe $tracexe -sitename $sitename)
    $infos | ForEach-Object {   
                                switch -Regex ($_) {
                                    "^([^:]+):(.*)$" {
                                                        [string]$property = $($Matches.1).Trim()
                                                        [string]$value = $($Matches.2).Trim()
                                                        if ($value -ne "") {
                                                            $result.properties.add($property, $value)
                                                        }
                                                     }
                                    "^\t( |\*)\(([a-zA-Z]+)\)\t([a-zA-Z0-9]+)$" {
                                                        $gw_name = $Matches.3
                                                        $gw_status = $Matches.2
                                                        $gw_main = $($Matches.1 -eq "*")
                                                        $gw = New-Object connectedFirewall($gw_name, $gw_status, $gw_main)
                                                        $result.gatewayList.Add($gw_name, $gw)
                                                     }
                                }
                            }
    return $result
}