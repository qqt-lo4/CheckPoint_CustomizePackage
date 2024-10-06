function Get-InstalledProgramPath {
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
    $regKeys = Get-ApplicationUninstallRegKey @PSBoundParameters
    $result = @()
    foreach ($item in $regKeys) {
        $result += Get-ItemPropertyValue -Path $item.PSPath -Name "InstallLocation"
    }
    return $result | Select-Object -Unique
}
