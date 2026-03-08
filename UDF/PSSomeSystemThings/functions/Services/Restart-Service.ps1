Add-Type -AssemblyName System.ServiceProcess
function Restart-Service {
    <#
    .SYNOPSIS
        Restarts Windows services with remote execution support

    .DESCRIPTION
        Wraps Microsoft.PowerShell.Management\Restart-Service and adds support for
        remote execution via ComputerName, Credential, or PSSession parameters.

    .PARAMETER InputObject
        ServiceController objects from pipeline.

    .PARAMETER Force
        Forces the service to restart even if dependent services are running.

    .PARAMETER PassThru
        Returns the service object after restart.

    .PARAMETER Include
        Service names to include.

    .PARAMETER Exclude
        Service names to exclude.

    .PARAMETER Name
        Service name(s) to restart.

    .PARAMETER DisplayName
        Filter by display name(s).

    .PARAMETER ComputerName
        Remote computer name(s).

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession(s) for remote execution.

    .OUTPUTS
        [System.ServiceProcess.ServiceController[]]. Service objects if PassThru is specified.

    .EXAMPLE
        Restart-Service -Name "Spooler"

    .EXAMPLE
        Restart-Service -Name "Spooler" -ComputerName "SERVER01"

    .NOTES
        Author  : Loïc Ade
        Version : 2.0.0

        Version History:
        1.0.0 - Initial version using Invoke-ThisFunctionRemotely
        2.0.0 - Replaced Invoke-ThisFunctionRemotely with Invoke-Command,
                 added Session/ComputerName conflict check,
                 uses Split-RemoteAndNativeParameters
    #>

    [CmdletBinding(DefaultParameterSetName="InputObject")]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "InputObject")]
        [ValidateNotNullOrEmpty()]
        [System.ServiceProcess.ServiceController[]]$InputObject,

        [switch]$Force,

        [switch]$PassThru,

        [ValidateNotNullOrEmpty()]
        [string[]]$Include,

        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude,

        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Name")]
        [Alias("ServiceName")]
        [string[]]$Name,

        [Parameter(Mandatory, ParameterSetName = "DisplayName")]
        [string[]]$DisplayName,

        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias("Cn")]
        [string[]]$ComputerName,

        [ValidateNotNullOrEmpty()]
        [pscredential]$Credential,

        [Parameter(ValueFromPipelineByPropertyName)]
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
            Microsoft.PowerShell.Management\Restart-Service @Params
        }
    }
    Process {
        $hParams = Split-RemoteAndNativeParameters
        $hRemoteParams = $hParams.Remote
        Invoke-Command @hRemoteParams -ScriptBlock $oScriptBlock -ArgumentList $hParams.Native
    }
    End{}
}