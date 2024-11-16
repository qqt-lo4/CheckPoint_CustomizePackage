function Get-EPSJobStatus {
    Param(
        [object]$EPSAPI,
        [Parameter(Mandatory)]
        [string]$Id
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sEndpoint = "webmgmt/api/v2/jobs/$Id"
        $hParameters = @{
            operationName = "jobStatus"
        }
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPIGet($sEndpoint, $hParameters)
        return $oAPIResult
    }
}
