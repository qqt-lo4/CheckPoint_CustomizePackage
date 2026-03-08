function Get-Notifications {
    Param(
        [object]$EPSAPI
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "getNotifications"
        $sQuery = "query getNotifications {
            getNotifications {
                id
                createdBy
                status
                startedOn
                modifyOn
                endedOn
                progressPercentage
                message
                messageArguments
                show
                internalInfo
            }
        }"
        $hVariables = @{}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.getNotifications
    }
}
