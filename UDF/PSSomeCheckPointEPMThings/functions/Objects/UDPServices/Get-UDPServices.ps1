function Get-UDPServices {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getUDPServices"
        $sQuery = "query getUDPServices {
            getUDPServices {
              uid
              type
              name
              comments
              read__only
              port
              source__port
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getUDPServices
    }
}
