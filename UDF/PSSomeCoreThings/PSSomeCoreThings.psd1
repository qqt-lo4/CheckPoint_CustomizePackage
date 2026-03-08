@{
    # Module manifest for PSSomeCoreThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeCoreThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '061e2642-e999-4f4c-ab2d-70ce5a43cdf8'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Core PowerShell utilities: logging framework, script introspection, configuration management, remote execution helpers, and file system operations.'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @(
        'Write-LogHost'
        'Write-LogInformation'
    )

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('Core', 'Logging', 'Configuration', 'Scripting', 'Utilities')
            ProjectUri = ''
        }
    }
}