function Get-NetworkObjects {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getNetworkObjects"
        $sQuery = "query getNetworkObjects {
            getNetworkObjects {
              uid
              type
              name
              comments
              read__only
              subnet4
              subnet6
              mask__length6
              subnet__mask
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getNetworkObjects
    }
}