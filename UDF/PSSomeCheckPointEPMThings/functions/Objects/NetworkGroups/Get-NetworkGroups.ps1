function Get-NetworkGroups {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getNetworkGroups"
        $sQuery = "query getNetworkGroups {
            getNetworkGroups {
              uid
              type
              name
              comments
              read__only
              members {
                uid
                name
                type
                __typename
              }
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getNetworkGroups
    }
}