function Get-RDSSessionProcess {
    <#
    .SYNOPSIS
        Lists processes running in an RDS session

    .DESCRIPTION
        Retrieves processes running in a specific session using CIM/WMI natively.
        Supports PowerShell remoting with Credential and Session parameters

    .PARAMETER SessionId
        Session ID

    .PARAMETER ComputerName
        Name of the RDS server. Default is local server

    .PARAMETER Credential
        PSCredential object for remote authentication

    .PARAMETER Session
        Existing PSSession to use for remote operations

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        List of processes in the session

    .EXAMPLE
        Get-RDSSessionProcess -SessionId 2
        Lists all processes in session 2

    .EXAMPLE
        $cred = Get-Credential
        Get-RDSSessionProcess -SessionId 3 -ComputerName "RDS01" -Credential $cred | Where-Object {$_.WorkingSetSize -gt 100MB}
        Lists memory-intensive processes using credentials

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int]$SessionId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'Host', 'PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential,

        [System.Management.Automation.Runspaces.PSSession]$Session
    )

    process {
        $params = Split-RemoteAndNativeParameters

        # Verify session exists
        $sessionGetParams = @{ SessionId = $SessionId }
        $remoteParams = $params.Remote
        if ($remoteParams.Count -gt 0) {
            $sessionGetParams += $remoteParams
        }
        else {
            if ($ComputerName) { $sessionGetParams['ComputerName'] = $ComputerName }
        }

        $sessionInfo = Get-RDSSession @sessionGetParams | Where-Object { $_.SessionId -eq $SessionId }

        if (-not $sessionInfo) {
            Write-Error "Session ID $SessionId not found"
            return
        }

        $scriptBlock = {
            param($nativeParams)

            try {
                $targetComputer = if ($nativeParams.ComputerName) { $nativeParams.ComputerName } else { $env:COMPUTERNAME }

                # Get processes via CIM
                $processes = Get-CimInstance -ClassName Win32_Process |
                Where-Object { $_.SessionId -eq $nativeParams.SessionId }

                $processes | ForEach-Object {
                    [PSCustomObject]@{
                        PSTypeName     = 'RDS.SessionProcess'
                        ProcessId      = $_.ProcessId
                        ProcessName    = $_.Name
                        SessionId      = $_.SessionId
                        WorkingSetSize = $_.WorkingSetSize
                        ThreadCount    = $_.ThreadCount
                        HandleCount    = $_.HandleCount
                        CommandLine    = $_.CommandLine
                        CreationDate   = $_.CreationDate
                        ComputerName   = $targetComputer
                    }
                }
            }
            catch {
                Write-Error "Error retrieving processes: $_"
            }
        }

        # Execute
        try {
            $nativeParams = $params.Native

            if ($remoteParams.Count -gt 0) {
                Invoke-Command @remoteParams -ScriptBlock $scriptBlock -ArgumentList $nativeParams
            }
            else {
                & $scriptBlock -nativeParams $nativeParams
            }
        }
        catch {
            Write-Error "Error: $_"
        }
    }
}
