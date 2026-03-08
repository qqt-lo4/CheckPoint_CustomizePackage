#requires -version 5.0
#requires -RunAsAdministrator

#region Script Parameters
    Param(
		[ValidateSet("EN", "FR", "JP", "ES", "IT", "DE", "PT", "RU", "CS", "EL", "PL", "")]
        [AllowEmptyString()]
        [string]$language,
        [string]$uninstPasswd = "",
        [string]$packageToInstall = "EPS_E89.10_ASFWSTAGO_FW1-COMP-PC-EC"
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
class tracDefaultsSetting {
    [string]$name
    [string]$type
    [string]$value
    [string]$beforelastvalue
    [string]$lastvalue
    [string]$space1
    [string]$space2
    [string]$space3
    [string]$space4
    [string]$space5

    tracDefaultsSetting([string]$name, [string]$type, [string]$value, [string]$beforelastvalue, [string]$lastvalue, `
                        [string]$space1, [string]$space2, [string]$space3, [string]$space4, [string]$space5) {
        $this.name = $name
        $this.type = $type
        $this.value = $value
        $this.beforelastvalue = $beforelastvalue
        $this.lastvalue = $lastvalue
        $this.space1 = $space1
        $this.space2 = $space2
        $this.space3 = $space3
        $this.space4 = $space4
        $this.space5 = $space5
    }

    [string]ToString() {
        if ((-not ($this.value.StartsWith("`""))) -and (($this.value -eq "") -or ($this.value.Contains(" ")))) {
            $_value = "`"" + $this.value + "`""
        } else {
            $_value = $this.value
        }
        return $this.name + $this.space1 `
             + $this.type + $this.space2 `
             + $_value + $this.space3 `
             + $this.beforelastvalue + $this.space4 `
             + $this.lastvalue + $this.space5
    }

    static [tracDefaultsSetting] newFromLine([string]$line) {
        if ($line -match "^([^ \t]+)((\t| )+)([^ \t]+)((\t| )+)([^\t]+)((\t| )+)([^ \t]+)((\t| )+)([^ \t]+)((\t| )*)$") {
            return New-Object tracDefaultsSetting($Matches.1, $Matches.4, $Matches.7, $Matches.10, $Matches.13, `
                                                  $Matches.2, $Matches.5, $Matches.8, $Matches.11, $Matches.14)
        } else {
            return $null
        }
    }
}

class tracDefaultsSettings {
    [hashtable]$options
    [System.Collections.ArrayList]$optionsorder
    hidden [string]$tracDefaultsPath

    tracDefaultsSettings([string]$tracDefaultsPath) {
        if (($null -eq $tracDefaultsPath) `
            -or ($tracDefaultsPath -eq "") `
            -or (-not (Test-Path -Path $tracDefaultsPath))) {
            throw [System.IO.FileNotFoundException] "Trac.defaults file does not exists"
        }
        $this.tracDefaultsPath = $tracDefaultsPath
        $this.options = @{}
        $this.optionsorder = New-Object System.Collections.ArrayList
        Get-Content -Path $tracDefaultsPath | ForEach-Object {
                                                  if ($_.Trim() -ne "") {
                                                      $setting = [tracDefaultsSetting]::newFromLine($_)
                                                      $this.options.Add($setting.name, $setting)
                                                      $this.optionsorder.Add($setting.name)
                                                  }
                                              }
    }

    [boolean]HasOption([string]$optionname) {
        return $this.options.ContainsKey($optionname)
    }

    [boolean]SetOptionValue([string]$optionname, [string]$value) {
        if ($this.HasOption($optionname)) {
            $this.options[$optionname].value = $value
            return $true
        } else {
            return $false
        }
    }

    [string]GetOptionValue([string]$optionname) {
        if ($this.HasOption($optionname)) {
            return $this.options[$optionname].value
        } else {
            return $null
        }
    }

    [string]ToString() {
        $result = ""
        for ($i=0; $i -lt $this.optionsorder.Count; $i++) {
            [tracDefaultsSetting]$setting = $this.options[$this.optionsorder[$i]] 
            $result += $setting.ToString() 
            if ($i -lt $this.optionsorder.Count - 1) {
                $result += "`n"
            }
        }
        return $result
    }

    [string]Backup() {
        $folder = Split-Path -Path $this.tracDefaultsPath -Parent
        $filename = Split-Path -Path $this.tracDefaultsPath -Leaf
        $newfile = $folder + "\" + $filename.Replace(".", "_") + ".backup_" + $(Get-Date -Format "yyyyMMdd_HHmmss")

        Copy-Item -Path $this.tracDefaultsPath -Destination $newfile
        if (Test-Path -Path $newfile) {
            return $newfile
        } else {
            return ""
        }
    }

    [void]Save() {
        $result = $this.ToString()
        $this.Backup()
        [IO.File]::WriteAllText($this.tracDefaultsPath, $result)
    }
}

function Get-CheckPointFile {
    Param(
        [Parameter(Mandatory, Position = 0, ParameterSetName = "regkey")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "applicationname")]
        [Parameter(Mandatory, Position = 0, ParameterSetName = "noinfo")]
        [ValidateNotNullOrEmpty()]
        [string]$filename,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "regkey")]
        [Microsoft.Win32.RegistryKey]$regkey,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "applicationname")]
        [string]$applicationname
    )
    switch ($PSCmdlet.ParameterSetName) {
        "regkey" {
            $application = Get-CheckPointProduct -regkey $regkey
        }
        "applicationname" {
            $application = $applicationname
        }
        "noinfo" {
            $regkey = $(Get-CheckPointRegKey)
            $application = Get-CheckPointProduct -regkey $regkey
        }
    }
    $path = switch($application) {
        "Check Point VPN"   { 
                                if ([System.Environment]::Is64BitOperatingSystem) {
                                    "C:\Program Files (x86)\CheckPoint\Endpoint Connect\$filename"
                                } else {
                                    "C:\Program Files\CheckPoint\Endpoint Connect\$filename"
                                }
                            }
        "Check Point Endpoint Security"
                            { 
                                if ([System.Environment]::Is64BitOperatingSystem) {
                                    "C:\Program Files (x86)\CheckPoint\Endpoint Security\Endpoint Connect\$filename"
                                } else {
                                    "C:\Program Files\CheckPoint\Endpoint Security\Endpoint Connect\$filename"
                                }
                            }
        default { "" }
    }
    if (($path -ne "") -and (Test-Path -Path $path)) {
        return $path
    } else {
        return ""
    }
}

function Get-CheckPointRegKey {
    [OutputType([Microsoft.Win32.RegistryKey[]])]
    Param()
    return Get-ApplicationUninstallRegKey -valueName "DisplayName" -valueData @("Check Point VPN", "Check Point Endpoint Security")
}

function Get-CheckPointProduct {
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    if ($regkey -and ($regkey -isnot [array])) {
        $regkey.GetValue("DisplayName")
    } else {
        return ""
    }
}

function Get-CheckPointTracExe {
    Param(
        [Microsoft.Win32.RegistryKey]$regkey = $(Get-CheckPointRegKey)
    )
    return $(Get-CheckPointFile -regkey $regkey -filename "trac.exe")
}

function Install-NewCheckPointVPN {
    Param(
        [Parameter(Mandatory)]
        [Alias("SetupFile")]
        [object]$msipath,
        [ValidateSet("EN", "FR", "JP", "ES", "IT", "DE", "PT", "RU", "CS", "EL", "PL", "")]
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$language,
        [AllowEmptyString()]
        [string]$uninstPasswd,
        [AllowEmptyString()]
        [string]$SDL_ENABLED,
        [AllowEmptyString()]
        [string]$FIXED_MAC
    )
    $oSetupFile =  if ($msipath -is [System.IO.FileInfo]) {
        $msipath
    } else {
        Get-Item $msipath
    }
    $oSetupType = $oSetupFile.Extension.ToUpper() -replace "\.", ""
    $arguments = @()
    if ($oSetupType -eq "EXE") {
        $command = $oSetupFile
    } else {
        $sFilePath = $oSetupFile.FullName
        $command = [System.Environment]::SystemDirectory + "\msiexec.exe"
        $arguments += "/i"
        $arguments += "`"$sFilePath`""
        $arguments += "/quiet"
        
    }
    $arguments += "/norestart"
    if ($uninstPasswd) {
        $arguments += $("UNINST_PASSWORD=" + $uninstPasswd)
    }
    if ($SDL_ENABLED -and ($SDL_ENABLED -ne "")) {
        $arguments += "SDL_ENABLED=$SDL_ENABLED"
    }
    if ($FIXED_MAC -and ($FIXED_MAC -ne "")) {
        $arguments += "FIXED_MAC=$FIXED_MAC"
    }
    if ($language -ne "") {
        $languageHashtable = @{
            EN = 1033
            FR = 1036
            ES = 1034
            JP = 1041
            DE = 1031
            IT = 1040
            EL = 1032
            PL = 1045
            RU = 1049
            PT = 2070
            CS = 1029
        }
        $languageParameter = if ($language -eq "") { "" } else { $languageHashtable[$language] }
        $arguments += $("LCID=" + $languageParameter)
    }
    Start-Process -FilePath $command -ArgumentList $arguments -PassThru -Wait -NoNewWindow    
}

function Set-EndpointLogLevel {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),
        [ValidateSet("disabled", "basic", "extended")]
        [string]$loglevel = "extended"
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        if ($loglevel -eq "disabled") {
            $(& $tracexe "disable_log")
        } else {
            $(& $tracexe "enable_log" "-m" $loglevel)
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}

function Set-EndpointSDL {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe),
        [ValidateSet("disabled", "enaled")]
        [string]$loglevel
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        if ($loglevel -eq "disabled") {
            $(& $tracexe "sdl" "-st" "disable")
        } else {
            $(& $tracexe "sdl" "-st" "enable")
        }
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}

function Set-TracDefaultsConfig {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$tracDefaultsPath,
        [Parameter(Mandatory, Position = 1)]
        [PSObject]$jsonConfig
    )
    $resultSuccess = $true
    $oTracDefaultsSettings = [tracDefaultsSettings]::new($tracDefaultsPath)
    foreach ($item in $jsonConfig.PSObject.Properties) {
        $resultSuccess = $resultSuccess -and $oTracDefaultsSettings.SetOptionValue($item.Name, $item.value)
    }
    if (-not $resultSuccess) {
        throw [System.ArgumentException] "Some options can't be applied. The file might be bad."
    }
    $oTracDefaultsSettings.Save()
    return $oTracDefaultsSettings
}

function Start-CheckPointService {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $(& $tracexe "start")
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}

function Stop-CheckPointService {
    Param(
        [string]$tracexe = $(Get-CheckPointTracExe)
    )
    if (Test-Path -Path $tracexe -PathType Leaf) {
        $(& $tracexe "stop")
    } else {
        throw [System.IO.FileNotFoundException] "trac.exe file does not exists"
    }
}

# function ConvertTo-Hashtable {
#     [CmdletBinding()]
#     param (
#         [Parameter(ValueFromPipeline)]
#         $InputObject
#     )

#     process {
#         ## Return null if the input is null. This can happen when calling the function
#         ## recursively and a property is null
#         if ($null -eq $InputObject) {
#             return $null
#         }

#         ## Check if the input is an array or collection. If so, we also need to convert
#         ## those types into hash tables as well. This function will convert all child
#         ## objects into hash tables (if applicable)
#         if ($InputObject -is [hashtable]) {
#             $InputObject
#         } elseif (($InputObject -is [System.Collections.IEnumerable]) -and ($InputObject -isnot [string])) {
#             $collection = @(
#                 foreach ($object in $InputObject) {
#                     ConvertTo-Hashtable -InputObject $object
#                 }
#             )
#             ## Return the array but don't enumerate it because the object may be pretty complex
#             Write-Output -NoEnumerate $collection
#         } elseif ($null -ne ($InputObject.GetType().ImplementedInterfaces.FullName | Where-Object { $_ -like "Microsoft.Graph.PowerShell.Runtime.IAssociativeArray*" })) {
#             ## Convert it to its own hash table and return it
#             $hash = [ordered]@{}
#             $aProperties = $InputObject.PSObject.Properties | Where-Object { $_.Name -ne "AdditionalProperties" }
#             foreach ($property in $aProperties) {
#                 $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
#             }
#             $hash
#         } elseif ($InputObject -is [psobject]) { ## If the object has properties that need enumeration
#             ## Convert it to its own hash table and return it
#             $hash = [ordered]@{}
#             foreach ($property in $InputObject.PSObject.Properties) {
#                 $hash.Add($property.Name, (ConvertTo-Hashtable -InputObject $property.Value))
#             }
#             $hash
#         } else {
#             ## If the object isn't an array, collection, or other object, it's already a hash table
#             ## So just return it.
#             $InputObject
#         }
#     }
# }

function ConvertTo-Hashtable {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )
    process {
        ## Return null if the input is null
        if ($null -eq $InputObject) {
            return $null
        }
        
        ## If already a hashtable, return it
        if ($InputObject -is [hashtable]) {
            return $InputObject
        }
        
        ## Check if the input is an array or collection
        if (($InputObject -is [System.Collections.IEnumerable]) -and ($InputObject -isnot [string])) {
            $collection = @(
                foreach ($object in $InputObject) {
                    ConvertTo-Hashtable -InputObject $object
                }
            )
            ## Return the array but don't enumerate it
            Write-Output -NoEnumerate $collection
        }
        ## Check for Microsoft Graph specific types
        elseif ($null -ne ($InputObject.GetType().ImplementedInterfaces.FullName | Where-Object { $_ -like "Microsoft.Graph.PowerShell.Runtime.IAssociativeArray*" })) {
            $hash = [ordered]@{}
            $aProperties = $InputObject.PSObject.Properties | Where-Object { $_.Name -ne "AdditionalProperties" }
            foreach ($property in $aProperties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            return $hash
        }
        ## If the object has properties (PSObject/PSCustomObject)
        elseif ($InputObject -is [psobject]) {
            $hash = [ordered]@{}
            foreach ($property in $InputObject.PSObject.Properties) {
                $hash[$property.Name] = ConvertTo-Hashtable -InputObject $property.Value
            }
            return $hash
        }
        ## Otherwise return as-is
        else {
            return $InputObject
        }
    }
}

enum LogLevel {
    Error = 1
    Warning = 2
    Info = 3
    Host = 3
    Verbose = 4
    Debug = 5
}

function Set-LogInfo {
    [cmdletbinding()]
    <#
    .Description
    Set log informations used by Write-Log* functions
    .Version 1.0
    First version
    .Version 1.1
    Added another parameter set named "Config"
    Added management for fallback folder
    Added path resolution to remove environement variables
    #>
    Param(
        [Parameter(ParameterSetName = "config")]
        [object]$Config,
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$LogFolder,
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$FallbackLogFolder,
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$LogFileName = (Get-ScriptLogFileName),
        [Parameter(ParameterSetName = "DirectValues")]
        [int]$LogRotateCount = -1,
        [Parameter(ParameterSetName = "DirectValues")]
        [int64]$LogSize = 10MB,
        [Parameter(ParameterSetName = "DirectValues")]
        [LogLevel]$LogLevel = ([LogLevel]::Info),
        [Parameter(ParameterSetName = "DirectValues")]
        [string]$DateFormat = "yyyy-MM-dd HH:mm:ss",
        [Parameter(ParameterSetName = "DirectValues")]
        [System.EnvironmentVariableTarget]$EnvironmentVariableTarget = "Machine"
    )
    # build environment variables target
    $sEnvironmentVariableTarget = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.EnvVarTarget) {
            $Config.EnvVarTarget
        } else {
            "Machine"
        }
    } else {
        [System.EnvironmentVariableTarget]::$EnvironmentVariableTarget
    }
    # build log folder output
    $sLogFolder = if ($PSCmdlet.ParameterSetName -eq "config") {$Config.Folder} else {$LogFolder}
    if ((-not $sLogFolder) -or ($sLogFolder -eq "")) {
        throw "Folder to store log is empty!"
    }
    $sLogFolder = Resolve-PathWithVariables -Path $sLogFolder -EnvironmentVariableTarget $sEnvironmentVariableTarget
    $sFallbackLogFolder = if ($PSCmdlet.ParameterSetName -eq "config") {$Config.FallbackFolder} else {$FallbackLogFolder}
    if (($sFallbackLogFolder) -and ($sFallbackLogFolder -ne "")) {
        $sFallbackLogFolder = Resolve-PathWithVariables -Path $sFallbackLogFolder -EnvironmentVariableTarget $sEnvironmentVariableTarget
    }
    $sLogFolder = if (Test-Path -Path $sLogFolder -PathType Container) {
        $sLogFolder
    } else {
        if (($sFallbackLogFolder) -and (Test-Path -Path $sFallbackLogFolder -PathType Container)) {
            $sFallbackLogFolder
        } else {
            throw [System.IO.DirectoryNotFoundException] "Both log folders does not exist"
        }
    }
    # build log file name output
    $sLogFileName = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.FileName) {
            $Config.FileName
        } else {
            (Get-ScriptLogFileName)
        }
    } else {
        $LogFileName
    }
    $sLogFileName = Resolve-PathWithVariables -Path $sLogFileName -EnvironmentVariableTarget $sEnvironmentVariableTarget
    # build logrotate variable
    $iLogRotate = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.RotateCount) {$Config.RotateCount} else { -1 }
    } else {
        $LogRotateCount
    }
    # build log size
    $iLogSize = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.Size) {
            if ($Config.Size -is [int]) {
                $Config.Size
            } elseif ($Config.Size -is [string]) {
                Convert-SizeToInt -Size $Config.Size
            } else {
                throw "Bad size format"
            }    
        } else {
            -1
        }
    } else {
        $LogSize
    }
    # build log level variable
    $eLogLevel = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.LogLevel) {
            if ($Config.LogLevel -in [Enum]::GetNames("LogLevel")) {
                [LogLevel]::($Config.LogLevel)
            } else {
                throw [System.ArgumentOutOfRangeException] "Provided log level is not correct"
            }
        } else {
            ([LogLevel]::Info)
        }
    } else {
        $LogLevel
    }
    # build dateformat variable
    $sDateFormat = if ($PSCmdlet.ParameterSetName -eq "config") {
        if ($Config.DateFormat) {
            $Config.DateFormat
        } else {
            "yyyy-MM-dd HH:mm:ss"
        }
    } else {
        $DateFormat
    }
    # build result variable
    $result = @{
        GlobalLogLevel = $eLogLevel
        LogDateFormat = $sDateFormat
        LogFolder = $sLogFolder
        LogFileName = $sLogFileName
        LogFile = ($sLogFolder + "\" + $sLogFileName)
        DoFileRotate = ($iLogRotate -ne -1)
        LogRotateCount = ($iLogRotate)
        LogSize = $iLogSize
        DoWriteToFile = (($null -ne $LogFileName) -and ($LogFileName -ne ""))
    }
    $result = New-Object -TypeName psobject -Property $result
    Add-Member -InputObject $result -MemberType ScriptMethod -Name "DoWriteLogLevel" -Value {
        $InvocationName = $args[0]
        $eCurrentLogLevel = if ($InvocationName -match "^Write-Log([a-zA-Z]+)$") {
            [LogLevel]::($Matches.1)
        } else {
            throw "Not possible exception"
        }
        return ($eCurrentLogLevel.Value__ -le $this.GlobalLogLevel.Value__)
    }
    $Global:LogInfo = $result
}

function Write-LogItem {
    Param(
        [string]$InvocationName,
        [object]$MessageData 
    )
    $oLogInfo = $Global:LogInfo
    $eCurrentLogLevel = if ($InvocationName -match "^Write-Log([a-zA-Z]+)$") {
        [LogLevel]::($Matches.1)
    } else {
        throw "Not possible exception"
    }
    $sLogItem = $(Get-Date -Format $oLogInfo.LogDateFormat) + " " + $eCurrentLogLevel
    $sMsg = [string]$MessageData
    if ($sMsg.Contains("`n")) {
        $sLogItem += " :`n" + $sMsg
    } else {
        $sLogItem += " - " + $sMsg
    }
    if ($oLogInfo.DoFileRotate) {
        Invoke-FileRotate -filepath $oLogInfo.LogFile -count $oLogInfo.LogRotateCount -size $oLogInfo.LogSize
    }
    $sLogItem | Out-File -Append $oLogInfo.LogFile
}

function Write-LogError {
    [CmdletBinding(DefaultParameterSetName="NoException")]
    Param(
        [Parameter(ParameterSetName = "WithException")]
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = "NoException", Position = 0)]
        [AllowNull()][AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message,

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        [System.Management.Automation.ErrorCategory]$Category,

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        [string]$ErrorId,

        [Parameter(ParameterSetName = "NoException")]
        [Parameter(ParameterSetName = "WithException")]
        [Object]$TargetObject,

        [string]$RecommendedAction,

        [Alias("Activity")]
        [string]$CategoryActivity,

        [Alias("Reason")]
        [string]$CategoryReason,

        [Alias("TargetName")]
        [string]$CategoryTargetName,

        [Alias("TargetType")]
        [string]$CategoryTargetType,

        [Parameter(Mandatory, ParameterSetName = "WithException")]
        [System.Exception]$Exception,

        [Parameter(Mandatory, ParameterSetName = "ErrorRecord")]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    Begin {
        $oLogInfo = $Global:LogInfo        
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                switch ($PSCmdlet.ParameterSetName) {
                    "ErrorRecord" {
                        Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $ErrorRecord
                    }
                    "WithException" {
                        Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Exception
                    }
                    "NoException" {
                        Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
                    }
                }
            }
            Microsoft.PowerShell.Utility\Write-Error @PSBoundParameters
        }
    }
}

function Write-LogVerbose {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message
    )
    Begin {
        $oLogInfo = $Global:LogInfo
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
            }
            Microsoft.PowerShell.Utility\Write-Verbose @PSBoundParameters
        }
    }
}

function Write-LogWarning {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message
    )
    Begin {
        $oLogInfo = $Global:LogInfo        
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
            }
            Microsoft.PowerShell.Utility\Write-Warning @PSBoundParameters
        }
    }
}

function Write-LogDebug {
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [Alias("Msg")]
        [string]$Message
    )
    Begin {
        $oLogInfo = $Global:LogInfo        
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Message
            }
            Microsoft.PowerShell.Utility\Write-Debug @PSBoundParameters
        }
    }
}

function Write-LogInfo {
    [CmdLetBinding()]
    Param(
        [Parameter(ValueFromPipeline, ValueFromRemainingArguments, Position = 0)]
        [Object]$Object,

        [switch]$NoNewline,

        [Object]$Separator,

        [System.ConsoleColor]$ForegroundColor,

        [System.ConsoleColor]$BackgroundColor
    )
    Begin {
        $oLogInfo = $Global:LogInfo
    }
    Process {
        if ($oLogInfo.DoWriteLogLevel($MyInvocation.InvocationName)) {
            if ($oLogInfo.DoWriteToFile) {
                Write-LogItem -InvocationName $MyInvocation.InvocationName -MessageData $Object
            }
            Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
        }
    }
}
Set-Alias -Name Write-LogHost -Value Write-LogInfo
Set-Alias -Name Write-LogInformation -Value Write-LogInfo

function Resolve-PathWithVariables {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Path,
        [Parameter(Position = 1)]
        [System.EnvironmentVariableTarget]$EnvironmentVariableTarget,
        [hashtable]$Hashtable
    )
    $sResult = $Path
    # Replace environment variables
    $aTargets = @()
    if ($EnvironmentVariableTarget) {
        $aTargets += $EnvironmentVariableTarget
    }
    $aTargets += "Machine", "User", "Process"

    foreach ($target in $aTargets) {
        $hEnvVariables = [System.Environment]::GetEnvironmentVariables($target)
        foreach ($variable in $hEnvVariables.Keys) {
            if ($sResult -like ("*%" + $variable + "%*")) {
                $sResult = $sResult -replace ("%" + $variable + "%"), $hEnvVariables[$variable]
            }
        }
    }

    # Replace datetime variables
    $aDateMatches = $sResult | Select-String "%d:([^%]+)%" -AllMatches
    foreach ($m in $aDateMatches.matches) {
        $sResult = $sResult -replace $m.Value, (Get-Date -Format $m.Groups[1].Value)
    }

    # Replace variables included in $Hashtable
    foreach ($key in $Hashtable.Keys) {
        $sResult = $sResult -ireplace ("%" + $key + "%"), $Hashtable[$key]
    }

    # return $result
    return $sResult
}

function Get-ApplicationUninstallRegKey {
    Param(
        [Parameter(ParameterSetName = "value")]
        [ValidateNotNullOrEmpty()]
        $valueName = "DisplayName",
        [Parameter(ParameterSetName = "productcode")]
        [ValidateNotNullOrEmpty()]
        [string]$productCode,
        [Parameter(ParameterSetName = "value")]
        [ValidateNotNullOrEmpty()]
        $valueData
    )
    [Microsoft.Win32.RegistryKey[]]$result = @()
    $result = $null
    switch ($PSCmdlet.ParameterSetName) {
        "value" {
            $valueDataToSearch = $valueData
            foreach ($data in $valueDataToSearch) {
                $result += Get-ChildItem hklm:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\ | Where-Object { ($_.GetValue($valueName) -like $data ) }    
                $result += Get-ChildItem hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Where-Object { ($_.GetValue($valueName) -like $data ) }    
            }        
        }
        "productcode" {
            $result += Get-Item $("HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" + $productCode) -ErrorAction Ignore
            $result += Get-Item $("HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" + $productCode) -ErrorAction Ignore
        }
    }
    return $result
}

function Test-Installed {
    Param(
        [Parameter(Mandatory, ParameterSetName = "Name")]
        [string]$ProgramName,
        [Parameter(Mandatory, ParameterSetName = "productcode")]
        [string]$ProductCode
    )
    switch ($PSCmdlet.ParameterSetName) {
        "Name" {
            $regKey = Get-ApplicationUninstallRegKey -valueData $ProgramName
            return $($null -ne $regKey)        
        }
        "productcode" {
            $regKey = Get-ApplicationUninstallRegKey -productCode $ProductCode
            return $($null -ne $regKey)
        }
    }
}

$MSI_ERROR_SUCCESS = 0
$MSI_ERROR_SUCCESS_REBOOT_INITIATED = 1641
$MSI_ERROR_SUCCESS_REBOOT_REQUIRED = 3010
function Test-MSISuccess {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [int]$msiReturnCode
    )
    return (($msiReturnCode -eq $MSI_ERROR_SUCCESS) `
        -or ($msiReturnCode -eq $MSI_ERROR_SUCCESS_REBOOT_INITIATED) `
        -or ($msiReturnCode -eq $MSI_ERROR_SUCCESS_REBOOT_REQUIRED)) 
}

function Test-InstallationSuccessTag {
    Param (
        [ValidateNotNullOrEmpty()]
        [ValidateSet("hklm:\", "hkcu:\")]
        [string]$regroot = "hklm:\",
        [Parameter(Mandatory)]
        [string]$regfolder,
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        [string]$ApplicationName,
        [ValidateNotNullOrEmpty()]
        [string]$Status = "OK",
        [Parameter(ParameterSetName = "PackageVersion")]
        [ValidateNotNullOrEmpty()]
        [string]$PackageVersion,
        [Parameter(ParameterSetName = "ProductVersion")]
        [ValidateNotNullOrEmpty()]
        [string]$ProductVersion,
        [string]$TagFile,
        [ValidateSet("RegAndFile", "RegOrFile")]
        [string]$ValidationScope = "RegOrFile"
    )
    $registry_tag_path = $regroot + $regfolder + "\" + $ApplicationName
    $key = Get-Item -LiteralPath $registry_tag_path -ErrorAction SilentlyContinue
    $bKeyTest = if ($null -eq $key) {
        $false
    } else {
        $Status_Value = $key.GetValue("Status", $null)
        switch ($PSCmdlet.ParameterSetName) {
            "PackageVersion" {
                $Package_Version_Value = $key.GetValue("PackageVersion", $null)
                if ($null -eq $Package_Version_Value) {
                    ($null -ne $Status_Value) -and ($Status_Value -eq $Status)
                } else {
                    ($null -ne $Status_Value) -and ($Status_Value -eq $Status) `
                      -and ([version]$PackageVersion -le [version]$Package_Version_Value)        
                }
            }
            "ProductVersion" {
                $Product_Version_Value = $key.GetValue("ProductVersion", $null)
                if ($null -eq $Product_Version_Value) {
                    ($null -ne $Status_Value) -and ($Status_Value -eq $Status)
                } else {
                    try {
                        ($null -ne $Status_Value) -and ($Status_Value -eq $Status) `
                        -and ([version]$ProductVersion -le [version]$Product_Version_Value)
                    } catch {
                        ($ProductVersion -eq $Product_Version_Value)
                    }
                }
            }
        }
    }
    $bTagFileTest = ($TagFile -and (Test-path -Path $TagFile -PathType Leaf))
    if ($TagFile) {
        if ($ValidationScope -eq "RegOrFile") {
            return $bKeyTest -or $bTagFileTest
        } else {
            return $bKeyTest -and $bTagFileTest
        }    
    } else {
        return $bKeyTest
    }
}

function Set-InstallationTag {
    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet("hklm:\", "hkcu:\")]
        [string]$regroot = "hklm:\",
        [Parameter(Mandatory)]
        [string]$regfolder,
        [Parameter(Mandatory=$true)]
        [string]$ApplicationName,
        [string]$InstallDate = $(Get-Date -Format "dd/MM/yyyy HH:mm:ss,fff"),
        [string]$InstallPath,
        [string]$Manufactured,
        [string]$PackageVersion,
        [string]$Pkg_ID,
        [string]$ProductVersion,
        [string]$ProductCode,
        [string]$Scope,
        [string]$ScriptReturn,
        [string]$Status,
        [string]$TagFile
    )
    New-Item -Path $($regroot + $regfolder) -Name $ApplicationName –Force | Out-Null
    $path = $regroot + $regfolder + "\" + $ApplicationName
    Set-ItemProperty -Path $path -Name "ApplicationName" -Value $ApplicationName *>$null
    if ($InstallDate) { Set-ItemProperty -Path $path -Name "InstallDate" -Value $InstallDate }
    if ($InstallPath) { Set-ItemProperty -Path $path -Name "InstallPath" -Value $InstallPath }
    if ($Manufactured) { Set-ItemProperty -Path $path -Name "Manufactured" -Value $Manufactured }
    if ($PackageVersion) { Set-ItemProperty -Path $path -Name "PackageVersion" -Value $PackageVersion }
    if ($Pkg_ID) { Set-ItemProperty -Path $path -Name "Pkg_ID" -Value $Pkg_ID }
    if ($ProductVersion) { Set-ItemProperty -Path $path -Name "ProductVersion" -Value $ProductVersion }
    if ($ProductCode) { Set-ItemProperty -Path $path -Name "ProductCode" -Value $ProductCode }
    if ($Scope) { Set-ItemProperty -Path $path -Name "Scope" -Value $Scope }
    if ($ScriptReturn) { Set-ItemProperty -Path $path -Name "ScriptReturn" -Value $ScriptReturn }
    if ($Status) { Set-ItemProperty -Path $path -Name "Status" -Value $Status }
    if ($TagFile) { New-Item -Path $TagFile -ItemType File | Out-Null }
    return Get-ChildItem -Path $path
}

function Get-ScriptLogFileName {
    Param(
        [string]$scriptName = $(Get-RootScriptName)
    )
    return $scriptName + "_" + $(Get-Date -Format "yyyy-MM-dd_HHmm") + ".log"
}

function Get-ScriptLogFile {
    Param(
        [ValidateNotNullOrEmpty()]
        [string]$log_folder = $env:Temp,
        [string]$fallback_folder = $null
    )
    $filename = Get-ScriptLogFileName
    if (Test-Path -Path $log_folder -PathType Container) {
        $log_folder + $filename
    } else {
        if ($fallback_folder -eq $null) {
            throw [System.IO.DirectoryNotFoundException] "Directory $log_folder does not exists"
        } else {
            if (Test-Path -Path $fallback_folder -PathType Container) {
                $fallback_folder + $filename
            } else {
                throw [System.IO.DirectoryNotFoundException] "Directories $log_folder and $fallback_folder do not exist"
            }
        }
    }
}

function Get-RootScriptConfigFile {
    Param(
        [string]$configFileName = "config.json",
        [string]$devConfigFolderName = "input"
    )
    $rootScriptPath = Get-RootScriptPath
    $rootScriptName = Get-RootScriptName 
    if (Test-Path -Path ($rootScriptPath + $configFileName) -PathType Leaf) {
        return $rootScriptPath + $configFileName
    } elseif (Test-Path -Path ($rootScriptPath + $devConfigFolderName + "\" + $rootScriptName + "\" + $configFileName) -PathType Leaf) {
        return $rootScriptPath + $devConfigFolderName + "\" + $rootScriptName + "\" + $configFileName
    } elseif (Test-Path -Path ($rootScriptPath + $devConfigFolderName + "\" + $configFileName) -PathType Leaf) {
        return $rootScriptPath + $devConfigFolderName + "\" + $configFileName
    } else {
        return ""
    }
}

function Get-RootScriptName {
    Param(
        [switch]$appendExtension
    )
    $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' } 
    if ($appendExtension.IsPresent) {
        return $scriptCallStack[-1].Command
    } else {
        return $scriptCallStack[-1].Command.Split(".")[0]
    }
}

function Get-RootScriptPath {
    Param(
        [switch]$FullPath
    )
    $scriptCallStack = Get-PSCallStack | Where-Object { $_.Command -ne '<ScriptBlock>' } 
    $rootScriptFullPath = $scriptCallStack[-1].InvocationInfo.InvocationName
    $rootScriptName = $scriptCallStack[-1].InvocationInfo.MyCommand.Name
    $sResult = if (($rootScriptFullPath.Length - $rootScriptName.Length) -lt 0) {
        ""
    } else {
        $rootScriptFullPath.Remove($rootScriptFullPath.Length - $rootScriptName.Length)
    }
    if ($FullPath.IsPresent) {
        if ($sResult -eq "") {
            (Resolve-Path -Path ".").Path
        } else {
            (Resolve-Path -Path $sResult).Path
        }
    } else {
        return $sResult
    }
}

function Wait-ServiceStatus {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,
        [Parameter(Mandatory, Position = 1)]
        [string]$Status,
        [Parameter(Position = 2)]
        [int]$Timeout = 20000
    )
    $timoutRemaining = $Timeout
    While (($(Get-Service -Name $Name).Status -ne $Status) -and ($timoutRemaining -gt 0)) {
        $timoutRemaining = $timoutRemaining - 100
        Start-Sleep -Milliseconds 100
    }
    $newStatus = $(Get-Service -Name $Name).Status
    Return [PSCustomObject]@{
        Timeout = $timoutRemaining
        NewStatus = $newStatus
        ExpectedStatus = $Status
        Success = $($newStatus -eq $Status)
    }
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

#endregion Include

#region Functions

function Get-SourceFile {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$FileName
    )
    $sResult = $null
    foreach ($item in $FileName) {
        $sResult = if (Test-Path -Path "$PSScriptRoot\Sources\$item" -PathType Leaf) {
            "$PSScriptRoot\Sources\$item"
        } elseif (Test-Path -Path "$PSScriptRoot\Sources\CheckPoint_Packages\$packageToInstall\$item" -PathType Leaf) {
            "$PSScriptRoot\Sources\CheckPoint_Packages\$packageToInstall\$item"
        }
    }
    if ($null -ne $sResult) {
        $sResult = Get-Item $sResult
    }
    return $sResult
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



