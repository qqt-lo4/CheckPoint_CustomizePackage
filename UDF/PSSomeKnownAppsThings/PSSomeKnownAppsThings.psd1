@{
    # Module manifest for PSSomeKnownAppsThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeKnownAppsThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '8b5a3c91-d247-4e6f-a08b-1f9c7d4e25a3'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Launchers and helpers for known applications: admin tools (PAExec, Putty, MSTSC), OneDrive management, Nmap, browser, Teams, and File Explorer.'

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
            Tags       = @('Applications', 'AdminTools', 'OneDrive', 'Nmap', 'Putty', 'RemoteDesktop')
            ProjectUri = ''
        }
    }
}