function Get-LatestAgentFromCheckPoint {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
    }
    Process {
        $sTaskId = Get-LatestAgentFromCheckPointJob -EPSAPI $oEPSAPI
        $oResult = Wait-EPSJobEnd -EPSAPI $oEPSAPI -Id $sTaskId
        return $oResult
    }
}