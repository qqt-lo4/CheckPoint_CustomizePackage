function Get-ExportPackages {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getExportPackages"
        $sQuery = "query getExportPackages {
            getExportPackages {
              id
              name
              bladesSelected
              softwareVersionGuid
              virtualGroupId
              VPNSite {
                encryptionMethod
                endpointEnabled
                id
                serverAddress
                name
                __typename
              }
              epsMsiDependency
              dotNetDependency
              visualStudioDependency
              linuxPreboot
              isAtm
              kavMinSignatures
              kavFullSignatures
              minimizedPackage
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getExportPackages
    }
}