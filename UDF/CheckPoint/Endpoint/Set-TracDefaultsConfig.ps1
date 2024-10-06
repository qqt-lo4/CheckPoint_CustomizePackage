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