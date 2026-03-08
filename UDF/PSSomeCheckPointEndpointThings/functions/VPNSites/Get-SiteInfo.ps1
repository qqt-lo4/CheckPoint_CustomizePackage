<#
.SYNOPSIS
    Class representing a connected firewall in a Check Point VPN site

.DESCRIPTION
    Represents information about a firewall gateway including name, status, and whether it's the main gateway.

.NOTES
    Author  : Loïc Ade
    Version : 1.0.0
#>
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

<#
.SYNOPSIS
    Class representing Check Point VPN site information

.DESCRIPTION
    Container for VPN site information including connection name, properties, and gateway list.

.NOTES
    Author  : Loïc Ade
    Version : 1.0.0
#>
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
    <#
    .SYNOPSIS
        Retrieves detailed information about a Check Point VPN site

    .DESCRIPTION
        Gets comprehensive site information including properties and gateway list from Check Point VPN.
        Parses trac.exe info output into a structured checkpointSiteInfo object.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .PARAMETER sitename
        Name of the VPN site to query.

    .OUTPUTS
        [checkpointSiteInfo]. Object containing connection name, properties hashtable, and gatewayList hashtable.

    .EXAMPLE
        Get-SiteInfo -sitename "Corporate VPN"

    .EXAMPLE
        $siteInfo = Get-SiteInfo -sitename "Office"
        $siteInfo.properties
        $siteInfo.gatewayList

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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