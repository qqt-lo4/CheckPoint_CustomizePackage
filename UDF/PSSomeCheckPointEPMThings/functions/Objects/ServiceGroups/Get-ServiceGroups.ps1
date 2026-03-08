function Get-ServiceGroups {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getServiceGroups"
        $sQuery = "query getServiceGroups {
            getServiceGroups {
              uid
              type
              name
              comments
              read__only
              members {
                port
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
        return $oAPIResult.data.getServiceGroups
    }
}
