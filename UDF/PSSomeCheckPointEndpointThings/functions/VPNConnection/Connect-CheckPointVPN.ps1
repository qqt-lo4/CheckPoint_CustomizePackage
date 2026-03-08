function Connect-CheckPointVPN {
    <#
    .SYNOPSIS
        Connects to a Check Point VPN site

    .DESCRIPTION
        Establishes a VPN connection to a Check Point site using trac.exe with username and password authentication.
        Returns a result object indicating success and command output.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .PARAMETER SiteName
        Name of the VPN site to connect to.

    .PARAMETER Username
        Username for authentication.

    .PARAMETER Password
        Password for authentication.

    .OUTPUTS
        [PSCustomObject]. Object with Success (boolean) and CommandResult (string array) properties.

    .EXAMPLE
        Connect-CheckPointVPN -SiteName "Corporate VPN" -Username "user@company.com" -Password "MyPassword"

    .EXAMPLE
        $result = Connect-CheckPointVPN -SiteName "Office" -Username "jdoe" -Password "P@ssw0rd"
        if ($result.Success) { Write-Host "Connected successfully" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$SiteName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Password
    )

    if (Test-Path -Path $tracexe -PathType Leaf) {
        $sResult = $(& $tracexe "connect" "-s" $sitename "-u" $Username "-p" $Password)
        $bSuccess = $sResult[-1] -eq "Connection was successfully established"
        return New-Object PSObject -Property @{
            "Success" = $bSuccess
            "CommandResult" = $sResult
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}