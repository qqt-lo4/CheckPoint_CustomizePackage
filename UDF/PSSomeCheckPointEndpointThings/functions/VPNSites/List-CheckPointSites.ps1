function List-CheckPointSites {
    <#
    .SYNOPSIS
        Lists all configured Check Point VPN sites

    .DESCRIPTION
        Retrieves a list of all configured VPN site names from Check Point Endpoint Security
        by parsing the output from trac.exe info.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .OUTPUTS
        [String[]]. Array of VPN site names.

    .EXAMPLE
        List-CheckPointSites

    .EXAMPLE
        $sites = List-CheckPointSites
        $sites | ForEach-Object { Write-Host "Site: $_" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    $result = Get-CheckPointTracInfo -tracexe $tracexe | ForEach-Object { if ($_ -match "^Conn ([^:]+):") { return $Matches.1 } }
    $result
}