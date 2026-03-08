function Get-RuleSettings {
    Param(
        [object]$EPSAPI,
        [string]$RuleId,
        [string]$Family,
        [int]$ConnectionState
    )
    Begin {
        $oEPSAPI = if ($EPSAPI) { $EPSAPI } else { $Global:EPSAPI }
        $sOperationName = "rulesSettings"
        $sQuery = "query rulesSettings(`$ruleId: String, `$family: String, `$connectionState: Int) {
            rulesSettings(ruleId: `$ruleId, family: `$family, connectionState: `$connectionState) {
              ruleId
              version
              versions {
                version
                blade
                __typename
              }
              connectionState
              lastModifiedOn
              lastModifiedOnTimestamp
              hasDifferentVersion
              missingCapabilities
              lastModifiedBy
              capabilities {
                webAndFilesProtection {
                  urlFiltering {
                    urlFilteringMode
                    forceSafeSearch
                    __typename
                  }
                  downloadProtection {
                    downloadProtectionMode
                    downloadProtectionExtractMode
                    __typename
                  }
                  credentialProtection {
                    zeroPhishingProtectionMode
                    passwordProtectionMode
                    __typename
                  }
                  fileProtectionEmulation {
                    fileThreatEmulationMode
                    fileThreatEmulationEnvironmentMode
                    __typename
                  }
                  fileProtectionAntiVirus {
                    antiVirusMode
                    amAdditionalFeatures {
                      detectMode {
                        enabled
                        __typename
                      }
                      __typename
                    }
                    __typename
                  }
                  __typename
                }
                remediationAndAnalysis {
                  remediationAndResponse {
                    fileQuarantineState
                    attackRemediation
                    __typename
                  }
                  forensics {
                    forensicsMode
                    edrConfig {
                      enableEdr
                      edrServiceState
                      __typename
                    }
                    __typename
                  }
                  __typename
                }
                behavioralProtection {
                  antiBot {
                    onLowConfidence
                    onMediumConfidence
                    onHighConfidence
                    __typename
                  }
                  antiExploit {
                    antiExploitMode
                    __typename
                  }
                  antiRansomware {
                    antiRansomwareBehaviouralGuardMode
                    __typename
                  }
                  __typename
                }
                clientSettingsAndDeployment {
                  commonClientPolicy {
                    id
                    legacyCategory
                    enablePostponeInstallation
                    remindUserMinutes
                    forceInstallationHours
                    maxDelayDownloadHours
                    enableChallengeResponse
                    responseLength
                    defaultClientUninstallPasswordCounter
                    wasPasswordChanged
                    enableDataSharing
                    shareDataFilesRelatedToDetection
                    shareDataAnonimizedForensicsReport
                    shareDataMemoryDumps
                    prebootBackgroundUefi {
                      origName
                      md5
                      pathIdentifier
                      size
                      __typename
                    }
                    prebootBackground {
                      origName
                      md5
                      pathIdentifier
                      size
                      __typename
                    }
                    prebootScreenSaver {
                      origName
                      md5
                      pathIdentifier
                      size
                      __typename
                    }
                    prebootBanner {
                      origName
                      md5
                      pathIdentifier
                      size
                      __typename
                    }
                    oneCheckBackground {
                      origName
                      md5
                      pathIdentifier
                      size
                      __typename
                    }
                    userCheckIconImage {
                      origName
                      md5
                      pathIdentifier
                      size
                      __typename
                    }
                    showClientIcon
                    showLogViewer
                    notificationsLevel
                    enableLogUpload
                    maxEventsToUpload
                    eventsBeforeAttemptingUpload
                    logUploadIntervalMinutes
                    maxEventAgeToUploadEnable
                    maxEventAgeToUploadDays
                    eventDiscardAgeEnable
                    eventDiscardAgeDays
                    pushOpsServerUpdateIntervalMinutes
                    allowNetworkProtectionShutdown
                    networkProtectionAlerts {
                      id
                      allowAlert
                      allowLog
                      featureType
                      __typename
                    }
                    enableDeploymentLocations
                    enableServerDeployment
                    deploymentLocations {
                      id
                      type
                      supportedPlatform
                      pkgPath
                      __typename
                    }
                    commonClientAdditionalFeatures {
                      authenticatedProxy {
                        proxy
                        data {
                          username
                          password
                          __typename
                        }
                        __typename
                      }
                      generalUpdate {
                        disabled
                        checkIntervalMins
                        baseUrl
                        __typename
                      }
                      superNode {
                        enabled
                        SNList {
                          epguid
                          fqdn
                          nodeType
                          displayName
                          __typename
                        }
                        __typename
                      }
                      InnerSrc {
                        connectedTo
                        src
                        __typename
                      }
                      conn_awareness_v8530 {
                        connectedTo
                        sources {
                          type
                          source
                          __typename
                        }
                        __typename
                      }
                      __typename
                    }
                    __typename
                  }
                  deploymentPolicy {
                    legacyCategory
                    deploymentBlades {
                      family
                      bladeMask
                      selected
                      __typename
                    }
                    selectedPackage {
                      version
                      __typename
                    }
                    selectedMacPackage {
                      version
                      __typename
                    }
                    deploymentMacBlades {
                      family
                      bladeMask
                      selected
                      __typename
                    }
                    availablePackages {
                      version
                      featuresIncluded
                      packageTypes
                      __typename
                    }
                    __typename
                  }
                  __typename
                }
                accessCompliance {
                  compliance {
                    uid
                    name
                    shortName
                    type
                    comments
                    clientAction {
                      uid
                      name
                      comments
                      isRunning
                      isInstalled
                      action {
                        uid
                        name
                        cpmiDisplayName
                        __typename
                      }
                      remediation {
                        uid
                        name
                        type
                        runArgs
                        runAs
                        useResource
                        remediationPath
                        verificationData
                        applyToWarnAndRestrict
                        remediationUrl
                        comments
                        __typename
                      }
                      __typename
                    }
                    wsusAction {
                      uid
                      name
                      comments
                      isEnabled
                      maxDays
                      action {
                        uid
                        name
                        cpmiDisplayName
                        __typename
                      }
                      remediation {
                        uid
                        name
                        type
                        runArgs
                        runAs
                        useResource
                        remediationPath
                        verificationData
                        applyToWarnAndRestrict
                        notifyUser
                        remediationUrl
                        comments
                        __typename
                      }
                      __typename
                    }
                    restrictedFilesAction {
                      uid
                      name
                      type
                      comments
                      rules {
                        objId
                        rulename
                        type
                        operand
                        action {
                          uid
                          name
                          type
                          cpmiDisplayName
                          __typename
                        }
                        checks {
                          uid
                          name
                          type
                          __typename
                        }
                        remediation {
                          uid
                          name
                          __typename
                        }
                        cpmiComments
                        disabled
                        __typename
                      }
                      __typename
                    }
                    appFilesAction {
                      uid
                      name
                      type
                      comments
                      rules {
                        objId
                        rulename
                        type
                        operand
                        action {
                          uid
                          name
                          type
                          cpmiDisplayName
                          __typename
                        }
                        checks {
                          uid
                          name
                          type
                          __typename
                        }
                        remediation {
                          uid
                          name
                          __typename
                        }
                        cpmiComments
                        disabled
                        __typename
                      }
                      __typename
                    }
                    servicePackAction {
                      uid
                      name
                      type
                      comments
                      rules {
                        objId
                        rulename
                        type
                        operand
                        action {
                          uid
                          name
                          type
                          cpmiDisplayName
                          __typename
                        }
                        checks {
                          uid
                          name
                          type
                          __typename
                        }
                        remediation {
                          uid
                          name
                          __typename
                        }
                        cpmiComments
                        disabled
                        __typename
                      }
                      __typename
                    }
                    antiVirusAction {
                      uid
                      name
                      type
                      comments
                      rules {
                        objId
                        rulename
                        type
                        operand
                        action {
                          uid
                          name
                          type
                          cpmiDisplayName
                          __typename
                        }
                        checks {
                          uid
                          name
                          type
                          __typename
                        }
                        remediation {
                          uid
                          name
                          __typename
                        }
                        cpmiComments
                        disabled
                        __typename
                      }
                      __typename
                    }
                    vpnCompliance {
                      uid
                      name
                      vpnSource
                      comments
                      __typename
                    }
                    __typename
                  }
                  applicationControl {
                    defaultAction
                    developerProtection
                    terminateOnExecution
                    allowWSL
                    legacyCategory
                    __typename
                  }
                  accessZones {
                    uid
                    name
                    shortName
                    _original_type
                    type
                    category
                    domainsPreset
                    objectValidationState
                    color
                    uepmName
                    policyModifiedon
                    displayname
                    trustedAction {
                      uid
                      name
                      shortName
                      _original_type
                      type
                      category
                      domainsPreset
                      displayname
                      trusted {
                        uid
                        name
                        shortName
                        _original_type
                        type
                        category
                        natSummaryText
                        ipaddrLast6
                        ipaddrFirst6
                        ipaddrFirst
                        ipaddrLast
                        __typename
                      }
                      __typename
                    }
                    dynamicContent {
                      domainsPreset
                      domainId
                      status
                      content
                      __typename
                    }
                    __typename
                  }
                  firewall {
                    legacyCategory
                    uid
                    name
                    shortName
                    allowIpv6 {
                      uid
                      allowIpv6
                      __typename
                    }
                    hotspotSettings {
                      uid
                      name
                      hotspotAllowRegistration
                      __typename
                    }
                    wirelessSettings {
                      uid
                      name
                      disableWirelessOnLan
                      __typename
                    }
                    firewallPolicyIndication
                    vpnFirewall {
                      uid
                      name
                      __typename
                    }
                    incomingAction {
                      uid
                      name
                      shortName
                      fwIncomingRules {
                        objId
                        rulename
                        disabled
                        action {
                          uid
                          name
                          __typename
                        }
                        services {
                          uid
                          name
                          type
                          __typename
                        }
                        destination {
                          uid
                          name
                          type
                          __typename
                        }
                        source {
                          uid
                          name
                          type
                          __typename
                        }
                        track {
                          uid
                          name
                          shortName
                          __typename
                        }
                        __typename
                      }
                      __typename
                    }
                    outgoingAction {
                      uid
                      name
                      shortName
                      fwOutgoingRules {
                        objId
                        rulename
                        disabled
                        action {
                          uid
                          name
                          __typename
                        }
                        services {
                          uid
                          name
                          type
                          __typename
                        }
                        destination {
                          uid
                          name
                          type
                          __typename
                        }
                        source {
                          uid
                          name
                          type
                          __typename
                        }
                        track {
                          uid
                          name
                          shortName
                          __typename
                        }
                        __typename
                      }
                      __typename
                    }
                    __typename
                  }
                  __typename
                }
                dataSecurity {
                  mediaEncryptionPolicy {
                    legacyCategory
                    storageReadAccess {
                      allowReadPlain
                      allowReadEncrypted
                      allowExecute
                      readExclusions {
                        id
                        allowReadPlain
                        allowReadEncrypted
                        allowExecute
                        deviceOrGroup
                        __typename
                      }
                      __typename
                    }
                    storageWriteAccess {
                      allowWritePlain
                      allowWriteEncrypted
                      allowEncryptRmd
                      auditDevice
                      encryptNonCorporate
                      corporatePolicy {
                        mode
                        blacklist
                        whitelist
                        __typename
                      }
                      enableReadOnlyDelete
                      askWriteWhenReadOnly
                      askWriteLevel
                      writeExclusions {
                        id
                        allowWritePlain
                        allowWriteEncrypted
                        auditDevice
                        askWriteWhenReadOnly
                        allowEncryptRmd
                        deviceOrGroup
                        __typename
                      }
                      __typename
                    }
                    portProtection {
                      portRules {
                        id
                        disabled
                        accessType
                        logType
                        cpmiComments
                        devicesAndCategories
                        __typename
                      }
                      __typename
                    }
                    macPortProtection {
                      enabled
                      portRules {
                        name
                        allowed
                        audit
                        serialNumber
                        deviceClass
                        comments
                        __typename
                      }
                      __typename
                    }
                    offlineAccess {
                      allowEncryptRmd
                      allowEncryptForOthers
                      allowEncryptChangeSize
                      allowEncryptRemove
                      allowEncryptUpgrade
                      changeDeviceNameOnlyAfterEncryption
                      plainDataOnEncrypt
                      allowChangeFileSystemFormat
                      fileSystemFormat
                      calculationType
                      formatBeforeEncrypt
                      numberOfFormats
                      encContainerSize
                      defaultEncContainerSize
                      offlinePwdProtect
                      allowRemoteHelp
                      copyUtility
                      offlinePwdProtectReadOnly
                      allowChangeReadOnlyPwd
                      __typename
                    }
                    lockoutSettings {
                      enableLockoutSettings
                      enableMaxLogonFailBeforeLock
                      maxLogonFailToLock
                      enableMaxLogonFailBeforeTempLock
                      maxLogonFailToTempLock
                      lockoutDuration
                      __typename
                    }
                    mediaScanAction {
                      scanAndAuthorize
                      enableUserAuthorize
                      mediaAuthorization
                      corporatePolicy {
                        mode
                        blacklist
                        whitelist
                        __typename
                      }
                      autoAllowDelete
                      manualAllowSkip
                      manualAllowDelete
                      enableOpticalMediaScan
                      enableScanReadOnlyOpticalMedia
                      enableScanReadWriteOpticalMedia
                      __typename
                    }
                    mediaLogSettings {
                      logLevel
                      __typename
                    }
                    userAlerts {
                      encryptNonMandatoryMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      encryptNonMandatoryInserted
                      encryptWriteAccessMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      encryptWriteAccessWrite
                      encryptWriteAccessInserted
                      deviceBlockedMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      deviceBlockedInserted
                      deviceReadOnlyMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      deviceReadOnlyWrite
                      deviceReadOnlyInserted
                      askWritePlainMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      askWriteEncryptedMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      askEncryptCorporateMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      showFirstEncryptionCorporate
                      firstEncryptionCorporateDataMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      showEncryptionCorporateData
                      encryptionCorporateDataMsg {
                        blobXML
                        templateId
                        __typename
                      }
                      __typename
                    }
                    encryptionSites {
                      managementServer
                      trustedServers
                      currentSite
                      __typename
                    }
                    __typename
                  }
                  fullDiskEncryptionPolicy {
                    legacyCategory
                    enablePrebootAuthentication
                    tempPrebootBypass
                    tempPrebootBypassTimeSettings {
                      id
                      type
                      periodType
                      dayOfWeek
                      hour
                      onceStartTime
                      enableMaxLogons
                      maxLogons
                      enableExpirationDate
                      expirationDate
                      expirationDatePeriodType
                      __typename
                    }
                    prebootBypassScript
                    prebootBypassScriptTimeSettings {
                      id
                      type
                      periodType
                      dayOfWeek
                      hour
                      onceStartTime
                      enableMaxLogons
                      maxLogons
                      enableExpirationDate
                      expirationDate
                      expirationDatePeriodType
                      __typename
                    }
                    tempPrebootBypassOnLAN
                    tempPrebootBypassOnLANTimeSettings {
                      id
                      type
                      periodType
                      dayOfWeek
                      hour
                      onceStartTime
                      enableMaxLogons
                      maxLogons
                      enableExpirationDate
                      expirationDate
                      expirationDatePeriodType
                      __typename
                    }
                    tempPrebootBypassAutomaticOsLogonDelay
                    tempPrebootBypassAllowOsLogin
                    remoteHelpAction {
                      enabled
                      responseLength
                      __typename
                    }
                    bitLockerAction {
                      enableBitlocker
                      initialEncryption
                      drivesToEncrypt
                      encryptionAlgo
                      __typename
                    }
                    prebootAdvancedAction {
                      usbEnabled
                      pcmciaEnabled
                      mouseEnabled
                      allowHibernation
                      failedLogonRebootCount
                      successDialogTimeout
                      tpmEnabled
                      tpmFirmwareFriendly
                      __typename
                    }
                    prebootBypassAction {
                      maxFailedWindowsLogonAttempts
                      hardwareHash
                      netLocationAwareness
                      failureMessage
                      tpm
                      __typename
                    }
                    prebootAuthenticationAction {
                      bypassOnLAN
                      bypassOnLANUnlockAccount
                      displayUsername
                      __typename
                    }
                    encryptionAction {
                      algorithm
                      level
                      encryptHiddenVolumes
                      dynamicEncryption
                      allowSED
                      allowRAID
                      __typename
                    }
                    userAcquisitionAction {
                      enableUserAcquisition
                      usersCount
                      daysCount
                      daysEnabled
                      continueEnabled
                      continueCount
                      __typename
                    }
                    oneCheckAction {
                      enabled
                      screenSaverEnabled
                      screenSaverText
                      screenSaverTimeout
                      onlyPrebootUsersAllowed
                      usePrebootUserInWindows
                      __typename
                    }
                    enableRHC
                    fieMode
                    __typename
                  }
                  oneCheckPolicy {
                    legacyCategory
                    passwordSyncAction {
                      syncPrebootPassToWin
                      syncWinPassToPreboot
                      allowOsPasswordReset
                      __typename
                    }
                    passwordComplexityAction {
                      passwordRequirements
                      allowConsecutiveIdenticalLetters
                      requireSpecialCharacters
                      requireDigits
                      requireLowerCaseCharacters
                      requireUpperCaseCharacters
                      mustNotContainName
                      minPasswordLength
                      enableMinTimeBeforePasswordChange
                      minChangeTime
                      enableMaxTimeBeforePasswordChange
                      maxChangeTime
                      reusePasswordAfter
                      __typename
                    }
                    lockoutSettings {
                      enableLockoutSettings
                      enableMaxLogonFailBeforeLock
                      maxLogonFailToLock
                      enableMaxLogonFailBeforeTempLock
                      maxLogonFailToTempLock
                      lockoutDuration
                      maxLogonAttemptsBeforeLockout
                      __typename
                    }
                    remoteHelp {
                      allowOneTimeLogonRemoteHelp
                      allowPasswordRemoteHelp
                      __typename
                    }
                    logonPermission {
                      allowLogonToHibernatedSharedSystem
                      allowRecoveryMedia
                      allowChangeCredentialsFromClient
                      allowSingleSignOn
                      __typename
                    }
                    __typename
                  }
                  fullDiskEncryptionGlobalPolicy {
                    legacyCategory
                    enableSmartCardAuthentication
                    smartCardType
                    scanUserCertificate
                    scanUserCertificateFilter
                    changeAuthenticationMethod
                    allowSmartCardGracePeriod
                    newDrivers {
                      deviceName
                      __typename
                    }
                    smartcardDrivers {
                      binaryName
                      type
                      version
                      firmware
                      devices {
                        uid
                        name
                        __typename
                      }
                      __typename
                    }
                    mediaAccess {
                      rules {
                        id
                        nextId
                        ownerId
                        userId
                        accessRights
                        isDefaultEntry
                        __typename
                      }
                      __typename
                    }
                    __typename
                  }
                  __typename
                }
                behavioralProtection {
                  antiBot {
                    onLowConfidence
                    onMediumConfidence
                    onHighConfidence
                    __typename
                  }
                  antiExploit {
                    antiExploitMode
                    __typename
                  }
                  antiRansomware {
                    antiRansomwareBehaviouralGuardMode
                    __typename
                  }
                  __typename
                }
                __typename
              }
              __typename
            }
          }
          "
        $hVariables = @{}
        if ($Family) {
            $hVariables["family"] = $Family
        }
        if ($RuleId) {
            $hVariables["ruleId"] = $RuleId
        }
        if ($PSBoundParameters.ContainsKey("ConnectionState")) {
            $hVariables["connectionState"] = $ConnectionState
        }
    }
    Process {
        $oAPIResult = $oEPSAPI.CallAPI($sOperationName, $sQuery, $hVariables)
        return $oAPIResult.data.rulesSettings
    }
}
