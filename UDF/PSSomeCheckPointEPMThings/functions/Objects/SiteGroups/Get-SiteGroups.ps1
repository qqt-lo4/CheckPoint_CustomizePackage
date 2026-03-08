function Get-SiteGroups {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getSiteGroups"
        $sQuery = "query getSiteGroups {
            getSiteGroups {
              uid
              type
              name
              comments
              members {
                uid
                type
                name
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
        return $oAPIResult.data.getSiteGroups
    }
}