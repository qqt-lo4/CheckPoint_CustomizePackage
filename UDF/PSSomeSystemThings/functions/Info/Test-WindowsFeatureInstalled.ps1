function Test-WindowsFeatureInstalled {
    <#
    .SYNOPSIS
        Tests if a Windows Optional Feature is enabled

    .DESCRIPTION
        Uses Win32_OptionalFeature WMI class to check feature state without requiring elevation.
        InstallState: 1 = Enabled, 2 = Disabled, 3 = Absent

    .PARAMETER FeatureName
        The feature name (e.g., "Microsoft-Hyper-V-All")

    .OUTPUTS
        Returns $true if feature is enabled, $false otherwise

    .EXAMPLE
        Test-WindowsFeatureInstalled -FeatureName "Microsoft-Hyper-V-All"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$FeatureName
    )

    try {
        $feature = Get-CimInstance -ClassName Win32_OptionalFeature -Filter "Name='$FeatureName'" -ErrorAction Stop
        return ($feature.InstallState -eq 1)
    } catch {
        return $false
    }
}
