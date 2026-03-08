Add-Type -AssemblyName System.ServiceProcess
function Get-Service {
    <#
    .SYNOPSIS
        Retrieves Windows services with remote execution support

    .DESCRIPTION
        Wraps Microsoft.PowerShell.Management\Get-Service and adds support for
        remote execution via ComputerName, Credential, or PSSession parameters.

    .PARAMETER Name
        Service name(s) to retrieve.

    .PARAMETER DependentServices
        Include dependent services.

    .PARAMETER RequiredServices
        Include services that this service depends on.

    .PARAMETER Include
        Service names to include.

    .PARAMETER Exclude
        Service names to exclude.

    .PARAMETER DisplayName
        Filter by display name(s).

    .PARAMETER InputObject
        ServiceController objects from pipeline.

    .PARAMETER ComputerName
        Remote computer name(s) to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession(s) for remote execution.

    .OUTPUTS
        [System.ServiceProcess.ServiceController[]]. Service objects.

    .EXAMPLE
        Get-Service -Name "wuauserv"

    .EXAMPLE
        Get-Service -Name "Spooler" -ComputerName "SERVER01"

    .NOTES
        Author  : Loïc Ade
        Version : 2.0.0

        Version History:
        1.0.0 - Initial version using Invoke-ThisFunctionRemotely
        2.0.0 - Replaced Invoke-ThisFunctionRemotely with Invoke-Command,
                 added Session/ComputerName conflict check,
                 uses Split-RemoteAndNativeParameters
    #>

    [CmdletBinding(DefaultParameterSetName="Name")]
    Param(
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Name")]
        [Alias("ServiceName")]
        [string[]]$Name,

        [Alias("DS")]
        [switch]$DependentServices,

        [Alias("SDO","ServicesDependedOn")]
        [switch]$RequiredServices,

        [ValidateNotNullOrEmpty()]
        [string[]]$Include,

        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude,

        [Parameter(Mandatory, ParameterSetName = "DisplayName")]
        [string[]]$DisplayName,

        [Parameter(ValueFromPipeline, ParameterSetName = "InputObject")]
        [ValidateNotNullOrEmpty()]
        [System.ServiceProcess.ServiceController[]]$InputObject,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("Cn")]
        [string[]]$ComputerName,

        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential,

        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )

    Begin{
        if ($Session -and $ComputerName) {
            throw "Incompatible arguments : you can't use Session and ComputerName at the same time"
        }
        $oScriptBlock = {
            Param(
                [Parameter(Mandatory)]
                [object]$Params
            )
            Add-Type -AssemblyName System.ServiceProcess
            Microsoft.PowerShell.Management\Get-Service @Params
        }
    }
    Process {
        $hParams = Split-RemoteAndNativeParameters
        $hRemoteParams = $hParams.Remote
        Invoke-Command @hRemoteParams -ScriptBlock $oScriptBlock -ArgumentList $hParams.Native
    }
    End{}
}