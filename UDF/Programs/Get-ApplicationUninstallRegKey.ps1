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