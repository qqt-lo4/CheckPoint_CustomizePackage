function Set-InstallationTag {
    <#
    .SYNOPSIS
        Creates an installation tracking tag in the registry

    .DESCRIPTION
        Writes installation metadata to a registry key for tracking deployed applications.
        Stores information such as application name, install date, version, status, and
        optionally creates a tag file on disk.

    .PARAMETER regroot
        Registry root path. Valid values: "hklm:\", "hkcu:\" (default: "hklm:\")

    .PARAMETER regfolder
        Registry folder path under the root

    .PARAMETER ApplicationName
        Name of the application being tagged

    .PARAMETER InstallDate
        Installation date/time string (default: current date in dd/MM/yyyy HH:mm:ss,fff format)

    .PARAMETER InstallPath
        Application installation path

    .PARAMETER Manufactured
        Manufacturer/vendor name

    .PARAMETER PackageVersion
        Deployment package version

    .PARAMETER Pkg_ID
        Package identifier

    .PARAMETER ProductVersion
        Product version string

    .PARAMETER ProductCode
        MSI product code GUID

    .PARAMETER Scope
        Installation scope (machine or user)

    .PARAMETER ScriptReturn
        Script return code or message

    .PARAMETER Status
        Installation status (e.g., "OK", "Failed")

    .PARAMETER TagFile
        Optional file path to create as an installation marker

    .OUTPUTS
        Microsoft.Win32.RegistryKey. The created registry key.

    .EXAMPLE
        Set-InstallationTag -regfolder "SOFTWARE\MyCompany\Deployments" -ApplicationName "MyApp" -Status "OK" -ProductVersion "1.2.3"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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
