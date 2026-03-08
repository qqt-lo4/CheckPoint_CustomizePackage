function Get-InstalledPrograms {
    <#
    .SYNOPSIS
        Lists all installed programs on the system

    .DESCRIPTION
        Retrieves installed programs from Windows registry uninstall keys (HKLM and HKCU,
        both 64-bit and 32-bit). Optionally includes AppX packages and supports
        remote execution via PSSession or WMI.

    .PARAMETER ComputerName
        Remote computer name for remote execution

    .PARAMETER Credential
        Credentials for remote execution

    .PARAMETER Session
        Existing PSSession for remote execution

    .PARAMETER UseWMI
        Use WMI (Win32_Product) instead of registry queries

    .PARAMETER ProgramAndFeatures
        Filter results to match Programs and Features criteria (excludes system components and patches)

    .PARAMETER AsHashtable
        Return results as ordered hashtables instead of PSCustomObjects

    .PARAMETER IncludeAppx
        Include AppX/MSIX packages in the results

    .OUTPUTS
        PSCustomObject[] or OrderedDictionary[]. Installed program objects with Name, Type,
        Publisher, Version, ProductCode, Scope, and _AdditionalProperties.

    .EXAMPLE
        Get-InstalledPrograms -ProgramAndFeatures
        Lists programs similar to the Programs and Features control panel

    .EXAMPLE
        Get-InstalledPrograms -IncludeAppx | Where-Object { $_.Name -like "*Chrome*" }

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [switch]$UseWMI,
        [switch]$ProgramAndFeatures,
        [switch]$AsHashtable,
        [switch]$IncludeAppx
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

    function Get-UninstallKeys {
        Param(
            [Parameter(Mandatory, Position = 0)]
            [string]$RegistryPath
        )
        $aKeys = Get-ChildItem $RegistryPath -ErrorAction SilentlyContinue
        $hKeys = @{}
        if ($aKeys) {
            foreach ($oKey in $aKeys) {
                $hKeys[$oKey.PSChildName] = $oKey
            }
        }
        return @{
            Array = $aKeys
            Hashtable = $hKeys
        }
    }

    function Add-ResultItems {
        Param(
            [Parameter(Position = 0)]
            [AllowNull()]
            [Microsoft.Win32.RegistryKey[]]$Key,
            [hashtable]$WindowsInstallerProducts,
            [string]$KeyName,
            [switch]$ProgramAndFeatures
        )
        $aResult = @()

        # Return empty array if Key is null
        if ($null -eq $Key) {
            return $aResult
        }

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
                    $hApp.Add("Type", "win32")
                    if ($hReg.Publisher) {
                        $hApp.Add("Publisher", $hReg.Publisher)
                    }
                    if ($hReg.DisplayVersion) {
                        $hApp.Add("Version", $hReg.DisplayVersion)
                    }
                    if ($hReg.InstallDate) {
                        $hApp.Add("InstallDate", $hReg.InstallDate)
                    }
                    if ($hReg.Comments) {
                        $hApp.Add("Comments", $hReg.Comments)
                    }
                    $hApp.Add("ProductCode", $oKey.PSChildName)

                    # Determine scope based on KeyName
                    $scope = if ($KeyName -like "*User*") { "user" } else { "machine" }
                    $hApp.Add("Scope", $scope)

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

    function Expand-IndirectString {
        Param(
            [string]$IndirectString = ""
        )

        # Add SHLoadIndirectString type if not already loaded
        if (-not ([System.Management.Automation.PSTypeName]'SHLWAPIDLL.IndirectStrings').Type) {
            $CSharpCode = @'
using System;
using System.Text;
using System.Runtime.InteropServices;

namespace SHLWAPIDLL {
    public class IndirectStrings {
        [DllImport("shlwapi.dll", CharSet=CharSet.Unicode)]
        private static extern int SHLoadIndirectString(string pszSource, StringBuilder pszOutBuf, int cchOutBuf, string ppvReserved);

        public static string GetIndirectString(string indirectString) {
            try {
                StringBuilder lptStr = new StringBuilder(1024);
                int returnValue = SHLoadIndirectString(indirectString, lptStr, 1024, null);
                if (returnValue == 0) {
                    return lptStr.ToString();
                }
                return null;
            }
            catch {
                return null;
            }
        }
    }
}
'@
            Add-Type -TypeDefinition $CSharpCode -Language CSharp -ErrorAction SilentlyContinue
        }

        return [SHLWAPIDLL.IndirectStrings]::GetIndirectString($IndirectString)
    }

    function Get-AppxPackages {
        Param(
            [switch]$ProgramAndFeatures
        )
        $aResult = @()

        try {
            # Get all AppX packages for all users
            $allPackages = Get-AppxPackage -ErrorAction SilentlyContinue

            foreach ($package in $allPackages) {
                $hApp = [ordered]@{}
                $hApp.Add("Name", $package.Name)
                $hApp.Add("PackageName", $package.Name)
                $hApp.Add("Architecture", $package.Architecture)
                $hApp.Add("Type", "appx")
                if ($package.Publisher) {
                    $hApp.Add("Publisher", $package.Publisher)
                }
                if ($package.Version) {
                    $hApp.Add("Version", $package.Version.ToString())
                }
                if ($package.InstallLocation) {
                    $hApp.Add("InstallLocation", $package.InstallLocation)
                }
                $hApp.Add("ProductCode", $package.PackageFullName)

                # Determine scope based on whether it's installed for all users or current user
                $scope = if ($package.IsBundle -eq $false -and $package.SignatureKind -eq "System") { "machine" } else { "user" }
                $hApp.Add("Scope", $scope)

                $hAdditionalProperties = @{
                    Package = $package
                }
                $hApp.Add("_AdditionalProperties", $hAdditionalProperties)
                $aResult += $hApp
            }
        } catch {
            Write-Warning "Unable to retrieve AppX packages: $_"
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
    
            # Get uninstall keys from all registry locations
            $uninstallDefault = Get-UninstallKeys "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
            $uninstallWOW = Get-UninstallKeys "hklm:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"
            $uninstallUser = Get-UninstallKeys "hkcu:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
            $uninstallUserWOW = Get-UninstallKeys "hkcu:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"

            $aResult = @()
            $aResult += Add-ResultItems -Key $uninstallDefault.Array -WindowsInstallerProducts $hWindowsInstallerProducts -KeyName "Default" -ProgramAndFeatures:$ProgramAndFeatures
            $aResult += Add-ResultItems -Key $uninstallWOW.Array -WindowsInstallerProducts $hWindowsInstallerProducts -KeyName "WOW6432Node" -ProgramAndFeatures:$ProgramAndFeatures
            $aResult += Add-ResultItems -Key $uninstallUser.Array -WindowsInstallerProducts $hWindowsInstallerProducts -KeyName "User" -ProgramAndFeatures:$ProgramAndFeatures
            $aResult += Add-ResultItems -Key $uninstallUserWOW.Array -WindowsInstallerProducts $hWindowsInstallerProducts -KeyName "UserWOW6432Node" -ProgramAndFeatures:$ProgramAndFeatures
            if ($IncludeAppx) {
                $aResult += Get-AppxPackages -ProgramAndFeatures:$ProgramAndFeatures
            }
            if ($PSBoundParameters["Verbose"]) {
                # Maintain backward compatibility with variable names for Verbose output
                $aUninstallKeysDefault = $uninstallDefault.Array
                $hUninstallKeysDefault = $uninstallDefault.Hashtable
                $aUninstallKeysWOW6432Node = $uninstallWOW.Array
                $hUninstallKeysWOW6432Node = $uninstallWOW.Hashtable
                $aUninstallKeysUser = $uninstallUser.Array
                $hUninstallKeysUser = $uninstallUser.Hashtable
                $aUninstallKeysUserWOW6432Node = $uninstallUserWOW.Array
                $hUninstallKeysUserWOW6432Node = $uninstallUserWOW.Hashtable
                
                return @{
                    aWindowsInstallerProducts = $aWindowsInstallerProducts
                    hWindowsInstallerProducts = $hWindowsInstallerProducts
                    aUninstallKeysWOW6432Node = $aUninstallKeysWOW6432Node
                    hUninstallKeysWOW6432Node = $hUninstallKeysWOW6432Node
                    aUninstallKeysDefault = $aUninstallKeysDefault
                    hUninstallKeysDefault = $hUninstallKeysDefault
                    aUninstallKeysUser = $aUninstallKeysUser
                    hUninstallKeysUser = $hUninstallKeysUser
                    aUninstallKeysUserWOW6432Node = $aUninstallKeysUserWOW6432Node
                    hUninstallKeysUserWOW6432Node = $hUninstallKeysUserWOW6432Node
                    aResult = $aResult
                }
            } else {
                # Sort hashtables by Name, then convert to objects if needed
                $sortedResult = $aResult | Sort-Object -Property { $_['Name'] }

                return $sortedResult | ForEach-Object -Process {
                    $o = if($AsHashtable) {
                        $_
                    } else {
                        [pscustomobject]$_
                    }
                    $o.PSTypeNames.Insert(0, "Installed Program") ;
                    $o
                }
            }    
        }
    }
}
