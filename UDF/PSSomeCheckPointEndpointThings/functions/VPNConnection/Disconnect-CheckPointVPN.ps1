function Disconnect-CheckPointVPN {
    <#
    .SYNOPSIS
        Disconnects from a Check Point VPN site

    .DESCRIPTION
        Terminates the active VPN connection to a Check Point site using trac.exe.
        Returns a result object indicating success and command output.

    .PARAMETER tracexe
        Path to trac.exe executable. If not specified, retrieved automatically.

    .OUTPUTS
        [PSCustomObject]. Object with Success (boolean) and CommandResult (string array) properties.

    .EXAMPLE
        Disconnect-CheckPointVPN

    .EXAMPLE
        $result = Disconnect-CheckPointVPN
        if ($result.Success) { Write-Host "Disconnected successfully" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )

    if (Test-Path -Path $tracexe -PathType Leaf) {
        $sResult = $(& $tracexe "disconnect")
        $bSuccess = $sResult[-1] -eq "Connection was successfully disconnected"
        return New-Object PSObject -Property @{
            "Success" = $bSuccess
            "CommandResult" = $sResult
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}