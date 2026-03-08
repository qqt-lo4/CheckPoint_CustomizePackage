function Get-ApplicationUninstallRegKey {
    <#
    .SYNOPSIS
        Retrieves uninstall registry keys for an application

    .DESCRIPTION
        Searches the Windows uninstall registry keys (both 64-bit and 32-bit hives)
        to find entries matching a display name pattern or a specific product code.

    .PARAMETER valueName
        The registry value name to search by (default: DisplayName)

    .PARAMETER productCode
        The MSI product code GUID to look up directly

    .PARAMETER valueData
        The value data pattern to match against (supports wildcards)

    .OUTPUTS
        Microsoft.Win32.RegistryKey[]. Matching registry key objects.

    .EXAMPLE
        Get-ApplicationUninstallRegKey -valueData "Google Chrome*"

    .EXAMPLE
        Get-ApplicationUninstallRegKey -productCode "{GUID-HERE}"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
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