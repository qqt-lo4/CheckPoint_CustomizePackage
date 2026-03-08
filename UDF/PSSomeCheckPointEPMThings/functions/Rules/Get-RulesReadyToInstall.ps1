function Get-RulesReadyToInstall {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "rulesReadyToInstall"
        $sQuery = "query rulesReadyToInstall {
            rulesReadyToInstall {
              rulesIds
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.rulesReadyToInstall
    }
}
