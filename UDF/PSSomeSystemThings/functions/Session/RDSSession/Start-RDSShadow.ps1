function Start-RDSShadow {
    <#
    .SYNOPSIS
        Connects to and shadows (views or controls) an RDS session

    .DESCRIPTION
        Initiates a shadow connection to observe or control another user's RDS session.
        Launches mstsc.exe with shadow parameters to view or control the target session.
        Requires appropriate permissions and may require user consent depending on GPO settings.

        This function runs mstsc.exe LOCALLY on your machine (not remotely), opening a window
        that connects to the target session for viewing or controlling.

    .PARAMETER SessionId
        ID of the session to shadow

    .PARAMETER ComputerName
        Name of the RDS server where the session is located. Default is local server.

    .PARAMETER Credential
        PSCredential object for verifying session existence (used with Get-RDSSession)

    .PARAMETER Session
        Existing PSSession for verifying session existence (used with Get-RDSSession)

    .PARAMETER Control
        If specified, enables control mode (keyboard and mouse input).
        Without this switch, view-only mode is used.

    .PARAMETER NoConsent
        If specified, attempts to bypass user consent prompt.
        Only works if GPO allows shadowing without consent.

    .OUTPUTS
        None. Launches mstsc.exe window for shadowing.

    .EXAMPLE
        Start-RDSShadow -SessionId 2 -ComputerName "RDS-Server01"
        Shadows session 2 in view-only mode

    .EXAMPLE
        Start-RDSShadow -SessionId 2 -ComputerName "RDS-Server01" -Control
        Shadows session 2 with full control (keyboard and mouse)

    .EXAMPLE
        Start-RDSShadow -SessionId 2 -ComputerName "RDS-Server01" -Control -NoConsent
        Shadows with control, bypassing consent prompt (requires GPO permission)

    .EXAMPLE
        # Complete support workflow
        $session = Get-RDSSession -UserName "john.doe" -ComputerName "RDS01" -Session $oSession
        $result = Send-RDSMessage -SessionId $session.SessionId `
            -Message "Support technician wants to help. Accept?" `
            -ButtonType YesNo -Wait -Session $oSession

        if ($result.ButtonClicked -eq 'Yes') {
            Start-RDSShadow -SessionId $session.SessionId -ComputerName $session.ComputerName -Control
        }

    .EXAMPLE
        # Shadow with credential for session verification
        $cred = Get-Credential
        Start-RDSShadow -SessionId 2 -ComputerName "RDS01" -Credential $cred -Control

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        Requirements:
        - Administrator privileges or specific shadow permissions
        - Target session must exist and be active
        - GPO settings may require user consent
        - mstsc.exe must be available on the system

        GPO Configuration:
        Path: Computer Configuration > Administrative Templates >
              Remote Desktop Services > Remote Desktop Session Host > Connections
        Setting: "Set rules for remote control of Remote Desktop Services user sessions"

        Values:
        0 = No remote control allowed
        1 = Full control with user's permission (default)
        2 = Full control without user's permission
        3 = View session with user's permission
        4 = View session without user's permission

        Note: The -Credential and -Session parameters are only used to verify that the target
        session exists via Get-RDSSession. The actual shadow connection uses your current
        Windows credentials (the user running this command).
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

        [System.Management.Automation.Runspaces.PSSession]$Session,

        [switch]$Control,

        [switch]$NoConsent
    )

    process {
        try {
            # Verify that mstsc.exe is available
            $mstscPath = Get-Command mstsc.exe -ErrorAction SilentlyContinue
            if (-not $mstscPath) {
                Write-Error "mstsc.exe not found. Remote Desktop client must be installed."
                return
            }

            # Verify that the session exists
            Write-Verbose "Verifying session $SessionId on $ComputerName"

            $sessionParams = @{
                SessionId    = $SessionId
                ComputerName = $ComputerName
            }

            # Add Credential or Session if provided
            if ($Credential) {
                $sessionParams['Credential'] = $Credential
            }
            if ($Session) {
                $sessionParams['Session'] = $Session
            }

            $sessionInfo = Get-RDSSession @sessionParams | Where-Object { $_.SessionId -eq $SessionId }

            if (-not $sessionInfo) {
                Write-Error "Session ID $SessionId not found on $ComputerName"
                return
            }

            Write-Verbose "Session found: User=$($sessionInfo.UserName), State=$($sessionInfo.State)"

            # Check if session is in a valid state for shadowing
            if ($sessionInfo.State -eq 'Listen') {
                Write-Error "Cannot shadow a Listen session (session $SessionId is not active)"
                return
            }

            if ($sessionInfo.State -eq 'Disconnected') {
                Write-Warning "Session $SessionId is disconnected. Shadowing may not work properly."
            }

            # Build mstsc command arguments
            $mstscArgs = "/v:$ComputerName /shadow:$SessionId"

            if ($Control) {
                $mstscArgs += " /control"
                Write-Verbose "Control mode enabled"
            }
            else {
                Write-Verbose "View-only mode (no control)"
            }

            if ($NoConsent) {
                $mstscArgs += " /noConsentPrompt"
                Write-Verbose "Consent prompt bypass requested (requires GPO permission)"
            }

            # Display information
            $mode = if ($Control) { "CONTROL" } else { "VIEW-ONLY" }
            Write-Host "`nStarting shadow session..." -ForegroundColor Cyan
            Write-Host "  Target: " -NoNewline -ForegroundColor Cyan
            Write-Host "$($sessionInfo.UserName)" -NoNewline -ForegroundColor Yellow
            Write-Host "@$ComputerName (Session $SessionId)" -ForegroundColor Cyan
            Write-Host "  Mode: " -NoNewline -ForegroundColor Cyan
            Write-Host $mode -ForegroundColor $(if ($Control) { "Red" } else { "Green" })

            if (-not $NoConsent -and $sessionInfo.State -eq 'Active') {
                Write-Host "  Note: User consent may be required" -ForegroundColor Yellow
            }

            # Launch mstsc
            Write-Verbose "Launching: mstsc.exe $mstscArgs"

            $process = Start-Process -FilePath "mstsc.exe" -ArgumentList $mstscArgs -PassThru

            if ($process) {
                Write-Verbose "Shadow session launched (Process ID: $($process.Id))"
                Write-Host "`nShadow window opened. Close the window to end the shadow session.`n" -ForegroundColor Green
            }
            else {
                Write-Error "Failed to launch mstsc.exe"
            }
        }
        catch {
            Write-Error "Error starting shadow session: $_"
        }
    }
}
