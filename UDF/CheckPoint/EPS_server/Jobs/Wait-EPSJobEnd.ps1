function Wait-EPSJobEnd {
    Param(
        [object]$EPSAPI,
        [Parameter(Mandatory)]
        [string]$Id
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
    }
    Process {
        do {
            Start-Sleep -Seconds 1
            $oJobStatus = Get-EPSJobStatus -Id $Id -EPSAPI $oEPSAPI
            $sMessage = if ($oJobStatus.notificationInfo.message) { $oJobStatus.notificationInfo.message } else { "In progress" }
            $iPercent = if ($oJobStatus.notificationInfo.progressPercentage) { $oJobStatus.notificationInfo.progressPercentage } else { 0 }
            Write-Progress -Activity $sMessage -PercentComplete $iPercent
        } until ($oJobStatus.notificationInfo.progressPercentage -eq 100)
        return $oJobStatus
    }
}
