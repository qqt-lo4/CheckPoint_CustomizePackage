function Get-ObjectsByName {
    Param(
        [object]$EPSAPI,
        [Parameter(Mandatory)]
        [string[]]$Names
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "objectsByNames"
        $sQuery = "query objectsByNames(`$names: [String]) {
            objectsByNames(names: `$names) {
              uid
              name
              type
              __typename
            }
          }          
          "
        $hVariables = @{names = $Names}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.objectsByNames
    }
}