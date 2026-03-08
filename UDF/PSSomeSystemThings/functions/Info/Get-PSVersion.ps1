function Get-PSVersion {
    <#
    .SYNOPSIS
        Retrieves the PowerShell version

    .DESCRIPTION
        Returns the PowerShell version table or just the version number.
        Supports remote execution.

    .PARAMETER onlyVersion
        If specified, returns only the version number instead of the full version table.

    .PARAMETER ComputerName
        Remote computer name to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession for remote execution.

    .OUTPUTS
        [version] or [hashtable]. The PS version or full PSVersionTable.

    .EXAMPLE
        Get-PSVersion

    .EXAMPLE
        Get-PSVersion -onlyVersion

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding(DefaultParameterSetName = "None")]
    Param(
        [switch]$onlyVersion,
        [Parameter(ParameterSetName = "userpasswd")]
        [string]$ComputerName,
        [Parameter(ParameterSetName = "userpasswd")]
        [pscredential]$Credential,
        [Parameter(ParameterSetName = "pssession")]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    $oScriptBlock = {
        Param(
            [bool]$OnlyVersion
        )
        if ($onlyVersion) {
            return $PSVersionTable.PSVersion
        } else {
            return $PSVersionTable
        }
    }
    $PSBoundParameters.Remove("onlyVersion") | Out-Null
    Invoke-Command @PSBoundParameters -ScriptBlock $oScriptBlock -ArgumentList $onlyVersion
}
