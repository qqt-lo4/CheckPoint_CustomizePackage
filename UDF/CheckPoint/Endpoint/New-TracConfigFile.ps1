function New-TracConfigFile {
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