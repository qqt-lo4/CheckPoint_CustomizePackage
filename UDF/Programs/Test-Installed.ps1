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
