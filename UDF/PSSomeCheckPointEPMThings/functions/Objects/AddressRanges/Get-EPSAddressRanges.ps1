function Get-EPSAddressRanges {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getAddressRanges"
        $sQuery = "query getAddressRanges {
            getAddressRanges {
              uid
              type
              name
              comments
              read__only
              ipv4__address__first
              ipv4__address__last
              ipv6__address__first
              ipv6__address__last
              __typename
            }
          }          
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getAddressRanges
    }
}