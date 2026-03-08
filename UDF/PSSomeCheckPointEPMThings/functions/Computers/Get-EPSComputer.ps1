function Get-EPSComputer {
    [Cmdletbinding(DefaultParameterSetName = "Computers")]
    Param(
        [object]$EPSAPI,
        [Parameter(ParameterSetName = "Id")]
        [string]$Id,
        [Parameter(ParameterSetName = "Computers")]
        [Parameter(ParameterSetName = "Name")]
        [int]$offset = 0,
        [Parameter(ParameterSetName = "Computers")]
        [Parameter(ParameterSetName = "Name")]
        [int]$pageSize = 10,
        [Parameter(ParameterSetName = "Computers")]
        [string]$viewType = "AllDevices",
        [Parameter(ParameterSetName = "Computers")]
        [hashtable[]]$filter,
        [Parameter(ParameterSetName = "Computers")]
        [hashtable[]]$sorting,
        [Parameter(ParameterSetName = "Name")]
        [string]$Name
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        if ($PSCmdlet.ParameterSetName -eq "Id") {
            $sOperationName = "computer"
            $sQuery = "query computer(`$id: ID!) {
                computer(id: `$id) {
                    id
                    commonName
                    samName
                    deviceType
                    osName
                    osVersion
                    domainName
                    distinguishedName
                    description
                    daInstalled
                    groups {
                        name
                        id
                        __typename
                    }
                    __typename
                }
            }              
            "
            $hVariables = @{
                id = $Id
            }
        } else {
            $sOperationName = "computers"
            $sQuery = "query computers(`$filter: [Filter], `$paging: Paging, `$computersToExclude: [String], `$groupsToExclude: [String], `$sorting: [Sorting], `$viewType: EmonView) {
                computers(filter: `$filter, paging: `$paging, computersToExclude: `$computersToExclude, groupsToExclude: `$groupsToExclude, sorting: `$sorting, viewType: `$viewType) {
                    totalCount
                    pageSize
                    pageOffset
                    computers {
                        browserExtension {
                            chromeExtensionPingRecently
                            edgeExtensionPingRecently
                            firefoxExtensionPingRecently
                            braveExtensionPingRecently
                            safariExtensionPingRecently
                            customIocStatus
                            __typename
                        }
                        threatEmulation {
                            teAvailability
                            teOverloaded
                            teReputation
                            saLastUpdate
                            ofrLastUpdate
                            __typename
                        }
                        efr {
                            bgLastUpdate
                            thErrorMessage
                            __typename
                        }
                        antiBot {
                            abLastUpdate
                            __typename
                        }
                        antiMalware {
                            engineName
                            engineStatus
                            windowsDefenderStatus
                            rebootRequiredReason
                            lastSignatureUpdateSource
                            __typename
                        }
                        endpointForServers {
                            profilesPolicy6
                            profilesPolicy11
                            profilesPolicy20
                            profilesPolicy10
                            profilesPolicy130
                            profilesPolicy51
                            profilesPolicy30
                            profilesPolicy45
                            profilesPolicy91
                            profilesPolicy22
                            profilesPolicy35
                            profilesPolicy60
                            profilesPolicy120
                            profilesPolicy100
                            profilesPolicy55
                            allPolicies
                            __typename
                        }
                        daWinPatchInformation {
                            winPatchVersion
                            winPatchDescription
                            __typename
                        }
                        posture {
                            lastScanStatus
                            lastScanStatusDescription
                            lastScanManualStarted
                            __typename
                        }
                        computerId
                        computerName
                        computerIP
                        computerClientVersion
                        computerDeployTime
                        computerLastErrorCode
                        computerLastErrorDescription
                        computerLastConnection
                        computerSyncedon
                        computerLastLoggedInUser
                        computerUserName
                        computerLastLoggedInPrebootUser
                        computerFdeStatus
                        computerFdeVersion
                        computerFdeWilWolStatus
                        computerFdeWilWolStatusUpdatedOn
                        computerFdeLastRecoveryDate
                        computerFdeTpmStatus
                        computerFdeTpmVersion
                        computerFdeTpmId
                        computerFdeProgress
                        computerType
                        computerCapabilities {
                            onlyInstalledAndRun
                            onlyInstalled
                            onlyNotRunning
                            stoppedBlades
                            __typename
                        }
                        computerGroups {
                            name
                            id
                            __typename
                        }
                        computerDeploymentStatus
                        amUpdatedOn
                        osName
                        osVersion
                        daInstalled
                        endpointType
                        isolationStatus
                        distinguishedName
                        isDeleted
                        amStatus
                        complianceStatus
                        canonicalName
                        deviceParents {
                            nid
                            name
                            distinguishedName
                            canonicalName
                            domainName
                            ouType
                            groupType
                            groupScope
                            readOnly
                            nodeType
                            __typename
                        }
                        isInDomain
                        domainName
                        scannerId
                        fdeRemoteUnlockOperation
                        fdeRemoteUnlockUserName
                        fdeRemoteUnlockStatus
                        fdeRecoveryType
                        enforcedModifiedOn
                        enforcedPolicyMalware20
                        enforcedPolicyTe130
                        enforcedPolicyEfr120
                        enforcedPolicyAntibot100
                        enforcedPolicyMe30
                        enforcedPolicyFdeDevice35
                        enforcedPolicyFdeUser36
                        enforcedPolicyFw10
                        enforcedPolicyCompliance60
                        enforcedPolicyApplicationControl22
                        enforcedPolicySaAccessZones11
                        enforcedPolicyCommonClientSettings51
                        enforcedPolicyDocSecPolicy91
                        enforcedVersionPolicyMalware20
                        enforcedVersionPolicyTe130
                        enforcedVersionPolicyEfr120
                        enforcedVersionPolicyAntibot100
                        enforcedVersionPolicyMe30
                        enforcedVersionPolicyFdeDevice35
                        enforcedVersionPolicyFdeUser36
                        enforcedVersionPolicyFw10
                        enforcedVersionPolicyCompliance60
                        enforcedVersionPolicyApplicationControl22
                        enforcedVersionPolicySaAccessZones11
                        enforcedVersionPolicyCommonClientSettings51
                        enforcedVersionPolicyDocSecPolicy91
                        enforcedNamePolicyMalware20
                        enforcedNamePolicyTe130
                        enforcedNamePolicyEfr120
                        enforcedNamePolicyAntibot100
                        enforcedNamePolicyMe30
                        enforcedNamePolicyFdeDevice35
                        enforcedNamePolicyFdeUser36
                        enforcedNamePolicyFw10
                        enforcedNamePolicyCompliance60
                        enforcedNamePolicyApplicationControl22
                        enforcedNamePolicySaAccessZones11
                        enforcedNamePolicyCommonClientSettings51
                        enforcedNamePolicyDocSecPolicy91
                        deployedModifiedOn
                        deployedPolicyMalware20
                        deployedPolicyTe130
                        deployedPolicyEfr120
                        deployedPolicyAntibot100
                        deployedPolicyMe30
                        deployedPolicyFdeDevice35
                        deployedPolicyFdeUser36
                        deployedPolicyFw10
                        deployedPolicyCompliance60
                        deployedPolicyApplicationControl22
                        deployedPolicySaAccessZones11
                        deployedPolicyCommonClientSettings51
                        deployedPolicyDocSecPolicy91
                        deployedVersionPolicyMalware20
                        deployedVersionPolicyTe130
                        deployedVersionPolicyEfr120
                        deployedVersionPolicyAntibot100
                        deployedVersionPolicyMe30
                        deployedVersionPolicyFdeDevice35
                        deployedVersionPolicyFdeUser36
                        deployedVersionPolicyFw10
                        deployedVersionPolicyCompliance60
                        deployedVersionPolicyApplicationControl22
                        deployedVersionPolicySaAccessZones11
                        deployedVersionPolicyCommonClientSettings51
                        deployedVersionPolicyDocSecPolicy91
                        deployedNamePolicyMalware20
                        deployedNamePolicyTe130
                        deployedNamePolicyEfr120
                        deployedNamePolicyAntibot100
                        deployedNamePolicyMe30
                        deployedNamePolicyFdeDevice35
                        deployedNamePolicyFdeUser36
                        deployedNamePolicyFw10
                        deployedNamePolicyCompliance60
                        deployedNamePolicyApplicationControl22
                        deployedNamePolicySaAccessZones11
                        deployedNamePolicyCommonClientSettings51
                        deployedNamePolicyDocSecPolicy91
                        computerAmDatVersion
                        computerAmDatDate
                        computerAmLicExpirationDate
                        computerAmTotalInfected
                        computerAmVersion
                        computerNotRunningBladesMask
                        computerStatusSummary {
                            AM_Status
                            FDE_Status
                            FDE_ProgressPercentage
                            FDE_LastRecoveryDate
                            FDE_AcquiredUsers
                            FDE_TotalUsersToAcquire
                            Compliance_Status
                            SD_Status
                            DA_Not_Running_Blades_Mask
                            WC_Status
                            DLP_Status
                            WIL_WOL_Status
                            Smart_Card_Driver_Status
                            __typename
                        }
                        computerSdPackageName
                        computerSdPolicyName
                        computerSdPolicyVersion
                        computerAbState
                        computerAbStatusBotNames
                        computerAmScannedon
                        computerAmTotalQuarantined
                        computerLastContactedPolicyServerIp
                        computerLastContactedPolicyServerName
                        computerSdPackageVersion
                        computerComplianceViolationIds
                        computerFdePrebootStatusUpdatedOn
                        computerAmInfections
                        computerSmartCardStatus
                        amProviderBrand
                        __typename
                    }
                    __typename
                }
            }"
            if ($Name) {
                $hVariables = @{
                    paging = @{
                        offset = $offset
                        pageSize = $pageSize
                    }
                    filter = New-EPSComputerFilter "computerName" -eq $Name
                    sorting = New-EPSComputerSorting "computerLastConnection" -Descending
                }
            } else {
                $hVariables = @{
                    paging = @{
                        offset = $offset
                        pageSize = $pageSize
                    }
                    viewType = $viewType
                }
                if ($filter) {
                    $hVariables.filter = $filter
                }    
            }
        }
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        if ($Name) {
            $aComputers = $oAPIResult.data.$sOperationName.computers
            if ($aComputers) {
                $oResult = $aComputers[0]
                $oResult.PSTypeNames.Insert(0, "CheckPoint EPS OnPrem")
                return $oResult
            } else {
                return $null
            }
        } else {
            return $oAPIResult.data.$sOperationName
        }
    }
}
