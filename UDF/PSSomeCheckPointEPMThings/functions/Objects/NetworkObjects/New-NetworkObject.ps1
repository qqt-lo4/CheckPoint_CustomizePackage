function New-NetworkObject {
    Param(
        [object]$EPSAPI,
        [Parameter(Mandatory)]
        [string]$Name,
        [string]$subnet4,
        [string]$mask__length4,
        [string]$subnet6,
        [string]$mask__length6,
        [string]$subnet__mask
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        if (-not (($subnet4 -and ($mask__length4 -or $subnet__mask)) `
            -or ($subnet6 -and $mask__length6))) {
            throw [System.ArgumentException] "Missing or incoherent parameters"
        }
        $sOperationName = "UpsertNetworkObject"
        $sQuery = "mutation UpsertNetworkObject(`$networkObjectInput: NetworkObjectInput!) {
            UpsertNetworkObject(networkObject: `$networkObjectInput) {
              uid
              name
              __typename
            }
          }
          "
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.UpsertNetworkObject
    }
}