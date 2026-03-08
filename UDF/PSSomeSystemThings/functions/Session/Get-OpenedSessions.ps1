function Get-OpenedSessions {
    <#
    .SYNOPSIS
        Retrieves all logon sessions on a computer

    .DESCRIPTION
        Enumerates Win32_LogonSession and Win32_LoggedOnUser WMI classes to list all
        active logon sessions with user, domain, logon type, and start time.

    .PARAMETER ComputerName
        Remote computer name(s) to query.

    .PARAMETER Credential
        Credentials for remote execution.

    .PARAMETER Session
        Existing PSSession(s) for remote execution.

    .OUTPUTS
        [PSObject[]]. Objects with Domain, Name, LogonType, AuthenticationPackage, and StartTime.

    .EXAMPLE
        Get-OpenedSessions

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    Param(
        [string[]]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession[]]$Session
    )
    $oScriptBLock = {
        $logon_sessions = (Get-CimInstance win32_logonsession)
        $logon_users = (Get-CimInstance win32_loggedonuser)
        foreach ($item in $logon_users) {
            $logon_session = ($logon_sessions | Where-Object { $_.LogonId -eq $item.Dependent.LogonId })
            $result = [ordered]@{
                "Domain" = $item.Antecedent.Domain
                "Name" = $item.Antecedent.Name
                "LogonId" = $item.Dependent.LogonId
                "LogonTypeId" = $logon_session.LogonType
                "LogonType" = switch ($logon_session.LogonType) {
                        "0" {"Local System"}
                        "2" {"Interactive"} #(Local logon)
                        "3" {"Network"} # (Remote logon)
                        "4" {"Batch"} # (Scheduled task)
                        "5" {"Service"} # (Service account logon)
                        "7" {"Unlock"} #(Screen saver)
                        "8" {"NetworkCleartext"} # (Cleartext network logon)
                        "9" {"NewCredentials"} #(RunAs using alternate credentials)
                        "10" {"RemoteInteractive"} #(RDP\TS\RemoteAssistance)
                        "11" {"CachedInteractive"} #(Local w\cached credentials)
                        default {"Unknown"}
                }
                "AuthenticationPackage" = $logon_session.AuthenticationPackage
                "StartTime" = $logon_session.StartTime
                "Session" = $logon_session
            }
            New-Object -TypeName psobject -Property $result
        }
    }
    Invoke-Command @PSBoundParameters -ScriptBlock $oScriptBLock
}