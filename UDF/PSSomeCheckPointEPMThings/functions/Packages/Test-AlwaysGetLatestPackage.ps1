function Test-AlwaysGetLatestPackage {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getisAlwaysGetLatestAgent"
        $sQuery = "query getisAlwaysGetLatestAgent {
            getisAlwaysGetLatestAgent
          }"
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getisAlwaysGetLatestAgent
    }
}