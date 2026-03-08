function Get-Packages {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getPackages"
        $sQuery = "query getPackages {
            getPackages {
              id
              version
              packageType
              platformType
              featuresIncluded
              offlineFeaturesIncluded
              fileName
              size
              isInstalled
              isInRepo
              isLatest
              isCFG
              isRecommended
              __typename
            }
          }"
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getPackages
    }
}