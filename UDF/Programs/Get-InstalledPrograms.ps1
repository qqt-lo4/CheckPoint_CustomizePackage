function Get-InstalledPrograms {
    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [switch]$UseWMI,
        [switch]$ProgramAndFeatures
    )

    function Test-PSDrive {
        Param(
            [Parameter(Mandatory, Position = 0)]
            [string]$Name,
            [Parameter(Position = 1)]
            [string]$PSProvider,
            [Parameter(Position = 2)]
            [string]$Root
        )
    
        $oPSdrive = Get-PSDrive -Name $Name -ErrorAction SilentlyContinue
        if ($PSProvider) {
            $oPSdrive = $oPSdrive | Where-Object { $_.Provider.Name -ieq $PSProvider }
        }
        if ($Root) {
            $oPSdrive = $oPSdrive | Where-Object { $_.DisplayRoot -ieq $Root }
        }
        return ($null -ne $oPSdrive)
    }

    function Convert-RegistryToHashtable {
        Param(
            [Parameter(Mandatory, Position = 0)]
            [object]$RegistryKey
        )
        $hResult = [ordered]@{}
        foreach ($p in $RegistryKey.Property) {
            $hResult.$p = $RegistryKey.GetValue($p)
        }
        return $hResult
    }

    function Add-ResultItems {
        Param(
            [Parameter(Mandatory, Position = 0)]
            [Microsoft.Win32.RegistryKey[]]$Key,
            [hashtable]$WindowsInstallerProducts,
            [string]$KeyName,
            [switch]$ProgramAndFeatures
        )
        $aResult = @()
        foreach ($oKey in $Key) {
            if ($oKey.ValueCount -ne 0) {
                $hReg = Convert-RegistryToHashtable $oKey
                $bValidResult = if ($ProgramAndFeatures) {
                    ($hReg.SystemComponent -ne 1) -and (-not $hReg.PatchType ) -and ($hReg.DisplayName -or $hReg.ProductName )
                } else {
                    $true
                }
                if ($bValidResult) {
                    $hApp = [ordered]@{}
                    $sName = if ($hReg.DisplayName) {
                        $hReg.DisplayName
                    } elseif ($hReg.ProductName) {
                        $hReg.ProductName
                    } else {
                        ""
                    }
                    $hApp.Add("Name", $sName)
                    if ($hReg.Publisher) {
                        $hApp.Add("Publisher", $hReg.Publisher)
                    }
                    if ($hReg.DisplayVersion) {
                        $hApp.Add("Version", $hReg.DisplayVersion)
                    }
                    if ($hReg.InstallDate) {
                        $hApp.Add("InstallDate", $hReg.InstallDate)
                    }
                    $hApp.Add("ProductCode", $oKey.PSChildName)
                    $hAdditionalProperties = @{
                        KeyName = $KeyName                        
                        Registry = $hReg
                    }
                    if ($WindowsInstallerProducts[$oKey.PSChildName]) {
                        $oWindowsInstallerProduct = $WindowsInstallerProducts[$oKey.PSChildName]
                        $hAdditionalProperties.WindowsInstaller = Convert-RegistryToHashtable $oWindowsInstallerProduct
                    }
                    $hApp.Add("_AdditionalProperties", $hAdditionalProperties)
                    $aResult += $hApp    
                }
            }
        }
        return $aResult
    }

    if ($ComputerName -or $Session) {
        $aResult = Invoke-ThisFunctionRemotely -ImportFunctions @("ConvertTo-Guid")
        return $aResult | ForEach-Object -Process { $_.PSTypeNames.Insert(0, "Installed Program") ; $_ } | Sort-Object -Property Name
    } else {
        if ($UseWMI) {
            return Get-CimInstance -Class Win32_Product
        } else {
            if (-not (Test-PSDrive "HKCR")) {
                New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR | Out-Null
            }
        
            $aWindowsInstallerProducts = Get-ChildItem "hkcr:\Installer\Products"
            $hWindowsInstallerProducts = @{}
            foreach ($oKey in $aWindowsInstallerProducts) {
                $sGuid = ConvertTo-Guid -PackageCode $oKey.PSChildName
                $hWindowsInstallerProducts["{" + $sGuid.ToString() + "}"] = $oKey
            }
    
            $aUninstallKeysWOW6432Node = Get-ChildItem hklm:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\
            $hUninstallKeysWOW6432Node = @{}
            foreach ($oKey in $aUninstallKeysWOW6432Node) {
                $hUninstallKeysWOW6432Node[$oKey.PSChildName] = $oKey
            }
            $aUninstallKeysDefault = Get-ChildItem hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\
            $hUninstallKeysDefault = @{}
            foreach ($oKey in $aUninstallKeysDefault) {
                $hUninstallKeysDefault[$oKey.PSChildName] = $oKey
            }
    
            $aResult = @()
            $aResult += Add-ResultItems -Key $aUninstallKeysDefault -WindowsInstallerProducts $hWindowsInstallerProducts -KeyName "Default" -ProgramAndFeatures:$ProgramAndFeatures
            $aResult += Add-ResultItems -Key $aUninstallKeysWOW6432Node -WindowsInstallerProducts $hWindowsInstallerProducts -KeyName "WOW6432Node" -ProgramAndFeatures:$ProgramAndFeatures
            if ($PSBoundParameters["Verbose"]) {
                return @{
                    aWindowsInstallerProducts = $aWindowsInstallerProducts
                    hWindowsInstallerProducts = $hWindowsInstallerProducts
                    aUninstallKeysWOW6432Node = $aUninstallKeysWOW6432Node
                    hUninstallKeysWOW6432Node = $hUninstallKeysWOW6432Node
                    aUninstallKeysDefault = $aUninstallKeysDefault
                    hUninstallKeysDefault = $hUninstallKeysDefault
                    aResult = $aResult
                }    
            } else {
                return $aResult | ForEach-Object -Process { $o = [pscustomobject]$_ ; $o.PSTypeNames.Insert(0, "Installed Program") ; $o } | Sort-Object -Property Name
            }    
        }
    }
}
