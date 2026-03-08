function Find-NMap {
    <#
    .SYNOPSIS
        Finds the Nmap installation on the system

    .DESCRIPTION
        Locates Nmap by checking the uninstall registry keys. Returns the
        executable and program paths. With -Zenmap, returns the Zenmap
        (pythonw.exe) path and arguments instead. Supports remote execution.

    .PARAMETER ComputerName
        Remote computer to search on.

    .PARAMETER Credential
        Credential for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .PARAMETER Zenmap
        Return Zenmap paths and arguments instead of Nmap.

    .OUTPUTS
        [PSCustomObject]. ExePath, ProgramPath (and Arguments for Zenmap).

    .EXAMPLE
        Find-NMap

    .EXAMPLE
        Find-NMap -Zenmap

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [switch]$Zenmap
    )
    if ($ComputerName -or $Session) {
        Invoke-ThisFunctionRemotely -ImportFunctions @("Get-ApplicationUninstallRegKey", "Get-InstalledProgramPath")
    } else {
        $oRegistry = Get-ApplicationUninstallRegKey -valueData "Nmap*"
        if ($oRegistry) {
            $sPath = Get-ItemPropertyValue $oRegistry.PSPath -Name "UninstallString"
            $ss = Select-String -InputObject $sPath -Pattern "^`"(?<path>.+\\)[^\\]+`"$|^(?<path>.+\\)[^\\]+$"
            if ($ss) {
                $sNmapPath = ($ss.Matches.Groups | Where-Object { $_.name -eq "path" }).Value
                if ($Zenmap) {
                    return [PSCustomObject]@{
                        ExePath = $sNmapPath + "zenmap\bin\pythonw.exe"
                        ProgramPath = $sNmapPath
                        Arguments = "-c ""from zenmapGUI.App import run;run()"""
                    }
                } else {
                    return [PSCustomObject]@{
                        ExePath = $sNmapPath + "nmap.exe"
                        ProgramPath = $sNmapPath
                    }
                }
            } else {
                $null
            }
        } else {
            return $null
        }
    }
}
