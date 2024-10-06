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
