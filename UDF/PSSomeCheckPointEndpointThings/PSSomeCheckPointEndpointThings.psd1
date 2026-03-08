@{
    # Module manifest for PSSomeCheckPointEndpointThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeCheckPointEndpointThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = 'b7c3e5a1-9f24-4d68-8e1b-3a5c72f09d46'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Check Point Endpoint Security client management: VPN connections, site configuration, service control, installation, and trac configuration.'

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
            Tags       = @('CheckPoint', 'Endpoint', 'VPN', 'Security', 'API')
            ProjectUri = ''
        }
    }
}
