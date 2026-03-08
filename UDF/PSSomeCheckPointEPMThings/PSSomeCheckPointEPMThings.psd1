@{
    # Module manifest for PSSomeCheckPointEPMThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeCheckPointEPMThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '48d6bba0-e881-4e64-bd89-172a15348931'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Check Point Endpoint Policy Manager (EPM) API wrapper: computer management, policy installation, rules, packages, network objects, and service definitions.'

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
            Tags       = @('CheckPoint', 'EPM', 'EndpointSecurity', 'Firewall', 'API')
            ProjectUri = ''
        }
    }
}
