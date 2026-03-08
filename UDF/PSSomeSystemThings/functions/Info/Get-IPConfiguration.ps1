function Get-IPConfiguration {
    <#
    .SYNOPSIS
        Retrieves IP configuration for active network interfaces

    .DESCRIPTION
        Returns IPv4 configuration details including IP address, gateway, DNS servers,
        and DHCP status for interfaces that have an IPv4 address assigned.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [PSCustomObject[]]. Objects with InterfaceName, IPAddress, Gateway, DNSServers, DHCPEnabled, etc.

    .EXAMPLE
        Get-IPConfiguration

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "None")]
    Param(
        [Parameter(ParameterSetName = "userpasswd")]
        [string]$ComputerName,
        [Parameter(ParameterSetName = "userpasswd")]
        [pscredential]$Credential,
        [Parameter(ParameterSetName = "pssession")]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    $oScriptBlock = {
        Get-NetIPConfiguration | Where-Object { $_.IPv4Address } | ForEach-Object {
            $interface = $_
            $dhcp = Get-NetIPAddress -InterfaceIndex $interface.InterfaceIndex -AddressFamily IPv4 | 
                    Select-Object -ExpandProperty PrefixOrigin
            
            [PSCustomObject]@{
                InterfaceName  = $interface.InterfaceAlias
                InterfaceIndex = $interface.InterfaceIndex
                ConfigType     = if ($dhcp -eq "Dhcp") { "DHCP" } else { "Manual IP" }
                DHCPEnabled    = ($dhcp -eq "Dhcp")
                IPAddress      = $interface.IPv4Address.IPAddress
                PrefixLength   = $interface.IPv4Address.PrefixLength
                Gateway        = $interface.IPv4DefaultGateway.NextHop
                DNSServers     = $interface.DNSServer.ServerAddresses -join ", "
            }
        }
    }    
    Invoke-Command @PSBoundParameters -ScriptBlock $oScriptBlock
}
