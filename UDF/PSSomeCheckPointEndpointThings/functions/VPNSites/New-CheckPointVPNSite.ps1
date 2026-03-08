function New-CheckPointVPNSite {
    <#
    .SYNOPSIS
        Creates a new Check Point VPN site configuration

    .DESCRIPTION
        Creates a new VPN site in Check Point Endpoint Security using trac.exe create command.
        Supports various authentication methods and login options.

    .PARAMETER site
        Gateway hostname or IP address for the VPN site.

    .PARAMETER displayName
        Display name for the VPN site shown in the client.

    .PARAMETER authenticationMethod
        Authentication method: "username-password", "certificate", "p12-certificate", "challenge-response",
        "securIDKeyFob", "securIDPinPad", or "SoftID".

    .PARAMETER loginOption
        Login option string for the site.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .OUTPUTS
        [PSCustomObject]. Object with Success (boolean), Output (string array), and Site (string) properties.

    .EXAMPLE
        New-CheckPointVPNSite -site "vpn.example.com" -displayName "Company VPN" -authenticationMethod "username-password"

    .EXAMPLE
        New-CheckPointVPNSite -site "192.168.1.1" -authenticationMethod "certificate"

    .EXAMPLE
        $result = New-CheckPointVPNSite -site "vpn.office.com" -displayName "Office VPN" -loginOption "SSL" -tracexe "C:\Program Files\CheckPoint\trac.exe"
        if ($result.Success) { Write-Host "Site created: $($result.Site)" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "authMethod")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "LoginOption")]
        [string]$site,
        [Parameter(ParameterSetName = "authMethod")]
        [Parameter(ParameterSetName = "LoginOption")]
        [string]$displayName,
        [ValidateSet("username-password", "certificate", "p12-certificate", `
                     "challenge-response", "securIDKeyFob", "securIDPinPad", "SoftID")]
        [Parameter(Mandatory, ParameterSetName = "authMethod")]
        [string]$authenticationMethod,
        [Parameter(Mandatory, ParameterSetName = "LoginOption")]
        [string]$loginOption,
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $arguments = @("create", "-s", $site)
        if ($displayName) {
            $arguments += "-di"
            $arguments += $displayName
        }
        if ($loginOption) {
            $arguments += "-lo"
            $arguments += $loginOption
        }
        if ($authenticationMethod) {
            $arguments += "-a"
            $arguments += $authenticationMethod
        }
        $textOutput = $(& $tracexe @arguments)
        $outputLastLine = $textOutput[$textOutput.Count - 1].Trim().ToLower()
        $success = $($outputLastLine -eq "connection was successfully created")
        return New-Object psobject -Property @{
            Success = $success
            Output = $textOutput
            Site = $site
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}
