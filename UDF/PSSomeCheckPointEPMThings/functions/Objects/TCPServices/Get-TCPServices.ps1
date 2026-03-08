function Get-TCPServices {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getTCPServices"
        $sQuery = "query getTCPServices {
            getTCPServices {
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
        return $oAPIResult.data.getTCPServices
    }
}