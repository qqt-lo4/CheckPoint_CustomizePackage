#region Includes
. $PSScriptRoot\UDF\7-zip\New-7ZipArchive.ps1
. $PSScriptRoot\UDF\7-zip\New-7ZipSFX.ps1
. $PSScriptRoot\UDF\7-zip\New-SFXConfigFile.ps1
. $PSScriptRoot\UDF\API\Invoke-IgnoreSSL.ps1
. $PSScriptRoot\UDF\Array\Get-ArrayPage.ps1
. $PSScriptRoot\UDF\AutoIt\Invoke-AutoItCompile.ps1
. $PSScriptRoot\UDF\AutoIt\New-PowershellScriptRunner.ps1
. $PSScriptRoot\UDF\AutoIt\Search-AutoItCompile.ps1
. $PSScriptRoot\UDF\Cabinet\Expand-CABFile.ps1
. $PSScriptRoot\UDF\Cabinet\Get-CABContentList.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\ConvertTo-EPSInstalledFeatures.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\class-tracDefaultsSetting.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\class-tracDefaultsSettings.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Set-TracDefaultsConfig.ps1
. $PSScriptRoot\UDF\CheckPoint\EPS_server\Connect\Connect-EPSAPI.ps1
. $PSScriptRoot\UDF\CheckPoint\EPS_server\Jobs\Get-EPSJobStatus.ps1
. $PSScriptRoot\UDF\CheckPoint\EPS_server\Jobs\Wait-EPSJobEnd.ps1
. $PSScriptRoot\UDF\CheckPoint\EPS_server\Packages\Get-ExportPackages.ps1
. $PSScriptRoot\UDF\CheckPoint\EPS_server\Packages\Get-Packages.ps1
. $PSScriptRoot\UDF\CheckPoint\EPS_server\Packages\Download-EPSPackage.ps1
. $PSScriptRoot\UDF\CLI\Dialog\Invoke-CLIDialog.ps1
. $PSScriptRoot\UDF\CLI\Dialog\Invoke-YesNoCLIDialog.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialog.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialogButton.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialogObjectsRow.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialogSeparator.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialogSpace.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialogTableItems.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialogText.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-CLIDialogTextBox.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-DialogResultAction.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-DialogResultScriptblock.ps1
. $PSScriptRoot\UDF\CLI\Dialog\New-DialogResultValue.ps1
. $PSScriptRoot\UDF\CLI\Dialog\Select-CLIFileFromFolder.ps1
. $PSScriptRoot\UDF\CLI\Dialog\Select-CLIJsonFile.ps1
. $PSScriptRoot\UDF\CLI\Dialog\Select-CLIObjectInArray.ps1
. $PSScriptRoot\UDF\CLI\Convert-ConsoleColorToInt.ps1
. $PSScriptRoot\UDF\CLI\Get-ItemSelectedByUser.ps1
. $PSScriptRoot\UDF\CLI\Invoke-Pause.ps1
. $PSScriptRoot\UDF\CLI\Read-NumericValue.ps1
. $PSScriptRoot\UDF\CLI\Read-ValidatedValue.ps1
. $PSScriptRoot\UDF\ConnectionInfo\Read-CLIDialogConnectionInfo.ps1
. $PSScriptRoot\UDF\File\Invoke-WindowsFileExplorer.ps1
. $PSScriptRoot\UDF\File\Select-FileFromFolder.ps1
. $PSScriptRoot\UDF\Format\Format-TableCustom.ps1
. $PSScriptRoot\UDF\Format\Get-ColumnFormat.ps1
. $PSScriptRoot\UDF\GraphQL\Invoke-GraphQLQuery.ps1
. $PSScriptRoot\UDF\Hashtable\ConvertTo-Hashtable.ps1
. $PSScriptRoot\UDF\Hashtable\Copy-Hashtable.ps1
. $PSScriptRoot\UDF\Json\ConvertFrom-Jsonc.ps1
. $PSScriptRoot\UDF\Json\Get-JSONFileList.ps1
. $PSScriptRoot\UDF\Path\Resolve-PathWithVariables.ps1
. $PSScriptRoot\UDF\Path\Split-PathToHashTable.ps1
. $PSScriptRoot\UDF\Programs\Get-ApplicationUninstallRegKey.ps1
. $PSScriptRoot\UDF\Registry\Get-FileTypeShellExtensionCommand.ps1
. $PSScriptRoot\UDF\Script\Get-PowershellScriptWithIncludedDependancies.ps1
. $PSScriptRoot\UDF\Script\Get-ScriptDir.ps1
. $PSScriptRoot\UDF\Script\Replace-ScriptRegion.ps1
. $PSScriptRoot\UDF\Services\Wait-ServiceStatus.ps1
. $PSScriptRoot\UDF\String\ConvertTo-String.ps1
. $PSScriptRoot\UDF\String\Set-StringFormat.ps1
. $PSScriptRoot\UDF\String\Set-StringUnderline.ps1
. $PSScriptRoot\UDF\System\Test-IsAdmin.ps1
. $PSScriptRoot\UDF\Test-Input\Test-ValidNumberInput.ps1
. $PSScriptRoot\UDF\URL\ConvertTo-URL.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Get-MSIBinary.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Get-MSIProperty.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Get-MSIStreams.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Get-MSISummary.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Invoke-MSISQLQuery.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Open-MSIFile.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Set-MSIBinary.ps1
. $PSScriptRoot\UDF\WindowsInstaller\Set-MSIProperty.ps1
#endregion Includes

$variables = {
    $script_mode = "main"
    $EXIT_NOT_INSTALLED_BAD_CRED = 1
    $EXIT_OUTPUT_FOLDER_NOT_EMPTY = 2
    $EXIT_NO_VPN_INSTALLED = 3
}

#region script info
#scriptType=standard
#scriptVersion=2.2
#endregion script info




#region Release notes
<#1.0: First release
1.1: 
Removed :
- test recent connection
- VPN site creation
- trac.config and trac.defaults copy files
- no more calling vpnconfig.exe
Changed :
- trac.defaults items copied to config.json
1.1.1: 
Changed output encoding to force UTF8 with BOM
2.0: 
Added :
- It's now possible to create site and put the trac.config file inside the MSI
- It's now possible to specify a MSI path (instead of copying it to the input folder)
Changed :
- Package name is generated from MSI content
- Post actions for CheckPoint_CustomizePackage and Install-CheckPointEndpointSecurity 
moved to different json config files
2.1: 
Added: 
- Dynamic EXE management
2.2: 
Changed :
- selecting the right file (EPS.msi or install.exe) was not working
- a 2.1 version was not using the good sfxConfig.txt
- EXE extraction is done on a temp subdirectory which change each time
- output folder contains now selectedBlades (if dynamic package is selected)
Added :
- now you can download a package from your management server using this script
- opening file explorer at the end of package generation
#>
#endregion Release notes

#region Functions
function Select-CheckPointPackage {
    Param(
        [string]$selectHeaderMessage = "Please select a Check Point Endpoint Security package to customize:"
    )
    $aDialogRows = @(
        New-CLIDialogText $selectHeaderMessage -ForegroundColor Green -AddNewLine
        New-CLIDialogButton -Text "&Download from management (> R81)" -Keyboard D -AddNewLine -Object {
            $oNewFile = Download-CheckPointPackage
            return New-DialogResultAction -Action "Other" -Value $oNewFile
        }
        New-CLIDialogButton -Text "&Select from repository" -Keyboard S -AddNewLine -Object { 
            $inputFolder = $PSScriptRoot + "\input\CheckPoint_package"
            $oResult = Select-CLIFileFromFolder -Path $inputFolder -Filter "*.msi", "*.exe" -ColumnName "Check Point Package" -SeparatorColor Blue -Recurse -SelectHeaderMessage $selectHeaderMessage -EmptyArrayMessage "No Check Point package in input folder"
            $oResult.PackageType = $oResult.Value.Extension.Replace(".", "").ToUpper()
            return $oResult        
        }
        New-CLIDialogButton -Text "Select an&other file" -Keyboard O -AddNewLine -Object {
            $validOtherFile = $false
            while (-not $validOtherFile) {
                $sOtherFilePath = Read-Host -Prompt "Please enter a file path"
                if ($sOtherFilePath -match "^\""(.+)\""$") {
                    $sOtherFilePath = $Matches.1
                }
                $validOtherFile = Test-Path -Path $sOtherFilePath -PathType Leaf
                if (-not $validOtherFile) {
                    Write-Host "File path is not valid" -ForegroundColor Red
                }
            }
            $oNewFile = Get-Item -Path $sOtherFilePath
            return New-DialogResultAction -Action "Other" -Value $oNewFile
        }
    )
    return Invoke-CLIDialog -InputObject $aDialogRows -Execute
}

function Download-CheckPointPackage {
    $oConnectionDialogResult = if ($Global:EPSAPI) {
        Read-CLIDialogConnectionInfo -HeaderAppName "Harmony Endpoint Web server" -DefaultServer $EPSAPI.Server -DefaultPort $EPSAPI.Port -DefaultUsername $EPSAPI.User
    } else {
        Read-CLIDialogConnectionInfo -HeaderAppName "Harmony Endpoint Web server"
    }
    
    if ($oConnectionDialogResult.Type -eq "Value") {
        $oConnectionInfo = $oConnectionDialogResult.Value
        Connect-EPSAPI -Username $oConnectionInfo.Username `
                       -Password $oConnectionInfo.Password `
                       -Server $oConnectionInfo.Server `
                       -Port $oConnectionInfo.port `
                       -IgnoreSSLError -GlobalVar
        $aPackages = Get-ExportPackages
        $oSelectedPackage = Select-CLIObjectInArray -Objects $aPackages -SelectedColumns "name", @{l = "bladesSelected"; e = {ConvertTo-EPSInstalledFeatures $_.bladesSelected -StringOutput -RemoveDA}} -FooterMessage "" -SeparatorColor Blue
        if ($oSelectedPackage.Type -eq "Value") {
            return Download-EPSPackage -softwarePackageId $oSelectedPackage.Value.softwareVersionGuid -blades $oSelectedPackage.Value.bladesSelected -id $oSelectedPackage.Value.id -waitEnd
        }
    } else {
        return $null
    }
}

function Replace-CheckPointInstallScriptParameters {
    Param(
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$packageName,
        [Parameter(Mandatory, ParameterSetName = "Script")]
        [object]$powershellScript,
        [Parameter(Mandatory, ParameterSetName = "File")]
        [string]$powershellFile
    )
    $newParameters = @"
    Param(
		[ValidateSet("EN", "FR", "JP", "ES", "IT", "DE", "PT", "RU", "CS", "EL", "PL", "")]
        [AllowEmptyString()]
        [string]`$language,
        [string]`$uninstPasswd = "",
        [string]`$packageToInstall = "$packageName"
    )
"@

    $oldScript = switch ($PSCmdlet.ParameterSetName) {
        "Script" {
            if ($powershellScript -is [string]) {
                $powershellScript -split "`n"
            } elseif ($powershellScript -is [array]) {
                $powershellScript
            }
        }
        "File" {
            Get-Content $powershellFile
        }
    }
    $result = Replace-ScriptRegion -regionName "Script Parameters" -powershellScript $oldScript -newRegionValue $newParameters
    return $result
}

function Get-InstallerConfig {
    Param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    $inputDir = Get-ScriptDir -InputDir -FullPath
    $hCommonParameters = @{
        FooterMessage = $null
        HeaderColor = "Blue"
        SeparatorColor = "Blue"
        HeaderTextInSeparator = $true
        AlwaysAskUser = $true
        DisplaySelectedItem = $true
    }

    $jsonSiteInputDir = $inputDir + "\site\"
    $siteConfigurationJson = Select-CLIJsonFile -jsonColumn "Site", "Authentication Method", "Details" -Sort "Site", "Authentication Method" `
                                                -jsonFolder $jsonSiteInputDir `
                                                -selectHeaderMessage "Please select a VPN site" `
                                                -errorMessage "Please select a valid site config file" `
                                                -filterFunction "Filter-JsonConfigFile" -filteredValue $hVariables `
                                                -SelectedItemText "Selected site:" `
                                                @hCommonParameters
    $hVariables["site"] = $siteConfigurationJson.Value.json.configuration.displayName

    $jsonInstallGeneralConfigInputDir = $inputDir + "\install_general_config\"
    $installGeneralConfigJson = Select-CLIJsonFile -jsonColumn "Description" -Sort "Description" `
                                                   -jsonFolder $jsonInstallGeneralConfigInputDir `
                                                   -selectHeaderMessage "Please select a general setup configuration file (log folders and SCCM tag)" `
                                                   -errorMessage "Please select a valid install config file" `
                                                   -filterFunction "Filter-JsonConfigFile" -filteredValue $hVariables `
                                                   -SelectedItemText "Selected setup general config:" `
                                                   @hCommonParameters

    $jsonInstallBeforeConfigInputDir = $inputDir + "\install_steps_before\"
    $installBeforeConfigJson = Select-CLIJsonFile -jsonColumn "Description" -Sort "Description" `
                                                  -jsonFolder $jsonInstallBeforeConfigInputDir `
                                                  -selectHeaderMessage "Please select steps to run before install" `
                                                  -errorMessage "Please select a valid config file" `
                                                  -filterFunction "Filter-JsonConfigFile" -filteredValue $hVariables `
                                                  -SelectedItemText "Selected steps to run before install:" `
                                                  @hCommonParameters

    $jsonInstallAfterConfigInputDir = $inputDir + "\install_steps_after\"
    $installAfterConfigJson = Select-CLIJsonFile -jsonColumn "Description" -Sort "Description" `
                                                 -jsonFolder $jsonInstallAfterConfigInputDir `
                                                 -selectHeaderMessage "Please select steps to run after install" `
                                                 -errorMessage "Please select a valid config file" `
                                                 -filterFunction "Filter-JsonConfigFile" -filteredValue $hVariables `
                                                 -SelectedItemText "Selected steps to run after install:" `
                                                 @hCommonParameters

    $jsonClientConfigInputDir = $inputDir + "\client_configuration\"
    $clientConfigurationJson = Select-CLIJsonFile -jsonColumn "Name", "Details" -Sort "Name", "Details" `
                                                  -jsonFolder $jsonClientConfigInputDir `
                                                  -selectHeaderMessage "Please select a Check Point configuration file (for trac.defaults customization)" `
                                                  -errorMessage "Please select a valid Check Point config file" `
                                                  -filterFunction "Filter-JsonConfigFile" -filteredValue $hVariables `
                                                  -SelectedItemText "Selected Check Point configuration file:" `
                                                  @hCommonParameters

    # ask if config shoud be embeded inside the MSI or done after installing MSI
    $TracDefaultsWhere = Invoke-YesNoCLIDialog -Message "Do you want to change trac.defaults inside MSI?" -YN  -Vertical `
                                               -YesButtonText "&Yes, integrate it inside MSI" `
                                               -NoButtonText "&No, change trac.defaults after setup"
    $sTracDefaultsWhere = if ($TracDefaultsWhere -eq "Yes") { "MSI" } else { "PS1" }
    $hVariables["TracDefaultsWhere"] = $sTracDefaultsWhere

    $jsonPackageCustomizationConfigInputDir = $inputDir + "\package_customization_msi\"
    $packageCustomizationMSIJson = Select-CLIJsonFile -jsonColumn "Description" -Sort "Description" `
                                                   -jsonFolder $jsonPackageCustomizationConfigInputDir `
                                                   -selectHeaderMessage "Please select a configuration file to customize the MSI Properties" `
                                                   -errorMessage "Please select a valid config file" `
                                                   -SelectedItemText "Selected customization for MSI file:" `
                                                   @hCommonParameters

    $jsonPackageCustomizationConfigInputDir = $inputDir + "\package_customization_post_actions\"
    $packageCustomizationPostActionsJson = Select-CLIJsonFile -jsonColumn "Description" -Sort "Description" `
                                                              -jsonFolder $jsonPackageCustomizationConfigInputDir `
                                                              -selectHeaderMessage "Please select custom actions to be ran after package generation" `
                                                              -errorMessage "Please select a valid config file" `
                                                              -SelectedItemText "Selected post actions file:" `
                                                              @hCommonParameters
           
    $hConfigJson = @{
        "package_to_install" = $PackageName
        "site" = $siteConfigurationJson.value.json.configuration
        "install_general_config" = $installGeneralConfigJson.value.json.install
        "install_steps_before" = $installBeforeConfigJson.value.json.install.steps_before
        "install_steps_after" = $installAfterConfigJson.value.json.install.steps_after
        "tracdefaults_where" = $sTracDefaultsWhere
        "client_configuration" = $clientConfigurationJson.value.json.configuration
        "package_customization_msi" = $packageCustomizationMSIJson.value.json.configuration
        "package_customization_post_actions" = $packageCustomizationPostActionsJson.value.json.configuration
    }
    return $hConfigJson
}

function Convert-SiteConfigToXML {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [object]$Config
    )
    $tracConfigXML = @"
<CONFIGURATION>
    <GW_USER gw="$($Config.displayName)" user="USER">
        <FROM_USER>
            <PARAM display_name="$($Config.displayName)"></PARAM>
            <PARAM gw_hostname="$($Config.site)"></PARAM>
            <PARAM gw_ipaddr="$($Config.site)"></PARAM>
            <PARAM authentication_method="$($Config.authenticationMethod)"></PARAM>
        </FROM_USER>
    </GW_USER>
    <USER user="USER">
        <FROM_USER>
            <PARAM active_site="$($Config.displayName)"></PARAM>
            <PARAM sdl_enabled="$($Config.sdl_enabled)"></PARAM>
            <PARAM debug_mode="$($Config.debug_mode)"></PARAM>
        </FROM_USER>
    </USER>
</CONFIGURATION>
"@
    $tracConfigXML = $tracConfigXML -replace "\s{2,}", ""
    $tracConfigXML = $tracConfigXML -replace "\n", ""
    return $tracConfigXML
}

function Get-ManagedENSServerConfig {
    Param(
        [Parameter(Mandatory)]
        [string]$ConfigDat
    )
    $xConfigDat = [xml](Get-Content -Path $ConfigDat)
    $sServerDN = $xConfigDat.DA_CONFIG.CPEPSNetwork.servers.server.dn | Select-Object -Unique
    $sServerName = ($sServerDN | Select-String -Pattern "^CN=[^,]+,O=([^.]+).+$").Matches.Groups[1].Value
    return  @{
        "ServerDN" = $sServerDN
        "ServerName" = $sServerName
        "EPMServerConfig" = $xConfigDat.DA_CONFIG
    }
}

function Get-CheckPointMSIInfo {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )
    if (Test-Path -Path $Path -PathType Leaf) {
        $hResult = @{}
        Open-MSIFile -Path $Path -GlobalVar
        $ahProperties = Get-MSIProperty
        $hResult.Add("Properties", $ahProperties)
        $aBinaries = Get-MSIStreams
        $hResult.Add("Binaries", $aBinaries)
        $sPackageName = ($ahProperties | Where-Object { $_.Property -eq "RELEASE_NAME"}).Value
        $hResult.Add("PackageName", $sPackageName)
        if ("Binary.CPINSTADDEXT_config.dat" -in $aBinaries) {
            # MSI is a managed Endpoint Security
            $sTempConfigDat = $env:TEMP + "\Binary.CPINSTADDEXT_config_" + (Get-Date -Format "yyyyMMdd_HHmm") + ".dat"
            Get-MSIBinary -Name "Binary.CPINSTADDEXT_config.dat" -OutputPath $sTempConfigDat
            $xConfigDat = [xml](Get-Content -Path $sTempConfigDat)
            Remove-Item $sTempConfigDat
            $sServerDN = $xConfigDat.DA_CONFIG.CPEPSNetwork.servers.server.dn | Select-Object -Unique
            $sServerName = ($sServerDN | Select-String -Pattern "^CN=[^,]+,O=([^.]+).+$").Matches.Groups[1].Value
            $hResult.Add("ServerDN", $sServerDN)
            $hResult.Add("ServerName", $sServerName)
            $hResult.Add("PackageType", "SmartEndpoint")
            $hResult.Add("EPMServerConfig", $xConfigDat.DA_CONFIG)
            $hResult.Add("SuggestedPackageName", ("EPS_" + $sPackageName + "_" + $sServerName.ToUpper()))
        } else {
            $hResult.Add("PackageType", "SmartDashboard")
            $hResult.Add("SuggestedPackageName", ("VPN_" + $sPackageName))
        }
        return $hResult
    } else {
        return $null
    }
}

function Get-MSITracDefaults {
    Param(
        [object]$MSIFile,
        [Parameter(Mandatory, Position = 0)]
        [string]$Path
    )
    Begin {
        $oMSIFile = if ($MSIFile) {
            $MSIFile
        } elseif ($global:MSIFile) {
            $global:MSIFile
        } else {
            throw [System.ArgumentNullException] "MSI File not opened, please use ""Open-MSIFile"""
        }
        $oMSIFile.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeReadOnly)
    }
    Process {
        $newTempFolder = ($env:TEMP + "\trac.defaults\")
        $newECCABTempFile = $newTempFolder + "EC.cab"
        if (Test-Path -Path $newTempFolder -PathType Container) { 
            if (Test-Path -Path ($newTempFolder + "trac.defaults")) {
                Remove-Item ($newTempFolder + "trac.defaults")
            }
        } else {
            New-Item -Path $newTempFolder -ItemType Directory -Force | Out-Null
        }
        Get-MSIBinary -Name "EC.cab" -OutputPath $newECCABTempFile
        $tracdefaultsInCAB = Get-CABContentList -CABFile $newECCABTempFile | Where-Object { $_ -like "trac.defaults.*" }
        Expand-CABFile -CABFile $newECCABTempFile -Destination $newTempFolder -Filename $tracdefaultsInCAB | Out-Null
        Remove-Item -Path $newECCABTempFile
        Rename-Item -Path ($newTempFolder + $tracdefaultsInCAB) -NewName "trac.defaults"
        return ($newTempFolder + "trac.defaults")
    }
}

function PackageCustomization_Copy-Item {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Source,
        [Parameter(Mandatory, Position = 1)]
        [string]$Destination,
        [hashtable]$Variables
    )
    $sSource = Resolve-PathWithVariables -Path $Source -Hashtable $Variables
    $sDestination = Resolve-PathWithVariables -Path $Destination -Hashtable $Variables
    Copy-Item -Path $sSource -Destination $sDestination
}

function PackageCustomization_Write-Host {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,
        [hashtable]$Variables
    )
    $sMessage = Resolve-PathWithVariables -Path $Message -Hashtable $Variables
    Write-Host $sMessage
}

function PackageCustomization_New-Runner {
    Param(
        [hashtable]$Variables
    )
    $hArgs = @{
        PS1FileName = "$outputFolder\Install-CheckPointEndpointSecurity.ps1"
        RunAsAdmin = $true
        X64 = $true
        CUI = $true
        Hashtable = $Variables
    }
    if ($hVariables["UpgradePasswordWhere"] -eq "PS1Launcher") {
        $hArgs.AdditionalArgumentsPasswordVariable = "-uninstPasswd $($hVariables["UpgradePassword"])"
    }
    New-PowershellScriptRunner @hArgs #-DoNotRemoveAU3
}

function Filter-JsonConfigFile {
    Param(
        [Parameter(Mandatory)]
        [object[]]$arrayJsonFiles,
        [Parameter(Mandatory)]
        [hashtable]$Variables
    )
    $aResult = @()
    foreach ($jsonFile in $arrayJsonFiles) {
        if ($jsonFile.json.Filter) {
            $bFilterOK = Invoke-Expression -Command $jsonFile.json.Filter
            if ($bFilterOK) {
                $aResult += $jsonFile
            }
        } else {
            $aResult += $jsonFile
        }
    }
    return $aResult
}

function Get-MSIInfo {
    Param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    $msi = Open-MSIFile -Path $Path
    return @{
        Properties = Get-MSIProperty -MSIFile $msi
        Binaries = Get-MSIStreams -MSIFile $msi
        MSI = $msi
    }
}

function Get-MSICheckPointVersion {
    Param(
        [parameter(Mandatory)]
        [object]$MSIInfo
    )
    $sVersion = ($MSIInfo.Properties | Where-Object { $_.Property -eq "RELEASE_NAME" }).Value
    return $sVersion
}

function Invoke-SelectedPackageNameDialog {
    Param(
        [Parameter(Mandatory)]
        [string]$selectedPackageName
    )
    $sResult = $selectedPackageName
    Write-Host ("Selected outut package name is: " + $selectedPackageName)
    $packageNameValidated = Invoke-YesNoCLIDialog -Message "Do you accept this package name as output folder?" -YN `
                                                  -YesButtonText "&Yes, use ""$selectedPackageName"" as output folder" `
                                                  -NoButtonText "&No, choose another folder name" -Vertical
    if ($packageNameValidated -eq "No") {
        $sNewPackageName = Read-ValidatedValue -header "Please enter output package name" -regex "^[a-zA-Z0-9 _.,-]+$"
        $sResult = $sNewPackageName.Value
    }
    Write-Host ("Selected package name = " + $sResult)
    return $sResult
}

function Invoke-ClearOrCreateOutputFolder {
    Param(
        [Parameter(Mandatory)]
        [string]$outputFolder
    )
    if (Test-Path $outputFolder -PathType Container) {
        $outputFolderContent = Get-ChildItem -Path $outputFolder
        if ($outputFolderContent) {
            # Dossier non vide
            $cleanOutputFolder = Invoke-YesNoCLIDialog -Message "Output folder is not empty. Do you want to clear it?" -YN -Vertical `
                                                -YesButtonText "&Yes, remove ouput folder content" `
                                                -NoButtonText "&No, don't clear and exit script"
            switch ($cleanOutputFolder) {
                "Yes" {
                    Write-Host "Removing content of $outputFolder"
                    $outputFolderContent | Remove-Item -Recurse
                }
                default {
                    Write-Host "Output folder must be cleared"
                    Write-Host "Please remove the content of $outputFolder"
                    Exit $EXIT_OUTPUT_FOLDER_NOT_EMPTY
                }
            }
        }
    } else {
        New-Item -Path $outputFolder -ItemType Directory | Out-Null
    }
}

function Invoke-UpgradePasswordDialog {
    Param(
        [Parameter(Mandatory)]
        [hashtable]$Variables,
        [switch]$InstallExe,
        [switch]$PS1Launcher
    )
    $bInstallExe = if ($InstallExe) {
        $true
    } elseif ($PS1Launcher) {
        $false
    } else {
        $true
    }
    $bPS1Launcher = if ($PS1Launcher) {
        $true
    } elseif ($InstallExe) {
        $false
    } else {
        $true
    }
    $aDialogRows = @(
        New-CLIDialogText -Text "If you upgrade a computer, please type the uninstall password" -AddNewLine
        New-CLIDialogTextBox -Header "Password" -PasswordChar "*" -HeaderSeparator " :  "
    )
    if ($bInstallExe) {
        if ($bPS1Launcher) {
            $aDialogRows += New-CLIDialogObjectsRow -InvisibleHeader -Row @(
                New-CLIDialogButton -Text "&Ok, integrate it in install.exe" -Keyboard O -Name "InstallEXE"
            )    
        } else {
            $aDialogRows += New-CLIDialogObjectsRow -InvisibleHeader -Row @(
                New-CLIDialogButton -Text "&Ok, integrate it in install.exe" -Validate -Keyboard O -Name "InstallEXE"
            )    
        }
    }
    if ($bPS1Launcher) {
        if ($bInstallExe) {
            $aDialogRows += New-CLIDialogObjectsRow -InvisibleHeader -Row @(
                New-CLIDialogButton -Text "&Ok, integrate it in PS1 launcher (default)" -Keyboard O -Validate -Name "PS1Launcher"
            )    
        } else {
            $aDialogRows += New-CLIDialogObjectsRow -InvisibleHeader -Row @(
                New-CLIDialogButton -Text "&Ok, integrate it in PS1 launcher" -Keyboard O -Validate -Name "PS1Launcher"
            )    
        }
    }   
    $aDialogRows += New-CLIDialogObjectsRow -InvisibleHeader -Row @(
        New-CLIDialogButton -Text "&Continue without password" -Keyboard C -Cancel -Name "None"
    )
    $oDialogResult = Invoke-CLIDialog -InputObject $aDialogRows -Execute
    if ((($oDialogResult.Type -eq "Action") -and ($oDialogResult.Action -eq "Validate")) `
        -or ($oDialogResult.Type -eq "Value")) {
        $oPassword = ($oDialogResult.DialogResult.Form.GetValue()).Password
        if ($oPassword) {
            $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($oPassword)
            $UnsecurePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
            $Variables["UpgradePassword"] = $UnsecurePassword
        }
    }
    $Variables["UpgradePasswordWhere"] = $oDialogResult.DialogResult.Button.Name
}

function Invoke-CopySourceToRepository {
    Param(
        [Parameter(Mandatory)]
        [object]$SourceFile,
        [hashtable]$Variables
    )
    $sFilePath, $oSourceFile = if ($SourceFile -is [string]) {
        $SourceFile, (Get-Item $SourceFile)
    } else {
        $SourceFile.FullName, $SourceFile
    }
    $sFileName = $oSourceFile.Name
    $sExtension = $oSourceFile.Extension.ToUpper() -replace "\.",""
    $selectedPackageName = $Variables["SelectedPackageName"]
    if (-not ($sFilePath.ToString().StartsWith($PSScriptRoot + "\input\CheckPoint_package\"))) {
        if (-not (Test-Path "$PSScriptRoot\input\CheckPoint_package\$selectedPackageName" -PathType Container)) {
            $sCopySource = Invoke-YesNoCLIDialog -Message "Do you want to copy the $sExtension in the input folder (for later use)?" -YN -Vertical `
                                                       -YesButtonText "&Yes, copy package in input folder" `
                                                       -NoButtonText "&No, don't copy for later use"
            if ($sCopySource -eq "Yes") {
                Write-Host "Copy $sFileName to repository - start"
                New-Item -ItemType Directory -Path "$PSScriptRoot\input\CheckPoint_package\$selectedPackageName" -Force | Out-Null
                Copy-Item -Path ($sFilePath) -Destination "$PSScriptRoot\input\CheckPoint_package\$selectedPackageName\$sFileName"
                Write-Host "Copy $sFileName to repository - end"
            }
        }    
    }
}

#endregion Functions

. $variables

switch ($script_mode) {
    "test" {
        $inputFolder = $PSScriptRoot + "\input\CheckPoint_package"
        $oResult = Select-CLIFileFromFolder -Path $inputFolder -Filter "*.msi", "*.exe" -AllowOtherFile -ColumnName "Check Point Package" -SeparatorColor Blue -Recurse
        $oResult.PackageType = $oResult.Value.Extension.Replace(".", "").ToUpper()
        $oResult
    }

    "main" {
        $hVariables = @{}
        $selectedCheckPointMSI = Select-CheckPointPackage
        if ($selectedCheckPointMSI.Type -eq "Value") {
            Write-Host "Selected package to customize: $($selectedCheckPointMSI.Value.FullName)"
        } else {
            Write-Host "Selected package to customize: other file ($($selectedCheckPointMSI.Value.FullName))"
        }
        $hVariables["FullName"] = $selectedCheckPointMSI.Value.FullName
        $hVariables["PackageType"] = $selectedCheckPointMSI.PackageType
        $hVariables["PackageInfo"] = $selectedCheckPointMSI

        # adding common variables for EXE and MSI management
        $hVariables["PSScriptRoot"] = $PSScriptRoot
        $hVariables["InputDir"] = Get-ScriptDir -InputDir -FullPath

        # --------------------------------------- MSI -----------------------------------------------
        if ($hVariables["PackageType"] -eq "MSI") {
            #$inputMSIFileName = Split-Path -Path $selectedCheckPointMSI -Leaf
            $inputMSIFileName = $selectedCheckPointMSI.Value.Name
            $hVariables["MSIFileName"] = $inputMSIFileName

            # Get Package info
            $hPackageInfo = Get-CheckPointMSIInfo -Path $selectedCheckPointMSI.Value.FullName
            $hVariables["SuggestedPackageName"] = $hPackageInfo["SuggestedPackageName"]
            $hVariables["PackageName"] = $hPackageInfo["PackageName"]
            $hVariables["ServerName"] = $hPackageInfo["ServerName"].ToUpper()
            $hVariables["PackageType"] = $hPackageInfo["PackageType"]

            # Choose output folder
            $selectedPackageName = $hPackageInfo.SuggestedPackageName
            $hVariables["SelectedPackageName"] = Invoke-SelectedPackageNameDialog -selectedPackageName $selectedPackageName

            # Copy in input folder
            Invoke-CopySourceToRepository -SourceFile $selectedCheckPointMSI.Value -Variables $hVariables

            # clearing output folder
            $outputFolder = "$PSScriptRoot\Sources\CheckPoint_package\$selectedPackageName\"
            $hVariables["OutputFolder"] = $outputFolder
            Invoke-ClearOrCreateOutputFolder -outputFolder $outputFolder

            # generate config.json and select site to build trac.config later
            $outputConfig = Get-InstallerConfig -PackageName $selectedPackageName
            
            # ask for password integration
            Invoke-UpgradePasswordDialog -Variables $hVariables -PS1Launcher

            # copy files to output folder
            if (Test-Path -Path "$PSScriptRoot\Install-CheckPointEndpointSecurity.ps1" -PathType Leaf) {
                if (-not (Test-Path "$outputFolder\Sources" -PathType Container)) {
                    New-Item -Path "$outputFolder\Sources" -ItemType Directory | Out-Null
                }

                Write-Host "Copy MSI"
                Copy-Item -Path $selectedCheckPointMSI.Value.FullName -Destination ("$outputFolder\Sources\" + $inputMSIFileName)

                # add trac.config
                Write-Host "Customize MSI - Add trac.config"
                $tempTracConfig = "$outputFolder\trac.config"
                $UTF8_without_BOM = New-Object System.Text.UTF8Encoding $false
                [System.IO.File]::WriteAllLines($tempTracConfig, (Convert-SiteConfigToXML $outputConfig.site), $UTF8_without_BOM)
                Open-MSIFile -Path ("$outputFolder\Sources\" + $inputMSIFileName) -GlobalVar
                Set-MSIBinary -Name "CPINSTADDEXT_Trac.config" -InputPath $tempTracConfig
                Remove-Item -Path $tempTracConfig

                # add trac.defaults
                if (($outputConfig.tracdefaults_where.ItemSelected -eq 1) -and ($outputConfig.client_configuration.trac_defaults)) {
                    Write-Host "Customize MSI - Add trac.defaults"
                    $sMSITracDefaultsFilePath = Get-MSITracDefaults -Path ("$outputFolder\Sources\" + $inputMSIFileName)
                    $oTracDefaultsConfig = $outputConfig.client_configuration.trac_defaults
                    Set-TracDefaultsConfig -tracDefaultsPath $sMSITracDefaultsFilePath -jsonConfig $oTracDefaultsConfig | Out-Null
                    $global:MSIFile.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeTransact)
                    Set-MSIBinary -Name "CPINSTADDEXT_trac.defaults" -InputPath $sMSITracDefaultsFilePath
                    $outputConfig.client_configuration = $null
                    Remove-Item $sMSITracDefaultsFilePath
                }

                # apply MSI properties
                Write-Host "Customize MSI - Apply MSI Properties"
                $MSIProperties = $outputConfig.package_customization_msi.MSI_customization
                foreach ($prop in $MSIProperties.PSObject.Properties.Name) {
                    Set-MSIProperty -Name $prop -Value $MSIProperties.$prop 
                }
                $global:MSIFile.commit()
                
                Write-Host "Copy install"
                $newPS1Script = Get-PowershellScriptWithIncludedDependancies -powershellFile "$PSScriptRoot\Install-CheckPointEndpointSecurity.ps1" -newPSScriptRootValue $PSScriptRoot
                $newPS1Script = Replace-CheckPointInstallScriptParameters -powershellScript $newPS1Script -packageName $selectedPackageName
                $UTF8_with_BOM = New-Object System.Text.UTF8Encoding $true
                [System.IO.File]::WriteAllLines("$outputFolder\Install-CheckPointEndpointSecurity.ps1", $newPS1Script, $UTF8_with_BOM)

                Write-Host "Copy config.json"
                $outputConfigJson = $outputConfig  | ConvertTo-Json -Depth 10
                [System.IO.File]::WriteAllLines("$outputFolder\config.json", $outputConfigJson, $UTF8_with_BOM)
                
                if ($outputConfig.package_customization_post_actions."post-actions") {
                    Write-Host "Running package customization post-actions"
                    foreach ($step in $outputConfig.package_customization_post_actions."post-actions") {
                        $sFunctionName = "PackageCustomization_" + $step.Action
                        if ($step.MessageBefore) {
                            PackageCustomization_Write-Host -Message $step.MessageBefore -Variables $hVariables
                        }
                        $hArguments = if ($step.Arguments) {
                            $step.Arguments | ConvertTo-Hashtable
                        } else {
                            @{}
                        }
                        $(&$sFunctionName @hArguments -Variables $hVariables)
                    }    
                }
            }
            Write-Host "Package customization end"
            $selectedCheckPointMSI = ""
        } else { 
            # --------------------------------------- EXE -----------------------------------------------
            $7zPath = (Get-ScriptDir -ToolsDir -ToolName "7-Zip" -FullPath)
            $7zExe = "$7zPath\7za.exe"
            #&$7zExe --help
            $oTempCPFolder = $env:TEMP + "\" + (Get-Date -Format "CP-yyyyMMdd_HHmmss")
            $oFolder = New-Item -ItemType Directory -Path $oTempCPFolder -Name $hVariables.PackageInfo.Value.Name -ErrorAction SilentlyContinue -Force
            $sUnpackedPackageFolder = $oFolder.FullName
            &$7zExe x -o"$($oFolder.FullName + "\\")" $hVariables.Fullname
            #Remove-Item $($env:TEMP + "\" + $hVariables.PackageInfo.Value.Name) -Recurse -ErrorAction SilentlyContinue
            
            # read SFX config file
            $sSfxConfig = Get-Content "$sUnpackedPackageFolder\sfxConfig.txt"
            $aSfxConfig = $sSfxConfig.Split("""")
            $aSfxConfig = $aSfxConfig | Where-Object { $_.Trim() -ne "" }
            $ss = Select-String -InputObject $aSfxConfig.Split("""")[-2] -Pattern ".+ msiexec.exe (?<msiargs>.+)"
            $sMSIargs = ($ss.Matches.Groups | Where-Object { $_.Name -eq "msiargs" }).Value
            $ss = Select-String -InputObject $aSfxConfig.Split("""")[-2] -Pattern "USERINSTALLMODE=(?<features>[0-9]+)"
            $iFeatures = [int](($ss.Matches.Groups | Where-Object { $_.name -eq "features" }).Value)
            $hVariables["Features"] = ConvertTo-EPSInstalledFeatures -Features $iFeatures -StringOutput -RemoveDA
            $hVariables["FeaturesArray"] = ConvertTo-EPSInstalledFeatures -Features $iFeatures
            
            # fill $hVariables hashtable
            $hVariables["UnpackedPackageFolder"] = $oFolder
            $hVariables["EPMInfo"] = Get-ManagedENSServerConfig -ConfigDat $oFolder\Config\config.dat
            $hVariables["MSIInfo"] = Get-MSIInfo -Path $oFolder\EPS.msi
            $hVariables["PackageName"] = Get-MSICheckPointVersion -MSIInfo $hVariables["MSIInfo"]
            $hVariables["PackageType"] = "SmartEndpoint"
            $hVariables["ServerName"] = $hVariables.EPMInfo.ServerName.ToUpper()
            $hVariables["SuggestedPackageName"] = ("EPS_$($hVariables["PackageName"])_" + $hVariables.EPMInfo.ServerName.ToUpper() + "_" + $hVariables["Features"])
            #$hVariables

            # generate config.json and select site to build trac.config later
            $outputConfig = Get-InstallerConfig -PackageName $hVariables["PackageName"]

            # Choose output folder
            $hVariables["SelectedPackageName"] = Invoke-SelectedPackageNameDialog -selectedPackageName $hVariables["SuggestedPackageName"]

            # Copy in input folder
            Invoke-CopySourceToRepository -SourceFile $selectedCheckPointMSI.Value -Variables $hVariables

            # Write trac.defaults file
            if ($hVariables.TracDefaultsWhere -eq "MSI") {
                Write-Host "Customize trac.defaults in unpacked folder"
                $sOriginalTracDefaultsPath = $sUnpackedPackageFolder + "\CheckPoint\Endpoint Security\Endpoint Connect\trac.defaults"
                Copy-Item $sOriginalTracDefaultsPath -Destination $env:TEMP | Out-Null
                $sTracDefaultsPath = $env:TEMP + "\trac.defaults"
                $oTracDefaultsConfig = $outputConfig.client_configuration.trac_defaults
                Set-TracDefaultsConfig -tracDefaultsPath $sTracDefaultsPath -jsonConfig $oTracDefaultsConfig | Out-Null
                $hVariables["MSIInfo"].msi.OpenDatabase([MsiOpenDatabaseMode]::msiOpenDatabaseModeTransact)
                Set-MSIBinary -Name "CPINSTADDEXT_trac.defaults" -InputPath $sTracDefaultsPath -MSIFile $hVariables["MSIInfo"].msi
                $outputConfig.client_configuration = $null
            }

            # Write trac.config file
            Write-Host "Customize trac.config in unpacked folder"
            $sTracConfigPath = $env:TEMP + "\trac.config"
            $UTF8_without_BOM = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllLines($sTracConfigPath, (Convert-SiteConfigToXML $outputConfig.site), $UTF8_without_BOM)
            Set-MSIBinary -Name "CPINSTADDEXT_Trac.config" -InputPath $sTracConfigPath -MSIFile $hVariables["MSIInfo"].msi

            # apply MSI properties
            Write-Host "Customize MSI - Apply MSI Properties"
            $MSIProperties = $outputConfig.package_customization_msi.MSI_customization
            foreach ($prop in $MSIProperties.PSObject.Properties.Name) {
                Set-MSIProperty -Name $prop -Value $MSIProperties.$prop -MSIFile $hVariables["MSIInfo"].msi
            }
            $hVariables["MSIInfo"].msi.commit()

            # clearing output folder
            Write-Host "Creating output folder"
            $outputFolder = "$PSScriptRoot\Sources\CheckPoint_package\$($hVariables["SuggestedPackageName"])"
            $hVariables["OutputFolder"] = $outputFolder
            Invoke-ClearOrCreateOutputFolder -outputFolder $outputFolder

            # cleaning useless things
            if (("AM" -notin $hVariables["FeaturesArray"]) -and (Test-Path -Path "$sUnpackedPackageFolder\AM2.Signatures" -PathType Container)) {
                $sRemoveSignatures = Invoke-YesNoCLIDialog -Message "The package does not contains antimalware but contains signature. Do you want to remove signatures?" -YN -Vertical `
                                                           -YesButtonText "&Yes, remove antimalware signatures" `
                                                           -NoButtonText "&No, keep them inside package"
                if ($sRemoveSignatures -eq "Yes") {
                    Remove-Item "$sUnpackedPackageFolder\AM2.Signatures" -Recurse
                }
            }

            if (("FDE" -notin $hVariables["FeaturesArray"]) -and (Test-Path -Path "$sUnpackedPackageFolder\lpb" -PathType Container)) {
                $sRemovelpb = Invoke-YesNoCLIDialog -Message "The package does not contains FDE but contains FDE Smart preboot. Do you want to remove FDE Smart preboot?" -YN -Vertical `
                                                           -YesButtonText "&Yes, remove FDE Smart preboot" `
                                                           -NoButtonText "&No, keep them inside package"
                if ($sRemovelpb -eq "Yes") {
                    Remove-Item "$sUnpackedPackageFolder\lpb" -Recurse
                }
            }

            # creating SFX config file - Manage password
            Invoke-UpgradePasswordDialog -Variables $hVariables -InstallExe -PS1Launcher
            
            if ($hVariables["UpgradePasswordWhere"] -eq "InstallEXE") {
                $sMSIargs += " UNINST_PASSWORD=$($hVariables["UpgradePassword"])"
            }
            # creating SFX config file - Creating file
            New-SFXConfigFile -Title "Check Point Endpoint Security" -ExecuteFile "msiexec.exe" -ExecuteParameters $sMSIargs -OutFilePath "$outputFolder\sfxConfig.txt"

            # compressing unpacked folder to output folder
            Write-Host "Creating EPS.7z"
            New-7ZipArchive -SevenZipExePath $7zExe -OutputArchivePath "$outputFolder\EPS.7z" -Content ($hVariables.UnpackedPackageFolder.FullName + "\*") -CompressionLevel 9
            Write-Host "Adding SFX items to output folder"
            Write-Host "Merging everything to install.exe"
            New-Item "$outputFolder\Sources" -ItemType Directory | Out-Null
            New-7ZipSFX -SevenZipHeaderFile "$7zPath\7zSD.sfx" `
                        -SFXConfigFile "$outputFolder\sfxConfig.txt" `
                        -ArchiveFile "$outputFolder\EPS.7z" `
                        -OutFile "$outputFolder\Sources\install.exe"

            Write-Host "Cleaning temporary 7z file and sfxConfig file"
            Remove-Item "$outputFolder\EPS.7z"
            Remove-Item "$outputFolder\sfxConfig.txt"

            # copy files (install and config.json)
            Write-Host "Copy install"
            $newPS1Script = Get-PowershellScriptWithIncludedDependancies -powershellFile "$PSScriptRoot\Install-CheckPointEndpointSecurity.ps1" -newPSScriptRootValue $PSScriptRoot
            $newPS1Script = Replace-CheckPointInstallScriptParameters -powershellScript $newPS1Script -packageName $hVariables["SuggestedPackageName"]
            $UTF8_with_BOM = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines("$outputFolder\Install-CheckPointEndpointSecurity.ps1", $newPS1Script, $UTF8_with_BOM)

            Write-Host "Copy config.json"
            $outputConfigJson = $outputConfig  | ConvertTo-Json -Depth 10
            [System.IO.File]::WriteAllLines("$outputFolder\config.json", $outputConfigJson, $UTF8_with_BOM)
            
            # Running post actions
            if ($outputConfig.package_customization_post_actions."post-actions") {
                Write-Host "Running package customization post-actions"
                foreach ($step in $outputConfig.package_customization_post_actions."post-actions") {
                    $sFunctionName = "PackageCustomization_" + $step.Action
                    if ($step.MessageBefore) {
                        PackageCustomization_Write-Host -Message $step.MessageBefore -Variables $hVariables
                    }
                    $hArguments = if ($step.Arguments) {
                        $step.Arguments | ConvertTo-Hashtable
                    } else {
                        @{}
                    }
                    $(&$sFunctionName @hArguments -Variables $hVariables)
                }    
            }

            # opening windows file explorer at generation end
            try {
                Invoke-WindowsFileExplorer $outputFolder
            } catch {
                Write-Host "There is a bug in Windows explorer that prevent opening from command line a path that contains commas" -ForegroundColor Yellow
                Write-Host "Package has been generated here:"
                Write-Host $outputFolder
            }
        }
    }
}
