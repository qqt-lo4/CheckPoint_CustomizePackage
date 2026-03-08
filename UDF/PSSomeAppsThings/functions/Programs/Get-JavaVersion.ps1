function Get-JavaVersion {
    <#
    .SYNOPSIS
        Gets the installed Java Runtime Environment version

    .DESCRIPTION
        Queries installed programs to find 64-bit Java Runtime Environment entries
        and returns them sorted by version number (newest first).

    .PARAMETER ComputerName
        Remote computer name for remote execution

    .PARAMETER Credential
        Credentials for remote execution

    .PARAMETER Session
        Existing PSSession for remote execution

    .OUTPUTS
        PSCustomObject[]. Java program entries sorted by version descending.

    .EXAMPLE
        Get-JavaVersion

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    $allPrograms = Get-InstalledPrograms @PSBoundParameters
    $jre = $allPrograms | Where-Object { $_.Name -match "^Java [0-9]+ Update [0-9]+ \(64-bit\)$" }
    $jre | ForEach-Object { $_.Version = [version]$_.Version }
    $jre = $jre | Sort-Object -Property Version -Descending
    $jre
}