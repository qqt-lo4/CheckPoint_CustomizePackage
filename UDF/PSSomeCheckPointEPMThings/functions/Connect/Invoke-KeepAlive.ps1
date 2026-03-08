function Invoke-KeepAlive {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "keepAliveJob"
        $sQuery = "query keepAliveJob {
            keepAliveJob
          }
        "
        $hVariables = @{}
    }
    Process {
        $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
    }
}