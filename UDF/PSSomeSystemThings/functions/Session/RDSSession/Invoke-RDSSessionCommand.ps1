function Invoke-RDSSessionCommand {
    <#
    .SYNOPSIS
        Executes a command or launches a process in an RDS session

    .DESCRIPTION
        Provides two execution modes:
        - ScriptBlock mode: Runs a PowerShell scriptblock on the target server. The session
          information object is passed as the first parameter to the scriptblock.
        - Process mode: Launches a process visible in the user's interactive session using
          WTSQueryUserToken and CreateProcessAsUser native APIs. Requires administrator
          privileges on the target server.

    .PARAMETER ScriptBlock
        PowerShell scriptblock to execute on the target server.
        The session information object (from Get-RDSSession) is passed as the first parameter.

    .PARAMETER FilePath
        Path of the executable to launch in the user's interactive session.
        The process will be visible on the user's desktop.

    .PARAMETER Arguments
        Command-line arguments for the executable (used with -FilePath)

    .PARAMETER SessionId
        ID of the target session

    .PARAMETER ComputerName
        Name of the RDS server. Default is local server

    .PARAMETER Credential
        PSCredential object for remote authentication

    .PARAMETER Session
        Existing PSSession to use for remote operations

    .PARAMETER Wait
        In Process mode, waits for the launched process to exit and returns the exit code

    .OUTPUTS
        System.Object
        In ScriptBlock mode: returns the scriptblock output
        In Process mode: returns a RDS.ProcessResult object with ProcessId and optionally ExitCode

    .EXAMPLE
        Invoke-RDSSessionCommand -SessionId 2 -Session $session -ScriptBlock {
            param($SessionInfo)
            "User $($SessionInfo.UserName) is in state $($SessionInfo.State)"
        }
        Runs a scriptblock on the target server with session context information

    .EXAMPLE
        Invoke-RDSSessionCommand -SessionId 2 -ComputerName "RDS01" -FilePath "notepad.exe"
        Launches Notepad visible in the user's session on the remote server

    .EXAMPLE
        Invoke-RDSSessionCommand -SessionId 2 -Session $session -FilePath "msg.exe" -Arguments "* Hello" -Wait
        Launches a command in the user's session and waits for completion

    .EXAMPLE
        Get-RDSSession -UserName "john*" -Session $session | Invoke-RDSSessionCommand -ScriptBlock {
            param($SessionInfo)
            Get-Process -Id $SessionInfo.SessionId -ErrorAction SilentlyContinue |
                Where-Object { $_.CPU -gt 60 }
        }
        Pipeline example: finds CPU-intensive processes in matching sessions

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
        The Process mode (-FilePath) requires administrator privileges on the target server.
        WTSQueryUserToken requires the SE_TCB_PRIVILEGE, typically available to SYSTEM
        or elevated administrator processes.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ScriptBlock')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'ScriptBlock')]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true, ParameterSetName = 'Process')]
        [string]$FilePath,

        [Parameter(ParameterSetName = 'Process')]
        [string]$Arguments = '',

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('ID')]
        [int]$SessionId,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'Host', 'PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential,

        [System.Management.Automation.Runspaces.PSSession]$Session,

        [Parameter(ParameterSetName = 'Process')]
        [switch]$Wait
    )

    process {
        $params = Split-RemoteAndNativeParameters

        # Validate session exists
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

        if ($sessionInfo.State -eq 'Listen') {
            Write-Error "Cannot execute commands in a Listen session"
            return
        }

        if ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
            # ScriptBlock mode: run user's scriptblock with session info as context
            $wrapperBlock = {
                param($nativeParams)

                $sessionInfo = $nativeParams.SessionInfo
                $userScriptBlock = [scriptblock]::Create($nativeParams.ScriptBlockText)

                & $userScriptBlock $sessionInfo
            }

            try {
                $nativeParams = $params.Native
                $nativeParams['SessionInfo'] = $sessionInfo
                $nativeParams['ScriptBlockText'] = $ScriptBlock.ToString()

                if ($remoteParams.Count -gt 0) {
                    Invoke-Command @remoteParams -ScriptBlock $wrapperBlock -ArgumentList $nativeParams
                }
                else {
                    & $wrapperBlock $nativeParams
                }
            }
            catch {
                Write-Error "Error executing scriptblock: $_"
            }
        }
        else {
            # Process mode: launch a visible process in the user's interactive session
            # Uses Windows Task Scheduler which natively handles session/desktop access
            $processBlock = {
                param($nativeParams)

                try {
                    $sessionId = $nativeParams.SessionId
                    $filePath = $nativeParams.FilePath
                    $arguments = $nativeParams.Arguments
                    $waitForExit = [bool]$nativeParams.Wait
                    $userName = $nativeParams.UserIdentity

                    Write-Verbose "Launching '$filePath' in session $sessionId (user: $userName) via scheduled task..."

                    # Create a unique task name
                    $taskName = "RDS_Launch_$([guid]::NewGuid().ToString('N').Substring(0,8))"

                    # Build scheduled task action
                    $actionParams = @{ Execute = $filePath }
                    if ($arguments) { $actionParams['Argument'] = $arguments }
                    $action = New-ScheduledTaskAction @actionParams

                    # Principal: run as the target user in their interactive session
                    $principal = New-ScheduledTaskPrincipal -UserId $userName -LogonType Interactive

                    # Register and start the task
                    Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Force | Out-Null
                    Start-ScheduledTask -TaskName $taskName

                    # Brief pause to let the process start
                    Start-Sleep -Milliseconds 500

                    if ($waitForExit) {
                        Write-Verbose "Waiting for task '$taskName' to complete..."
                        do {
                            Start-Sleep -Milliseconds 500
                            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                        } while ($task -and $task.State -eq 'Running')

                        $taskInfo = Get-ScheduledTaskInfo -TaskName $taskName -ErrorAction SilentlyContinue
                        $exitCode = if ($taskInfo) { $taskInfo.LastTaskResult } else { $null }
                    }

                    # Try to get the process ID (best effort)
                    $processId = $null
                    $proc = Get-Process | Where-Object {
                        $_.SessionId -eq $sessionId -and
                        $_.Name -eq [System.IO.Path]::GetFileNameWithoutExtension($filePath)
                    } | Sort-Object StartTime -Descending | Select-Object -First 1
                    if ($proc) { $processId = $proc.Id }

                    # Cleanup the scheduled task
                    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

                    [PSCustomObject]@{
                        PSTypeName   = 'RDS.ProcessResult'
                        ProcessId    = $processId
                        SessionId    = $sessionId
                        FilePath     = $filePath
                        Arguments    = $arguments
                        ExitCode     = if ($waitForExit) { $exitCode } else { $null }
                        ComputerName = $env:COMPUTERNAME
                    }
                }
                catch {
                    # Cleanup on error
                    if ($taskName) {
                        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
                    }
                    Write-Error "Error launching process in session: $_"
                }
            }

            try {
                $nativeParams = $params.Native
                $nativeParams['FilePath'] = $FilePath
                $nativeParams['Arguments'] = $Arguments
                $nativeParams['Wait'] = $Wait.IsPresent
                # Pass user identity (DOMAIN\User) for the scheduled task principal
                $nativeParams['UserIdentity'] = if ($sessionInfo.DomainName) {
                    "$($sessionInfo.DomainName)\$($sessionInfo.UserName)"
                } else {
                    $sessionInfo.UserName
                }

                if ($remoteParams.Count -gt 0) {
                    Invoke-Command @remoteParams -ScriptBlock $processBlock -ArgumentList $nativeParams
                }
                else {
                    & $processBlock $nativeParams
                }
            }
            catch {
                Write-Error "Error: $_"
            }
        }
    }
}
