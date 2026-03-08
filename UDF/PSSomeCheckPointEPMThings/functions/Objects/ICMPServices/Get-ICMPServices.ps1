function Get-ICMPServices {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getICMPServices"
        $sQuery = "query getICMPServices {
            getICMPServices {
              uid
              type
              name
              comments
              icmpType
              icmpCode
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getICMPServices
    }
}
