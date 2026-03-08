function Get-ICMPv6Services {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getICMPv6Services"
        $sQuery = "query getICMPv6Services {
            getICMPv6Services {
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
        return $oAPIResult.data.getICMPv6Services
    }
}
