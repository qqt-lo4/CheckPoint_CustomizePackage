function Get-RDSSessionHistory {
    <#
    .SYNOPSIS
        Retrieves Remote Desktop session history from Event Logs

    .DESCRIPTION
        Queries Windows Event Logs to retrieve historical RDS session information
        including logons, logoffs, disconnections, and reconnections.
        Uses TerminalServices-LocalSessionManager event log to gather session activity.

    .PARAMETER UserName
        Filter by username (supports wildcards like "*admin*")

    .PARAMETER ComputerName
        Name of the RDS server to query. Default is local server

    .PARAMETER Credential
        PSCredential object for remote authentication

    .PARAMETER Session
        Existing PSSession to use for remote operations

    .PARAMETER EventType
        Filter by event type: Logon, Logoff, Disconnect, Reconnect, or All (default)

    .PARAMETER MaxEvents
        Maximum number of events to retrieve (default: 100, max: 10000)

    .PARAMETER StartTime
        Start date/time for event search

    .PARAMETER EndTime
        End date/time for event search

    .PARAMETER Last
        Retrieve events from the last N days (e.g., -Last 7 for last 7 days)
        Shortcut for -StartTime (Get-Date).AddDays(-N)

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns objects containing TimeCreated, UserName, SessionId, EventType, ClientAddress, etc.

    .EXAMPLE
        Get-RDSSessionHistory -Last 7
        Retrieves all RDS events from the last 7 days

    .EXAMPLE
        Get-RDSSessionHistory -UserName "john.doe" -EventType Logon -Last 30
        Retrieves logon events for user john.doe from the last 30 days

    .EXAMPLE
        Get-RDSSessionHistory -ComputerName "RDS01" -Credential $cred -MaxEvents 50
        Retrieves last 50 RDS events from RDS01 using credentials

    .EXAMPLE
        Get-RDSSessionHistory -StartTime (Get-Date).AddDays(-7) -EndTime (Get-Date) -EventType Disconnect
        Retrieves disconnection events from the last 7 days with specific date range

    .EXAMPLE
        Get-RDSSessionHistory -UserName "*admin*" -Last 1 | Format-Table TimeCreated, EventType, UserName, SessionId
        Retrieves all admin user sessions from the last 24 hours in table format

    .EXAMPLE
        # Find all sessions for a specific user over the last week
        Get-RDSSessionHistory -UserName "john.doe" -Last 7 -Session $oSession |
            Group-Object EventType |
            Select-Object Name, Count
        Groups session events by type to see activity summary

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0

        Requires:
        - Read access to Event Logs (Microsoft-Windows-TerminalServices-LocalSessionManager/Operational)
        - This log must be enabled on the RDS server
        - Administrator privileges may be required depending on server configuration

        Event Sources:
        - Microsoft-Windows-TerminalServices-LocalSessionManager/Operational
          Event ID 21 : Session logon succeeded
          Event ID 22 : Shell start notification
          Event ID 23 : Session logoff succeeded
          Event ID 24 : Session disconnected
          Event ID 25 : Session reconnection succeeded
          Event ID 40 : Session disconnected (with reason code)

        Note: If the event log is not available, this may not be an RDS/Terminal Server
    #>
    [CmdletBinding()]
    param(
        [SupportsWildcards()]
        [string]$UserName,

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [Alias('Server', 'Host', 'PSComputerName')]
        [string]$ComputerName = $env:COMPUTERNAME,

        [PSCredential]$Credential,

        [System.Management.Automation.Runspaces.PSSession]$Session,

        [ValidateSet('All', 'Logon', 'Logoff', 'Disconnect', 'Reconnect')]
        [string]$EventType = 'All',

        [ValidateRange(1, 10000)]
        [int]$MaxEvents = 100,

        [DateTime]$StartTime,

        [DateTime]$EndTime,

        [ValidateRange(1, 365)]
        [int]$Last
    )

    process {
        $params = Split-RemoteAndNativeParameters

        $scriptBlock = {
            param($nativeParams)

            try {
                # Ensure EventType has a default value if not specified
                if (-not $nativeParams.EventType) {
                    $nativeParams.EventType = 'All'
                }

                Write-Verbose "EventType parameter: '$($nativeParams.EventType)'"
                Write-Verbose "Last parameter: '$($nativeParams.Last)'"
                Write-Verbose "MaxEvents parameter: '$($nativeParams.MaxEvents)'"

                # Build event filter based on EventType
                $eventIds = switch ($nativeParams.EventType) {
                    'Logon'      { @(21, 22) }
                    'Logoff'     { @(23) }
                    'Disconnect' { @(24, 40) }
                    'Reconnect'  { @(25) }
                    'All'        { @(21, 22, 23, 24, 25, 40) }
                    default      { @(21, 22, 23, 24, 25, 40) }  # Default to All if unrecognized
                }

                # Build time filter
                $startTime = $nativeParams.StartTime
                $endTime = $nativeParams.EndTime

                if ($nativeParams.Last) {
                    $startTime = (Get-Date).AddDays(-$nativeParams.Last)
                    $endTime = Get-Date
                    Write-Verbose "Using Last parameter: Events from $startTime to $endTime"
                }

                if (-not $startTime) {
                    $startTime = (Get-Date).AddDays(-30)  # Default: last 30 days
                    Write-Verbose "No time filter specified, defaulting to last 30 days"
                }
                if (-not $endTime) {
                    $endTime = Get-Date
                }

                Write-Verbose "Querying events from $startTime to $endTime"
                Write-Verbose "Event IDs: $($eventIds -join ', ')"
                Write-Verbose "Max events to retrieve: $($nativeParams.MaxEvents)"

                # Query the event log
                $logName = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'

                # Ensure MaxEvents has a valid value (default to 100 if not specified)
                $maxEventsValue = if ($nativeParams.MaxEvents -and $nativeParams.MaxEvents -gt 0) {
                    $nativeParams.MaxEvents
                }
                else {
                    100
                }
                Write-Verbose "MaxEvents value: $maxEventsValue"

                # Build filter hashtable (more reliable than XPath)
                $filterHashtable = @{
                    LogName   = $logName
                    ID        = $eventIds
                    StartTime = $startTime
                    EndTime   = $endTime
                }

                Write-Verbose "Filter: LogName=$logName, IDs=$($eventIds -join ','), StartTime=$startTime, EndTime=$endTime"

                try {
                    $events = Get-WinEvent -FilterHashtable $filterHashtable -MaxEvents $maxEventsValue -ErrorAction Stop
                    Write-Verbose "Found $($events.Count) events"
                }
                catch {
                    # Check for "no events found" error using language-independent FullyQualifiedErrorId
                    if ($_.FullyQualifiedErrorId -like '*NoMatchingEventsFound*') {
                        Write-Warning "No RDS session events found matching the criteria (Time: $startTime to $endTime, EventType: $($nativeParams.EventType))"
                        return @()
                    }
                    # Check if log doesn't exist
                    elseif ($_.Exception.Message -match 'does not exist|n''existe pas') {
                        Write-Error "Event log '$logName' not found. This may not be an RDS/Terminal Server, or the log may be disabled."
                        return @()
                    }
                    else {
                        # Re-throw unexpected errors
                        throw
                    }
                }

                # Parse events and build result objects
                $results = foreach ($event in $events) {
                    $eventXml = [xml]$event.ToXml()
                    $eventData = @{}

                    # Extract event data (EventXML node contains custom data)
                    $eventXmlNode = $eventXml.Event.UserData.EventXML
                    if ($eventXmlNode) {
                        foreach ($node in $eventXmlNode.ChildNodes) {
                            if ($node.Name -and $node.'#text') {
                                $eventData[$node.Name] = $node.'#text'
                            }
                        }
                    }

                    # Determine event type from Event ID
                    $type = switch ($event.Id) {
                        21 { 'Logon' }
                        22 { 'Logon' }
                        23 { 'Logoff' }
                        24 { 'Disconnect' }
                        25 { 'Reconnect' }
                        40 { 'Disconnect' }
                        default { 'Unknown' }
                    }

                    # Extract username (format can be DOMAIN\User or User)
                    $userName = $eventData['User']
                    if (-not $userName) {
                        # Fallback: try to get from Security ID or other fields
                        $userName = $eventData['UserSid'] -replace '^.*\\', ''
                    }

                    $sessionId = $eventData['SessionID']
                    $clientAddress = $eventData['Address']
                    $reason = $eventData['Reason']

                    # Apply username filter if specified
                    if ($nativeParams.UserName -and $userName) {
                        if (-not ($userName -like $nativeParams.UserName)) {
                            continue
                        }
                    }

                    # Build result object
                    [PSCustomObject]@{
                        PSTypeName    = 'RDS.SessionHistory'
                        TimeCreated   = $event.TimeCreated
                        EventType     = $type
                        UserName      = $userName
                        SessionId     = if ($sessionId) { [int]$sessionId } else { $null }
                        ClientAddress = $clientAddress
                        Reason        = $reason
                        EventId       = $event.Id
                        Message       = $event.Message
                        ComputerName  = $env:COMPUTERNAME
                    }
                }

                return $results | Sort-Object TimeCreated -Descending
            }
            catch {
                Write-Error "Error querying event log: $_"
                return @()
            }
        }

        # Execute locally or remotely
        $remoteParams = $params.Remote
        $nativeParams = $params.Native

        if ($remoteParams.Count -gt 0) {
            Invoke-Command @remoteParams -ScriptBlock $scriptBlock -ArgumentList $nativeParams
        }
        else {
            & $scriptBlock $nativeParams
        }
    }
}
