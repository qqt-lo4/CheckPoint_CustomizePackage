function Set-TracDefaultsConfig {
    <#
    .SYNOPSIS
        Applies configuration settings to Check Point trac.defaults file

    .DESCRIPTION
        Updates the trac.defaults configuration file with settings from a JSON configuration object.
        Creates a backup before modifying the file. All specified options must exist in the file.

    .PARAMETER tracDefaultsPath
        Path to the trac.defaults configuration file.

    .PARAMETER jsonConfig
        PSObject or hashtable containing configuration key-value pairs to apply.

    .OUTPUTS
        [tracDefaultsSettings]. The updated trac defaults settings object.

    .EXAMPLE
        $config = @{ log_level = "debug"; enable_ssl = "true" } | ConvertTo-Json | ConvertFrom-Json
        Set-TracDefaultsConfig -tracDefaultsPath "C:\Program Files\CheckPoint\Endpoint\trac.defaults" -jsonConfig $config

    .EXAMPLE
        $config = [PSCustomObject]@{ option1 = "value1"; option2 = "value2" }
        Set-TracDefaultsConfig -tracDefaultsPath (Get-CheckPointTracDefaults) -jsonConfig $config

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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