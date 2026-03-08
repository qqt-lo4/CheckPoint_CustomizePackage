function Get-SystemInfo {
    <#
    .SYNOPSIS
        Retrieves comprehensive system information

    .DESCRIPTION
        Returns operating system, computer system, edition, product type, build number,
        and architecture information via WMI and registry queries.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [PSObject]. Object with ComputerInfo, OperatingSystem, EditionID, ProductType, Build, and Architecture.

    .EXAMPLE
        Get-SystemInfo

    .EXAMPLE
        Get-SystemInfo -ComputerName "SERVER01"

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
        $os = Get-WmiObject "Win32_OperatingSystem" | Select-Object -Property * | ConvertTo-Json -Depth 10 | ConvertFrom-Json
        $cs = Get-WmiObject "Win32_ComputerSystem" | Select-Object -Property * | ConvertTo-Json -Depth 10 | ConvertFrom-Json

        $ntVersion = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

        $result = [ordered]@{
            ComputerInfo    = $cs
            OperatingSystem = $os
            EditionID       = $ntVersion.EditionID
            ProductType     = switch ($os.ProductType) { 1 { "Workstation" } 2 { "DomainController" } 3 { "Server" } default { "Unknown ($($os.ProductType))" } }
            Build           = [int]$ntVersion.CurrentBuildNumber
            Architecture    = $env:PROCESSOR_ARCHITECTURE
        }
        return New-Object -TypeName psobject -Property $result
    }
    Invoke-Command @PSBoundParameters -ScriptBlock $oScriptBlock
}