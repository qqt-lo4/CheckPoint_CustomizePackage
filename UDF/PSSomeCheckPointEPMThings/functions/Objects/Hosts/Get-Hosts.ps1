function Get-Hosts {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getHosts"
        $sQuery = "query getHosts {
            getHosts {
              uid
              name
              type
              comments
              read__only
              ipv4__address
              ipv6__address
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getHosts
    }
}