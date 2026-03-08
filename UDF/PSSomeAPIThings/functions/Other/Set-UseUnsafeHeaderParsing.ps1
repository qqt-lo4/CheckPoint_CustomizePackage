function Set-UseUnsafeHeaderParsing {
    <#
    .SYNOPSIS
        Enables or disables unsafe HTTP header parsing

    .DESCRIPTION
        Toggles the useUnsafeHeaderParsing setting in the .NET System.Net internals
        via reflection. When enabled, allows parsing of HTTP responses with malformed
        headers that would otherwise cause errors.

    .PARAMETER Enable
        Enables unsafe header parsing.

    .PARAMETER Disable
        Disables unsafe header parsing.

    .OUTPUTS
        None.

    .EXAMPLE
        Set-UseUnsafeHeaderParsing -Enable

    .EXAMPLE
        Set-UseUnsafeHeaderParsing -Disable

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param(
        [Parameter(Mandatory,ParameterSetName='Enable')]
        [switch]$Enable,

        [Parameter(Mandatory,ParameterSetName='Disable')]
        [switch]$Disable
    )

    $ShouldEnable = $PSCmdlet.ParameterSetName -eq 'Enable'

    $netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

    if ($netAssembly) {
        $bindingFlags = [Reflection.BindingFlags] 'Static,GetProperty,NonPublic'
        $settingsType = $netAssembly.GetType('System.Net.Configuration.SettingsSectionInternal')

        $instance = $settingsType.InvokeMember('Section', $bindingFlags, $null, $null, @())

        if ($instance) {
            $bindingFlags = 'NonPublic','Instance'
            $useUnsafeHeaderParsingField = $settingsType.GetField('useUnsafeHeaderParsing', $bindingFlags)

            if ($useUnsafeHeaderParsingField) {
                $useUnsafeHeaderParsingField.SetValue($instance, $ShouldEnable)
            }
        }
    }
}
