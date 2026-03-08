@{
    # Module manifest for PSSomeSystemThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeSystemThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'a9d13f7e-5b42-4c81-96e0-3d8f1a2c7b59'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Windows system management utilities: system info, services, drives, registry, sessions, shortcuts, network mappings, environment paths, task scheduler, and user management.'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('System', 'Windows', 'Services', 'Registry', 'Drive', 'Network', 'Session', 'Administration')
            ProjectUri = ''
        }
    }
}
