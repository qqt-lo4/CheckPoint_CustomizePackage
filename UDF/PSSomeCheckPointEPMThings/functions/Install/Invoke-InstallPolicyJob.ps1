function Invoke-InstallPolicyJob {
    Param(
        [object]$EPSAPI,
        [string[]]$RuleIds
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "installPolicyJob"
        $sQuery = "mutation installPolicyJob(`$ruleIds: [ID!]!) {
            installPolicyJob(ruleIds: `$ruleIds)
          }
          "
        $hVariables = @{ruleIds = $RuleIds}
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.installPolicyJob
    }
}
