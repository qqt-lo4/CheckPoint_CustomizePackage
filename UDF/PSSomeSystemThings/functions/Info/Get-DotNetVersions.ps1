function Get-DotNetVersions {
    <#
    .SYNOPSIS
        Retrieves installed .NET Framework versions

    .DESCRIPTION
        Checks the registry for installed .NET Framework versions (1.0 through 4.8+).
        Supports remote execution via ComputerName, Credential, or PSSession.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [PSObject]. Object with boolean properties for each .NET version and a version string for 4.5+.

    .EXAMPLE
        Get-DotNetVersions

    .EXAMPLE
        Get-DotNetVersions -ComputerName "SERVER01"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    $regKeyDotNet10 = Get-ChildItemRec @PSBoundParameters -path "hklm:\SOFTWARE\Microsoft\.NETFramework\policy"
    $regKey = Get-ChildItemRec @PSBoundParameters -path "hklm:\SOFTWARE\Microsoft\NET Framework Setup"
    function Test-DotNetVersionInstalled {
        Param(
            [Parameter(Mandatory)]
            [object]$reg,
            [Parameter(Mandatory)]
            [string]$version
        )
        $dotnet = $reg.Children.NDP.Children.$version
        if ($dotnet) {
            return $dotnet.Property.Install -eq 1
        } else {
            return $false
        }
    }
    $dotnet10 = $regKeyDotNet10.Children."v1.0".Children."3705"
    $dotnet10Installed = if ($dotnet10) {
        $dotnet10.Property.Install -eq 1
    } else {
        $false
    }
    $dotnet11Installed = Test-DotNetVersionInstalled -reg $regKey -version "v1.1.4322"
    $dotnet20Installed = Test-DotNetVersionInstalled -reg $regKey -version "v2.0.50727"
    $dotnet30 = $regKey.Children.NDP.Children."v3.0".Children.Setup
    $dotnet30Installed = if ($dotnet30) {
        $dotnet30.Property.InstallSuccess -eq 1
    } else {
        $false
    }
    $dotnet35Installed = Test-DotNetVersionInstalled -reg $regKey -version "v3.5"
    $dotnet40Client = $regKey.Children.NDP.Children."v4".Children.Client
    $dotnet40ClientInstalled = if ($dotnet40Client) {
        $dotnet40Client.Property.Install -eq 1
    } else {
        $false
    }
    $dotnet40Full = $regKey.Children.NDP.Children."v4".Children.Full
    $dotnet40FullInstalled = if ($dotnet40Full) {
        $dotnet40Full.Property.Install -eq 1
    } else {
        $false
    }
    $dotnet45PlusInstalled = if ($dotnet40Full) {
        $null -ne $dotnet40Full.Property.Release 
    } else {
        $false
    }
    $dotnet45PlusVersion = if ($dotnet45PlusInstalled) {
        $dotnet45PlusRelease = $dotnet40Full.Property.Release
        if ($dotnet45PlusRelease -ge 528040) { "4.8 or later" }
        elseif ($dotnet45PlusRelease -ge 461808) { "4.7.2" }
        elseif ($dotnet45PlusRelease -ge 461308) { "4.7.1" }
        elseif ($dotnet45PlusRelease -ge 460798) { "4.7" }
        elseif ($dotnet45PlusRelease -ge 394802) { "4.6.2" }
        elseif ($dotnet45PlusRelease -ge 394254) { "4.6.1" }
        elseif ($dotnet45PlusRelease -ge 393295) { "4.6" }
        elseif ($dotnet45PlusRelease -ge 379893) { "4.5.2" }
        elseif ($dotnet45PlusRelease -ge 378675) { "4.5.1" }
        elseif ($dotnet45PlusRelease -ge 378389) { "4.5" }
        else {"No 4.5 or later version detected"}
    } else {
        "No 4.5 or later version detected";
    }
    $result = [ordered]@{
        "1.0" = $dotnet10Installed
        "1.1" = $dotnet11Installed
        "2.0" = $dotnet20Installed
        "3.0" = $dotnet30Installed
        "3.5" = $dotnet35Installed
        "4.0 Client Profile" = $dotnet40ClientInstalled
        "4.0 Full Profile" = $dotnet40FullInstalled
        "4.5+" = $dotnet45PlusInstalled
        "4.5+ version" = $dotnet45PlusVersion
    }
    return New-Object -TypeName psobject -Property $result
}
