function Get-InstalledProgramPath {
    <#
    .SYNOPSIS
        Gets the installation path of an installed program

    .DESCRIPTION
        Retrieves the InstallLocation registry value from the uninstall registry keys
        matching the given criteria. Returns unique paths.

    .PARAMETER valueName
        The registry value name to search by (default: DisplayName)

    .PARAMETER productCode
        The MSI product code GUID to look up

    .PARAMETER valueData
        The value data pattern to match against (supports wildcards)

    .OUTPUTS
        System.String[]. Unique installation paths.

    .EXAMPLE
        Get-InstalledProgramPath -valueData "Microsoft Visual Studio*"

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
    $regKeys = Get-ApplicationUninstallRegKey @PSBoundParameters
    $result = @()
    foreach ($item in $regKeys) {
        $result += Get-ItemPropertyValue -Path $item.PSPath -Name "InstallLocation"
    }
    return $result | Select-Object -Unique
}
