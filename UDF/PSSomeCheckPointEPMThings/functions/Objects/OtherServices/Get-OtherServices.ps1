function Get-OtherServices {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getOtherServices"
        $sQuery = "query getOtherServices {
            getOtherServices {
              uid
              type
              name
              comments
              protocol
              includeInAny
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getOtherServices
    }
}
