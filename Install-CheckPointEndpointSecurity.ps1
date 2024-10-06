#requires -version 5.0
#requires -RunAsAdministrator

#region Script Parameters
Param(
    [ValidateSet("EN", "FR", "JP", "ES", "IT", "DE", "PT", "RU", "CS", "EL", "PL", "")]
    [AllowEmptyString()]
    [string]$language,
    [string]$uninstPasswd = "",
    [string]$packageToInstall = "E86.60_WW"
)
#endregion Script Parameters

#region Variables
$Variables={
    $EXIT_OK = 0
    $EXIT_APP_NOT_INSTALLED = 1
    $EXIT_TRAC_DEFAULTS_NOT_FOUND = 2
    $EXIT_VPN_CONNECT_SCRIPT_COPY_FAILED = 3
    $EXIT_OPTION_NOT_FOUND = 0

    $script_mode = "main"
}
#endregion Variables

#region Include
. $PSScriptRoot\UDF\CheckPoint\Endpoint\class-tracDefaultsSetting.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\class-tracDefaultsSettings.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Get-CheckPointFile.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Get-CheckPointRegKey.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Get-CheckPointProduct.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Get-CheckPointTracExe.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Install-NewCheckPointVPN.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Set-EndpointLogLevel.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Set-EndpointSDL.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Set-TracDefaultsConfig.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Start-CheckPointService.ps1
. $PSScriptRoot\UDF\CheckPoint\Endpoint\Stop-CheckPointService.ps1
. $PSScriptRoot\UDF\Hashtable\ConvertTo-Hashtable.ps1
. $PSScriptRoot\UDF\Log\enum_LogLevel.ps1
. $PSScriptRoot\UDF\Log\Set-LogInfo.ps1
. $PSScriptRoot\UDF\Log\Write-LogInfo.ps1
. $PSScriptRoot\UDF\Path\Resolve-PathWithVariables.ps1
. $PSScriptRoot\UDF\Programs\Get-ApplicationUninstallRegKey.ps1
. $PSScriptRoot\UDF\Programs\Test-Installed.ps1
. $PSScriptRoot\UDF\Programs\Test-MSISuccess.ps1
. $PSScriptRoot\UDF\Programs\Test-InstallationSuccessTag.ps1
. $PSScriptRoot\UDF\Programs\Set-InstallationTag.ps1
. $PSScriptRoot\UDF\Script\Get-ScriptLogFileName.ps1
. $PSScriptRoot\UDF\Script\Get-ScriptLogFile.ps1
. $PSScriptRoot\UDF\Script\Get-RootScriptConfigFile.ps1
. $PSScriptRoot\UDF\Script\Get-RootScriptName.ps1
. $PSScriptRoot\UDF\Script\Get-RootScriptPath.ps1
. $PSScriptRoot\UDF\Services\Wait-ServiceStatus.ps1
. $PSScriptRoot\UDF\System\Test-IsAdmin.ps1
#endregion Include

#region Functions
function Get-SourceFile {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$FileName
    )
    foreach ($item in $FileName) {
        $sResult = if (Test-Path -Path "$PSScriptRoot\Sources\$item" -PathType Leaf) {
            "$PSScriptRoot\Sources\$item"
        } else {
            "$PSScriptRoot\Sources\CheckPoint_Packages\$packageToInstall\$item"
        }
        return Get-Item $sResult
    }
    return $null
}

function PackageInstall_Write-LogInfo {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Message,
        [hashtable]$Variables
    )
    Write-LogInfo -Object $Message
}

function PackageInstall_Copy-Item {
    Param(
        [Parameter(Mandatory)]
        [string]$Source,
        [string]$OtherSource,
        [Parameter(Mandatory)]
        [string]$Destination,
        [hashtable]$Variables,
        [string]$MessageCopySuccess,
        [string]$MessageCopyError,
        [string]$MessageSourceNotFound
    )
    Begin {
        $sSource = Resolve-PathWithVariables -Path $Source -Hashtable $Variables
        $sRealSource = if (Test-Path -Path $sSource -PathType Leaf) {
            $sSource
        } else {
            if ($OtherSource) {
                $sOtherSource = Resolve-PathWithVariables -Path $OtherSource -Hashtable $Variables
                if (Test-Path -Path $sOtherSource -PathType Leaf) {
                    $sOtherSource
                } else {
                    Write-LogInfo $MessageSourceNotFound
                throw [System.IO.FileNotFoundException] $MessageSourceNotFound
                }
            } else {
                Write-LogInfo $MessageSourceNotFound
                throw [System.IO.FileNotFoundException] $MessageSourceNotFound
            }
        }
        $sDestination = Resolve-PathWithVariables -Path $Destination -Hashtable $Variables
    }
    
    Process {
        try {
            Copy-Item -Path $sRealSource -Destination $sDestination -Force
            Write-LogInfo $MessageCopySuccess
        } catch {
            Write-LogError $MessageCopyError -Exception $_
            if ($config.installer_config.tag.dotag) {
                Set-InstallationTag -ApplicationName $scriptName `
                    -ScriptReturn $EXIT_VPN_CONNECT_SCRIPT_COPY_FAILED `
                    -Manufactured $config.installer_config.tag.Manufactured `
                    -PackageVersion $config.installer_config.tag.PackageVersion `
                    -ProductVersion $packageToInstall `
                    -Status "KO" `
                    -RegFolder $config.installer_config.tag.RegFolder
                Write-LogInfo "Set Installation Tag: KO"
            }
            Exit $EXIT_VPN_CONNECT_SCRIPT_COPY_FAILED
        }    
    }
}

function PackageInstall_Wait-TracSrvWrapperServiceRunning {
    Param(
        [int]$Timeout,
        [hashtable]$Variables
    )
    $waitValue = Wait-ServiceStatus -Name "TracSrvWrapper" -Status "Running" -Timeout $Timeout
    if (-not $waitValue.Success) {
        Write-LogInfo "Service wait failed"
        Write-LogInfo "Starting service"
        Start-Service -Name "TracSrvWrapper"
        $waitValue = Wait-ServiceStatus -Name "TracSrvWrapper" -Status "Running" -Timeout $Timeout
    }
    Write-LogInfo $("Service wait success: " + $waitValue.Success)
}

function PackageInstall_Set-EndpointSDLState {
    Param(
        [Parameter(Mandatory)]
        [ValidateSet("disabled", "enabled")]
        [string]$Value,
        [hashtable]$Variables
    )
    Set-EndpointSDL -tracexe $tracexe $Value
}

function PackageInstall_Set-EndpointLogLevel {
    Param(
        [Parameter(Mandatory)]
        [ValidateSet("disabled", "basic", "extended")]
        [string]$Value,
        [hashtable]$Variables
    )
    Set-EndpointLogLevel -tracexe $tracexe $Value
}

function PackageInstall_Add-CertificateFingerprint {
    Param(
        [Parameter(Mandatory)]
        [string]$AcceptedCN,
        [Parameter(Mandatory)]
        [string]$Fingerprint,
        [hashtable]$Variables
    )
    New-Item -Path "HKLM:\SOFTWARE\WOW6432Node\CheckPoint\accepted_cn\$AcceptedCN" -ItemType Directory -Force | Out-Null
    New-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\CheckPoint\accepted_cn\$AcceptedCN" -Name "--Fingerprint--" -Value $Fingerprint -Force | Out-Null
}

function PackageInstall_Update-TracDefaults {
    Param(
        [hashtable]$Variables
    )
    $oTracDefaultsConfig = $config.client_configuration.trac_defaults
    if ($oTracDefaultsConfig) {
        Stop-Service -Name "TracSrvWrapper"
        $waitValue = Wait-ServiceStatus -Name "TracSrvWrapper" -Status "Stopped" -Timeout 60000
        $sTracDefaultsFile = Get-CheckPointFile "trac.defaults" 
        Set-TracDefaultsConfig -tracDefaultsPath $sTracDefaultsFile -jsonConfig $oTracDefaultsConfig | Out-Null
        Start-Service -Name "TracSrvWrapper"        
    }
}

function PackageInstall_Start-TracSrvWrapperService {
    Param(
        [hashtable]$Variables
    )
    Start-Service -Name "TracSrvWrapper"
}

function PackageInstall_Write-ProductToHost {
    Param(
        [hashtable]$Variables
    )
    switch ($Variables["Product"]) {
        "Check Point VPN" {
            PackageInstall_Write-LogInfo -Message "Installed product: Check Point VPN" -Variables $hVariables
        }
        "Check Point Endpoint Security" {
            PackageInstall_Write-LogInfo -Message "Installed product: Check Point Endpoint Security" -Variables $hVariables
        }
        "" {
            PackageInstall_Write-LogInfo -Message "Installed product: None" -Variables $hVariables
        }
        default {
            PackageInstall_Write-LogInfo -Message "Unknown product" -Variables $hVariables
            Exit
        }
    }
}

function PackageInstall_Stop-EndpointSecurity {
    Param(
        [hashtable]$Variables
    )
    PackageInstall_Write-LogInfo -Message "Stopping $($Variables["Product"])" -Variables $hVariables
    Stop-CheckPointService -tracexe $tracexe
}

function PackageInstall_Invoke-ExternalCommand {
    Param(
        [Parameter(Mandatory)]
        [string]$Command,
        [string[]]$Arguments,
        [hashtable]$Variables
    )
    $sCommand = Resolve-PathWithVariables -Path $Command -Hashtable $Variables
	if ($Arguments) {
		Start-Process -FilePath $sCommand -ArgumentList $Arguments -Wait
	} else {
		Start-Process -FilePath $sCommand -Wait
	}
}

function Invoke-RunSteps {
    Param(
        [object]$steps,
		[hashtable]$Variables
    )
    if ($steps) {
        foreach ($step in $steps) {
            $bCondition = if ($step.Condition) { Invoke-Expression $step.Condition } else { $true }
            if ($bCondition) {
                $sFunctionName = "PackageInstall_" + $step.Action
                if ($step.MessageBefore) {
                    PackageInstall_Write-LogInfo -Message $step.MessageBefore -Variables $Variables
                }
                $hArguments = if ($step.Arguments) {
                    $step.Arguments | ConvertTo-Hashtable
                } else {
                    @{}
                }
                $(&$sFunctionName @hArguments -Variables $Variables)
            }
        }
    }
}
#endregion Functions

. $Variables
$reg = Get-CheckPointRegKey
if ($null -eq $reg) {
    $product = ""
} else {
    $product = Get-CheckPointProduct -regkey $reg
    $tracexe = Get-CheckPointTracExe
}

$configFile = Get-RootScriptConfigFile 
if ($config -eq "") {
    throw [System.IO.FileNotFoundException] "Config file not found"
}
$config = Get-Content -Path $configFile | ConvertFrom-Json

Set-LogInfo -Config $config.install_general_config.Log

if ($script_mode -eq "test") {
    $logfile
    #Wait-ServiceStatus -Name "TracSrvWrapper" -Status "Running" 
} else {
    $hVariables = @{}
    $logfile = $Global:LogInfo.LogFile 
    #$logfile = Get-ScriptLogFile -log_folder $config.install.log.folder -fallback_folder $config.install.log.fallback_folder
    Write-Host $("Log file: " + $logfile)
    $scriptName = Get-RootScriptName
    $hVariables["LogFile"] = $logfile
    $hVariables["PSScriptRoot"] = $PSScriptRoot
    $hVariables["ScriptName"] = $scriptName
    $hVariables["Product"] = $product

    if ((-not $config.install_general_config.tag.ignoretag) -and (Test-InstallationSuccessTag -ApplicationName $scriptName -ProductVersion $packageToInstall -RegFolder $config.install_general_config.tag.RegFolder)) {
        Write-LogInfo "Package $packageToInstall already installed"
    } else {
        if (Test-IsAdmin) {
            # Run steps before
            Invoke-RunSteps -steps $config.install_steps_before -Variables $hVariables
            
            # Run Installation
            Write-LogInfo "Installing Check Point Endpoint Security"
            $msipath = Get-SourceFile -FileName "EPS.msi", "install.exe"
            if ($msipath) {
                $msiProcess = Install-NewCheckPointVPN -msipath $msipath -language $language -uninstPasswd $uninstPasswd
                $msiExitCode = $msiProcess.ExitCode
            } else {
                Write-Error "Setup file not found"
                Exit
            }
            
            if (Test-MSISuccess $msiExitCode) {
                Write-LogInfo "Installation succeeded with return code $msiExitCode"
                $reg = Get-CheckPointRegKey
                $tracexe = Get-CheckPointTracExe -regkey $reg

                # Run steps after
                Write-LogInfo "Running steps configured in config.json"
                Invoke-RunSteps -steps $config.install_steps_after -Variables $hVariables

                # Apply Installation tag
                if ($config.install.tag.dotag) {
                    Set-InstallationTag -ApplicationName $scriptName `
                        -ScriptReturn $msiExitCode `
                        -Manufactured $config.install_general_config.tag.Manufactured `
                        -PackageVersion $config.install_general_config.tag.PackageVersion `
                        -ProductVersion $packageToInstall `
                        -Status "OK" `
                        -RegFolder $config.install_general_config.tag.RegFolder
                    Write-LogInfo "Set Installation Tag: OK"
                }
                # Install script end
                Write-LogInfo "Install script end"
                Exit $msiExitCode
            } else {
                Write-LogInfo "Installation failed with return code $msiExitCode"
                if ($config.install_general_config.tag.dotag) {
                    Set-InstallationTag -ApplicationName $scriptName `
                        -ScriptReturn $msiExitCode `
                        -Manufactured $config.install_general_config.tag.Manufactured `
                        -PackageVersion $config.install_general_config.tag.PackageVersion `
                        -ProductVersion $packageToInstall `
                        -Status "KO" `
                        -RegFolder $config.install_general_config.tag.RegFolder
                    Write-LogInfo "Set Installation Tag: KO"
                }
                Exit $msiExitCode
            }
        }    
    }
}



