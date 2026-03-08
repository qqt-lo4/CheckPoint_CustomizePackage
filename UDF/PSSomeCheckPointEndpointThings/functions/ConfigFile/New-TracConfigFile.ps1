function New-TracConfigFile {
    <#
    .SYNOPSIS
        Creates a new Check Point trac.config configuration file

    .DESCRIPTION
        Generates a trac.config XML configuration file for Check Point Endpoint Security VPN.
        The file contains site configuration including gateway hostname, display name, and authentication method.

    .PARAMETER Path
        Output path for the trac.config file. Can be a directory (file will be named trac.config) or full file path.

    .PARAMETER Site
        Gateway hostname or IP address for the VPN site.

    .PARAMETER DisplayName
        Display name for the VPN site shown in the client.

    .PARAMETER AuthenticationMethod
        Authentication method: "username-password" or "certificate".

    .OUTPUTS
        [String]. Full path to the created trac.config file.

    .EXAMPLE
        New-TracConfigFile -Path "C:\Temp" -Site "vpn.example.com" -DisplayName "Company VPN" -AuthenticationMethod "username-password"

    .EXAMPLE
        New-TracConfigFile -Path "C:\Config\trac.config" -Site "192.168.1.1" -DisplayName "Office VPN" -AuthenticationMethod "certificate"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Site,
        [Parameter(Mandatory)]
        [string]$DisplayName,
        [ValidateSet("username-password", "certificate")]
        [string]$AuthenticationMethod
    )
    $sContent = @"
<CONFIGURATION>
    <GW_USER gw="$DisplayName" user="USER">
        <FROM_USER>
            <PARAM display_name="$DisplayName"></PARAM>
            <PARAM gw_hostname="$Site"></PARAM>
            <PARAM gw_ipaddr="$Site"></PARAM>
            <PARAM authentication_method="$AuthenticationMethod"></PARAM>
        </FROM_USER>
    </GW_USER>
    <USER user="USER">
        <FROM_USER>
            <PARAM active_site="$DisplayName"></PARAM>
        </FROM_USER>
    </USER>
</CONFIGURATION>
"@
    $sResultPath = if (Test-Path -Path $Path -PathType Container) {
        $Path + "\trac.config"
    } else {
        $Path
    }
    $sContent | Out-File -FilePath $sResultPath
    return $sResultPath
}