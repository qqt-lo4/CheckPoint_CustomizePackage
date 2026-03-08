function Get-LatestAgentFromCheckPointJob {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getAndInstallLatestClientJob"
        $sQuery = @"
        mutation getAndInstallLatestClientJob {
            getAndInstallLatestClientJob
        }
"@
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getAndInstallLatestClientJob
    }
}