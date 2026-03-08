@{
    # Module manifest for PSSomeEngineThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeEngineThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '71622ff8-6316-4226-a6a3-e1ea85104477'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'PowerShell engine utilities: script editing and analysis, module management, JEA configuration, PSSession helpers, PSDrive operations, and AutoIt compilation.'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        # AutoIt
        'Invoke-AutoItCompile'
        'New-PowershellScriptRunner'
        'Search-AutoItCompile'

        # ConnectionInfo
        'Get-ConnectionInfo'

        # Edit
        'Get-FunctionMetadata'
        'Get-PowershellScriptDependencies'
        'Get-PowershellScriptWithIncludedDependancies'
        'Get-ScriptCommentRegion'
        'Get-ScriptInfo'
        'Get-ScriptRegion'
        'Get-ScriptRegions'
        'Remove-ScriptRegion'
        'Replace-ScriptRegion'
        'Write-ScriptCommentDoc'

        # Module
        'Import-InstalledModule'
        'Import-PSModule'
        'Install-PSModule'
        'Test-InstalledPSModule'

        # Other
        'ConvertTo-OneLineScriptBlock'
        'ConvertTo-ScriptBlock'

        # Powershell
        'Get-CmdletDefinedParameters'
        'Get-CmdletHeader'
        'Get-CommandProxy'
        'New-PSRC'
        'New-PSSC'
        'Test-Type'

        # Powershell\JEA
        'Get-JEARoleFromUserGroups'
        'Install-JEAModule'
        'New-PSRoleCapabilityFile'
        'New-PSSessionConfigurationFile'
        'Select-JEARole'

        # PSDrive
        'Test-PSDrive'

        # PSSession
        'Connect-MultiplePSSessions'
        'New-TestedPSSession'
    )

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('Engine', 'Script', 'Module', 'JEA', 'PSSession', 'AutoIt', 'Development')
            ProjectUri = ''
        }
    }
}
